/**
 * scoring_engine.js — SNAPback
 * Owner: Hidhayath (Scoring & QA)
 *
 * This module is the heart of SNAPback. It tracks users' healthy purchases
 * by physical weight (kg), converting them to a "Fair Dollar Value" using
 * a uniform conversion table. This value is checked against a dynamic
 * Monthly Target threshold (25% of total SNAP). Points are awarded independently.
 *
 * Exports:
 *   FOOD_VALUE_RATES
 *   calculateTripProgress(tripItems)
 *   checkMonthlyTargets(uid, currentMonthProgress, tripContributionValue, snapAmount)
 */

'use strict';

// ---------------------------------------------------------------------------
// Conversions: 1 kg of this category contributes $X to the monthly threshold
// This mathematical standardisation prevents "gaming" the system with
// ultra-expensive premium foods, treating all fresh foods fairly.
// ---------------------------------------------------------------------------
const FOOD_VALUE_RATES = {
    fresh_produce: 3.00, // $3.00 per kg of vegetables
    fresh_fruit: 3.00,   // $3.00 per kg of fruit
    whole_grains: 1.50,  // $1.50 per kg of whole grains
    legumes: 1.50,       // $1.50 per kg of beans/lentils
    lean_protein: 4.00,  // $4.00 per kg of lean meats/fish
    cultural_staple: 2.00 // $2.00 per kg of cultural healthy staples
};

// Points multiplier: 100 points per $1 of "Fair Value" calculated
const POINTS_PER_DOLLAR = 100;
const CONSTANT_BASE_POINTS = 50; // Points given just for uploading the receipt

// ---------------------------------------------------------------------------
// calculateTripProgress
//
// Converts a receipt's parsed items (which have weightKg and category)
// into a fair dollar contribution and point value.
//
// @param {Array} tripItems  Each item: { name, weightKg, category, healthScore }
// @returns {Object} { contributionValue, pointsEarned }
// ---------------------------------------------------------------------------
function calculateTripProgress(tripItems) {
    let contributionValue = 0;

    if (!Array.isArray(tripItems) || tripItems.length === 0) {
        return { contributionValue: 0, pointsEarned: CONSTANT_BASE_POINTS };
    }

    for (const item of tripItems) {
        // Only count items with a valid weight and a mapped healthy category
        if (item.weightKg && item.weightKg > 0 && FOOD_VALUE_RATES[item.category]) {
            const rate = FOOD_VALUE_RATES[item.category];
            const itemValue = item.weightKg * rate;
            contributionValue += itemValue;
        }
    }

    // Calculate points
    const pointsEarned = CONSTANT_BASE_POINTS + Math.round(contributionValue * POINTS_PER_DOLLAR);

    return {
        contributionValue: parseFloat(contributionValue.toFixed(2)),
        pointsEarned: pointsEarned
    };
}

// ---------------------------------------------------------------------------
// checkMonthlyTargets
//
// Checks if the user's new progress triggers their monthly threshold block.
//
// @param {string} uid                    User ID
// @param {number} currentMonthProgress   The user's existing accumulated fair value this month
// @param {number} tripContributionValue  The amount earned from the current trip
// @param {number} snapAmount             Monthly SNAP benefit in dollars
// @returns {Object} { newMonthlyProgress, monthlyTarget, targetHit, rewardAmount }
// ---------------------------------------------------------------------------
function checkMonthlyTargets(uid, currentMonthProgress, tripContributionValue, snapAmount) {
    // Fairly calculated monthly target: 25% of their total SNAP benefit
    const monthlyTarget = snapAmount * 0.25;

    const newMonthlyProgress = currentMonthProgress + tripContributionValue;

    // Did this trip push them over the threshold?
    let targetHit = false;
    let rewardAmount = 0;

    // Only trigger if they crossed the threshold THIS trip, not if they already crossed it earlier
    if (newMonthlyProgress >= monthlyTarget && currentMonthProgress < monthlyTarget) {
        targetHit = true;
        // Reward is 20% of their base SNAP amount added as bonus credit
        rewardAmount = snapAmount * 0.20;
    }

    return {
        newMonthlyProgress: parseFloat(newMonthlyProgress.toFixed(2)),
        monthlyTarget: parseFloat(monthlyTarget.toFixed(2)),
        targetHit,
        rewardAmount: parseFloat(rewardAmount.toFixed(2))
    };
}

module.exports = {
    FOOD_VALUE_RATES,
    calculateTripProgress,
    checkMonthlyTargets
};
