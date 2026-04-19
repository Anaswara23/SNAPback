/**
 * usda_lookup.js
 * Queries the USDA FoodData Central API to get real nutrient data for a food item.
 * Converts nutrient values to per-unit (per lb, oz, etc.) and calculates health score 0-5.
 *
 * USDA FDC API Docs: https://fdc.nal.usda.gov/api-guide.html
 * Free API key: https://fdc.nal.usda.gov/api-key-signup.html
 */

const https = require('https');

const USDA_API_KEY = process.env.USDA_API_KEY || 'DEMO_KEY';
const USDA_SEARCH_URL = 'https://api.nal.usda.gov/fdc/v1/foods/search';

const sleep = (ms) => new Promise(resolve => setTimeout(resolve, ms));

// Grams per unit conversions
const UNIT_TO_GRAMS = {
    'lb': 453.592,
    'oz': 28.3495,
    'kg': 1000,
    'g': 1,
    'l': 1000,   // approx for water-based liquids
    'ml': 1,
    'ea': 100,    // default to 100g per each/unit
    'ct': 100,
    'pk': 100,
};

// Nutrient IDs in USDA FDC
const NUTRIENT_IDS = {
    calories: 1008,  // Energy (kcal)
    protein: 1003,  // Protein (g)
    totalFat: 1004,  // Total lipid (fat) (g)
    saturatedFat: 1258,  // Fatty acids, total saturated (g)
    carbs: 1005,  // Carbohydrate, by difference (g)
    fiber: 1079,  // Fiber, total dietary (g)
    sugar: 2000,  // Sugars, total including NLEA (g)
    sodium: 1093,  // Sodium, Na (mg)
};

function httpsGet(url) {
    return new Promise((resolve, reject) => {
        https.get(url, (res) => {
            let data = '';
            res.on('data', chunk => data += chunk);
            res.on('end', () => {
                try { resolve(JSON.parse(data)); }
                catch (e) { reject(new Error('Invalid JSON from USDA API')); }
            });
        }).on('error', reject);
    });
}

/**
 * Fetch nutrient data for a food item from USDA FDC.
 * Searches Foundation + SR Legacy (raw foods only) and picks the best match.
 * Returns nutrients per 100g.
 */
async function fetchNutrients(itemName) {
    const query = encodeURIComponent(itemName);
    // Foundation + SR Legacy only — these are raw, unprocessed foods
    const url = `${USDA_SEARCH_URL}?query=${query}&api_key=${USDA_API_KEY}&pageSize=10&dataType=Foundation,SR%20Legacy`;

    try {
        await sleep(800); // avoid rate limiting
        const data = await httpsGet(url);
        if (!data.foods || data.foods.length === 0) return null;

        // Pick the best match: prefer shorter, simpler descriptions (= raw/unprocessed)
        // e.g. "Apples, raw" beats "Apple, candied" for query "apple"
        const queryLower = itemName.toLowerCase();
        const ranked = data.foods
            .map(f => ({
                food: f,
                // score: shorter description + contains the query word = better match
                score: (f.description.toLowerCase().includes(queryLower) ? 10 : 0)
                    - f.description.length / 10
                    + (f.description.toLowerCase().includes('raw') ? 5 : 0)
                    - (f.description.toLowerCase().includes('candied') ? 10 : 0)
                    - (f.description.toLowerCase().includes('cooked') ? 2 : 0)
                    - (f.description.toLowerCase().includes('canned') ? 1 : 0)
            }))
            .sort((a, b) => b.score - a.score);

        const food = ranked[0].food;

        // ── Confidence check ──
        // If NONE of the query words appear in the matched food description, reject.
        // This prevents bad matches like "gummy bears" → "Beef, lean, protein"
        const queryWords = itemName.toLowerCase().split(/\s+/).filter(w => w.length > 2);
        const matchDesc = food.description.toLowerCase();
        const hasMatch = queryWords.some(word => matchDesc.includes(word));
        if (!hasMatch) {
            console.log(`[USDA] Rejected low-confidence match for "${itemName}": "${food.description}"`);
            return null;
        }

        const nutrients = {};

        for (const [key, id] of Object.entries(NUTRIENT_IDS)) {
            const found = food.foodNutrients.find(n => n.nutrientId === id);
            nutrients[key] = found ? found.value : 0;
        }

        return {
            fdcId: food.fdcId,
            description: food.description,
            nutrients,  // per 100g
        };
    } catch (e) {
        console.error('USDA API error for', itemName, ':', e.message);
        return null;
    }
}


