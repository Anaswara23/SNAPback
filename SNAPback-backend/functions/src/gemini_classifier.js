/**
 * gemini_classifier.js
 * Classifies grocery items using a 3-tier fallback chain:
 * 1. USDA FoodData Central API (real nutrient data → math formula → health score)
 * 2. Gemini 1.5 Flash AI (for items USDA doesn't know)
 * 3. Default: healthScore 2, category "other"
 *
 * Input items format: [{ name, price, quantity, unit }]
 * Output format: [{ name, category, healthScore, isCultural, quantity, unit, source }]
 */

const { GoogleGenerativeAI } = require('@google/generative-ai');
const { lookupItem } = require('./usda_lookup');
const admin = require('firebase-admin');

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY);

/**
 * Classify a single item using USDA first, then Gemini.
 */
async function classifyOneItem(item, culturalPrefs) {
  // --- TIER 1: USDA FoodData Central ---
  try {
    const usdaResult = await lookupItem(item.name, item.quantity, item.unit);
    if (usdaResult) {
      console.log(`[USDA] ${item.name} -> score ${usdaResult.healthScore} (${usdaResult.category})`);
      return {
        name: item.name,
        price: item.price,
        quantity: item.quantity,
        unit: item.unit,
        category: usdaResult.category,
        healthScore: usdaResult.healthScore,
        isCultural: false,
        totalGrams: usdaResult.totalGrams,
        source: 'usda',
      };
    }
  } catch (e) {
    console.warn(`[USDA] Failed for "${item.name}": ${e.message}`);
  }

  // --- TIER 2: Gemini AI ---
  try {
    const model = genAI.getGenerativeModel({ model: 'gemini-1.5-flash' });

    const prompt = `
      You are a nutrition classifier for a SNAP food rewards app called SNAPback.
      Cultural preferences of this user: ${culturalPrefs.join(', ')}.
      
      Classify this ONE grocery item and return a single JSON object with:
      - name: cleaned item name (string)
      - category: one of [fresh_produce, whole_grain, lean_protein, dairy,
        legume, healthy_fat, canned_veg, frozen_veg, refined_grain,
        processed_snack, sugary_drink, candy, other]
      - healthScore: integer 0 to 5 ONLY
      - isCultural: boolean (true if this is a culturally specific food)

      RULES:
      - Plantains, yuca, taro, bitter melon, chayote, nopales → fresh_produce, score 5
      - Sofrito, miso, garam masala, za'atar, tahini → healthy_fat, score 3
      - Dal, lentils, chickpeas, edamame, black beans → legume, score 5
      - Score is for nutrient density, NOT western food assumptions
      - Quantity: ${item.quantity} ${item.unit} — factor this into your assessment if relevant
      - Return ONLY a valid JSON object, no explanation, no markdown

      Item: "${item.name}"
    `;

    const result = await model.generateContent(prompt);
    let text = result.response.text().trim()
      .replace(/```json/g, '').replace(/```/g, '').trim();

    const parsed = JSON.parse(text);
    console.log(`[Gemini] ${item.name} -> score ${parsed.healthScore} (${parsed.category})`);
    return {
      name: item.name,
      price: item.price,
      quantity: item.quantity,
      unit: item.unit,
      category: parsed.category,
      healthScore: parsed.healthScore,
      isCultural: parsed.isCultural || false,
      source: 'gemini',
    };
  } catch (e) {
    console.warn(`[Gemini] Failed for "${item.name}": ${e.message}`);
  }

  // --- TIER 3: Default fallback ---
  console.warn(`[Default] Using fallback for "${item.name}"`);
  return {
    name: item.name,
    price: item.price,
    quantity: item.quantity,
    unit: item.unit,
    category: 'other',
    healthScore: 2,
    isCultural: false,
    source: 'default',
  };
}

/**
 * Classify all items in a receipt.
 * Logs failures to Firestore: classificationErrors/{timestamp}
 */
async function classifyItems(items, culturalPrefs) {
  const results = [];

  for (const item of items) {
    try {
      const classified = await classifyOneItem(item, culturalPrefs);
      results.push(classified);
    } catch (e) {
      // Log to Firestore for debugging
      try {
        const db = admin.firestore();
        await db.collection('classificationErrors').add({
          itemName: item.name,
          error: e.message,
          timestamp: new Date().toISOString(),
        });
      } catch (_) { }

      // Push a safe default so the whole receipt isn't broken
      results.push({
        name: item.name,
        price: item.price,
        quantity: item.quantity,
        unit: item.unit,
        category: 'other',
        healthScore: 2,
        isCultural: false,
        source: 'error',
      });
    }
  }

  return results;
}

module.exports = { classifyItems };
