require('dotenv').config();
const { lookupItem } = require('./src/usda_lookup');

// Roshini's test items — using realistic receipt quantities
const testItems = [
    { name: 'orange', quantity: 3, unit: 'ea' },
    { name: 'onion', quantity: 2, unit: 'lb' },
    { name: 'apple', quantity: 1, unit: 'lb' },
    { name: 'beef', quantity: 1.5, unit: 'lb' },
    { name: 'tomato', quantity: 1, unit: 'lb' },
    { name: 'paneer', quantity: 0.5, unit: 'lb' },
    { name: 'waffles', quantity: 1, unit: 'ea' },
];

async function runTest() {
    console.log('=== USDA LOOKUP TEST: Roshini\'s Items ===\n');
    for (const item of testItems) {
        const result = await lookupItem(item.name, item.quantity, item.unit);
        if (result) {
            console.log(`✅ ${item.quantity} ${item.unit}  "${item.name}"`);
            console.log(`   → Score: ${result.healthScore}/5 | Category: ${result.category}`);
            console.log(`   → USDA matched: "${result.fdcMatch}"`);
            console.log(`   → Nutrients per 100g: fiber ${result.nutrientsPer100g.fiber}g, protein ${result.nutrientsPer100g.protein}g, sugar ${result.nutrientsPer100g.sugar}g, sodium ${result.nutrientsPer100g.sodium}mg`);
            console.log('');
        } else {
            console.log(`❌ "${item.name}" → Not found in USDA → will fall back to Gemini\n`);
        }
    }
}

runTest().catch(console.error);