/**
 * Calculate health score 0-5 from nutrients per 100g.
 * Based on nutrient density scoring (inspired by Nutri-Score logic).
 */
function calculateHealthScore(nutrients) {
    let score = 0;

    // --- Positive signals ---
    // Fiber: >= 6g per 100g = excellent, >= 3g = good
    if (nutrients.fiber >= 6) score += 2.0;
    else if (nutrients.fiber >= 3) score += 1.5;
    else if (nutrients.fiber >= 1) score += 0.5;

    // Protein: >= 10g per 100g = excellent, >= 5g = good
    if (nutrients.protein >= 10) score += 1.5;
    else if (nutrients.protein >= 5) score += 1.0;
    else if (nutrients.protein >= 2) score += 0.5;

    // Low sugar: <= 2g = excellent, <= 5g = good
    if (nutrients.sugar <= 2) score += 1.0;
    else if (nutrients.sugar <= 5) score += 0.75;
    else if (nutrients.sugar <= 10) score += 0.25;

    // Low sodium: <= 140mg = good, <= 400mg = acceptable
    if (nutrients.sodium <= 140) score += 0.75;
    else if (nutrients.sodium <= 400) score += 0.25;

    // Low saturated fat: <= 1g = excellent, <= 3g = okay
    if (nutrients.saturatedFat <= 1) score += 0.75;
    else if (nutrients.saturatedFat <= 3) score += 0.25;

    // --- Negative signals ---
    // High sugar (> 20g → sugary drinks, candy)
    if (nutrients.sugar > 20) score -= 2.0;
    else if (nutrients.sugar > 10) score -= 1.0;

    // High saturated fat (> 10g → ultra-processed)
    if (nutrients.saturatedFat > 10) score -= 1.5;

    // High sodium (> 600mg → very salty processed food)
    if (nutrients.sodium > 600) score -= 1.0;

    // Clamp to 0–5
    return Math.round(Math.max(0, Math.min(5, score)));
}

/**
 * Determine food category from nutrient profile.
 */
function inferCategory(nutrients, itemName) {
    const name = itemName.toLowerCase();

    if (nutrients.sugar > 15 && nutrients.fiber < 1) return 'sugary_drink';
    if (nutrients.saturatedFat > 10) return 'processed_snack';
    if (nutrients.fiber >= 4 && nutrients.protein >= 5) return 'legume';
    if (nutrients.protein >= 15 && nutrients.saturatedFat < 3) return 'lean_protein';
    if (nutrients.fiber >= 3 && nutrients.protein < 5) return 'fresh_produce';
    if (nutrients.carbs >= 15 && nutrients.fiber >= 2) return 'whole_grain';
    if (nutrients.carbs >= 15 && nutrients.fiber < 2) return 'refined_grain';
    if (nutrients.totalFat >= 10 && nutrients.saturatedFat < 4) return 'healthy_fat';
    if (name.includes('milk') || name.includes('yogurt') || name.includes('cheese')) return 'dairy';
    if (name.includes('frozen')) return 'frozen_veg';
    if (name.includes('canned') || name.includes('can ')) return 'canned_veg';

    return 'other';
}

/**
 * Main function: look up an item by name + quantity + unit, return classification.
 * Returns null if USDA can't find the item.
 */
async function lookupItem(itemName, quantity = 1, unit = 'ea') {
    const result = await fetchNutrients(itemName);
    if (!result) return null;

    const gramsPerUnit = UNIT_TO_GRAMS[unit] || 100;
    const totalGrams = quantity * gramsPerUnit;
    // Scale nutrients to the actual quantity purchased
    const scalingFactor = totalGrams / 100;

    // Per-unit nutrients (scaled to what was actually purchased in lb, oz, etc.)
    const scaledNutrients = {};
    for (const [key, val] of Object.entries(result.nutrients)) {
        scaledNutrients[key] = parseFloat((val * scalingFactor).toFixed(2));
    }

    // Health score is based on per-100g density (not scaled) — density scoring is universal
    const healthScore = calculateHealthScore(result.nutrients);
    const category = inferCategory(result.nutrients, itemName);

    return {
        name: itemName,
        fdcMatch: result.description,
        category,
        healthScore,
        isCultural: false,   // Gemini will override this if needed
        quantity,
        unit,
        totalGrams: parseFloat(totalGrams.toFixed(1)),
        nutrientsPer100g: result.nutrients,
        nutrientsTotal: scaledNutrients,
    };
}

module.exports = { lookupItem, calculateHealthScore, inferCategory };
