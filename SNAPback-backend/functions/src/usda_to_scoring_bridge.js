/**
 * usda_to_scoring_bridge.js — SNAPback
 * Owner: Roshini (AI & Classification)
 *
 * This module is the integration bridge between:
 *   - Roshini's USDA classification output (from gemini_classifier.js)
 *   - Hidhayath's scoring engine (scoring_engine.js)
 *
 * It does three things:
 *   1. Maps USDA/Gemini category strings → scoring_engine's FOOD_VALUE_RATES keys
 *   2. Converts item unit/quantity → weightKg
 *   3. Filters out unhealthy items (USDA healthScore < 3) so they don't earn points
 *
 * OUTPUT matches scoring_engine.js's required input exactly:
 *   [{ name, weightKg, category, healthScore }, ...]
 *
 * DO NOT modify calculateTripProgress or checkMonthlyTargets — this bridge
 * adapts the data so those functions remain untouched.
 */

'use strict';

const { FOOD_VALUE_RATES, calculateTripProgress, checkMonthlyTargets } = require('./scoring_engine');

// ---------------------------------------------------------------------------
// Category Mapping: USDA/Gemini category → FOOD_VALUE_RATES key
// Only categories present in FOOD_VALUE_RATES earn points.
// Anything not listed here gets null → filtered out (no points).
// ---------------------------------------------------------------------------
const CATEGORY_MAP = {
    // Direct matches
    fresh_produce: 'fresh_produce',
    fresh_fruit: 'fresh_fruit',
    whole_grain: 'whole_grains',    // classifier uses singular, engine uses plural
    whole_grains: 'whole_grains',
    legume: 'legumes',
    legumes: 'legumes',
    lean_protein: 'lean_protein',

    // Mapped approximations
    dairy: null,              // dairy doesn't earn contribution value
    healthy_fat: 'fresh_produce',  // e.g. avocado, tahini — treated as produce
    canned_veg: 'fresh_produce',  // low-sodium canned counts
    frozen_veg: 'fresh_produce',  // frozen veg counts as produce

    // Cultural staple mapping — isCultural flag triggers this
    cultural_staple: 'cultural_staple',

    // Unhealthy — explicitly no contribution
    refined_grain: null,
    processed_snack: null,
    sugary_drink: null,
    candy: null,
    other: null,
};

// ---------------------------------------------------------------------------
// Unit → kg conversions
// ---------------------------------------------------------------------------
const UNIT_TO_KG = {
    kg: 1,
    g: 0.001,
    lb: 0.453592,
    oz: 0.0283495,
    l: 1,        // approx for liquids (1L water ≈ 1kg)
    ml: 0.001,
    ea: 0.1,      // default: 100g per unit
    ct: 0.1,
    pk: 0.5,      // default: 500g per pack
};

// ---------------------------------------------------------------------------
// MINIMUM HEALTH SCORE to earn any contribution points.
// Items scoring below this threshold are filtered out entirely.
// The rule: USDA healthScore >= 3 = healthy enough to reward.
// ---------------------------------------------------------------------------
const MIN_HEALTH_SCORE_FOR_POINTS = 3;

// ---------------------------------------------------------------------------
// mapCategory
// Maps a raw classifier category + isCultural flag → FOOD_VALUE_RATES key.
// Returns null if the item should not earn contribution points.
// ---------------------------------------------------------------------------
function mapCategory(category, isCultural) {
    // Cultural items get the cultural_staple rate if they're healthy
    if (isCultural && category !== 'sugary_drink' && category !== 'candy') {
        return 'cultural_staple';
    }
    return CATEGORY_MAP[category] ?? null;
}

// ---------------------------------------------------------------------------
// toWeightKg
// Converts { quantity, unit } from the classifier to kilograms.
// ---------------------------------------------------------------------------
function toWeightKg(quantity, unit) {
    const q = parseFloat(quantity) || 1;
    const factor = UNIT_TO_KG[unit?.toLowerCase()] ?? 0.1;
    return parseFloat((q * factor).toFixed(4));
}

// ---------------------------------------------------------------------------
// formatItemsForScoringEngine
// Main transform function.
//
// @param {Array} classifiedItems  Output from classifyItems() in gemini_classifier.js
//   Each item: { name, price, quantity, unit, category, healthScore, isCultural, source }
//
// @returns {Array} tripItems ready for calculateTripProgress()
//   Each item: { name, weightKg, category, healthScore }
//   Items that fail the health score filter are excluded.
// ---------------------------------------------------------------------------
function formatItemsForScoringEngine(classifiedItems) {
    const tripItems = [];
    const filtered = [];   // items excluded (for logging/debugging)

    for (const item of classifiedItems) {
        // Step 1: Filter out unhealthy items
        if ((item.healthScore ?? 0) < MIN_HEALTH_SCORE_FOR_POINTS) {
            filtered.push({ name: item.name, reason: `healthScore ${item.healthScore} < ${MIN_HEALTH_SCORE_FOR_POINTS}` });
            continue;
        }

        // Step 2: Map category
        const mappedCategory = mapCategory(item.category, item.isCultural);

        if (!mappedCategory) {
            filtered.push({ name: item.name, reason: `category "${item.category}" not eligible for points` });
            continue;
        }

        // Step 3: Convert to kg
        const weightKg = toWeightKg(item.quantity, item.unit);

        tripItems.push({
            name: item.name,
            weightKg,
            category: mappedCategory,
            healthScore: item.healthScore,
        });
    }

    if (filtered.length > 0) {
        console.log('[Bridge] Filtered out (no points):', filtered.map(f => `${f.name} (${f.reason})`).join(', '));
    }
    console.log('[Bridge] Eligible items for scoring:', tripItems.map(i => `${i.name} (${i.weightKg}kg, ${i.category})`).join(', '));

    return tripItems;
}

// ---------------------------------------------------------------------------
// processTrip
// Full pipeline: classified items → scoring engine → UI-ready output.
//
// @param {Array}  classifiedItems     Output from classifyItems()
// @param {string} uid                 Firebase user ID
// @param {number} currentMonthProgress User's accumulated fair value so far this month
// @param {number} snapAmount          User's monthly SNAP benefit in dollars
//
// @returns {Object} All values needed by the UI:
//   {
//     tripItems,            // formatted items (for debugging / display)
//     contributionValue,    // $ added to monthly threshold this trip
//     pointsEarned,         // gamified points to show on screen
//     newMonthlyProgress,   // total accumulated this month
//     monthlyTarget,        // 25% of SNAP (their goal)
//     targetHit,            // boolean — show celebration UI if true
//     rewardAmount,         // $ bonus SNAP credit if targetHit
//   }
// ---------------------------------------------------------------------------
function processTrip(classifiedItems, uid, currentMonthProgress, snapAmount) {
    // Step 1: Format classifier output for scoring engine
    const tripItems = formatItemsForScoringEngine(classifiedItems);

    // Step 2: calculateTripProgress (Hidhayath's function — untouched)
    const { contributionValue, pointsEarned } = calculateTripProgress(tripItems);

    // Step 3: checkMonthlyTargets (Hidhayath's function — untouched)
    const { newMonthlyProgress, monthlyTarget, targetHit, rewardAmount } =
        checkMonthlyTargets(uid, currentMonthProgress, contributionValue, snapAmount);

    return {
        tripItems,
        contributionValue,
        pointsEarned,
        newMonthlyProgress,
        monthlyTarget,
        targetHit,
        rewardAmount,
    };
}

module.exports = {
    formatItemsForScoringEngine,
    processTrip,
    mapCategory,
    toWeightKg,
};
