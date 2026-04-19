/**
 * test_bridge.js
 * End-to-end test: Simulated classifier output → bridge → scoring engine → UI output
 */

require('dotenv').config();
const { processTrip } = require('./src/usda_to_scoring_bridge');

// Simulated output from classifyItems() (what Roshini's classifier produces)
const classifiedItems = [
    { name: 'onion', price: 2.50, quantity: 3, unit: 'kg', category: 'fresh_produce', healthScore: 3, isCultural: false, source: 'usda' },
    { name: 'apple', price: 3.00, quantity: 1, unit: 'lb', category: 'fresh_fruit', healthScore: 3, isCultural: false, source: 'usda' },
    { name: 'plantains', price: 1.50, quantity: 1, unit: 'lb', category: 'fresh_produce', healthScore: 4, isCultural: true, source: 'gemini' },
    { name: 'lentils', price: 3.99, quantity: 2, unit: 'lb', category: 'legume', healthScore: 5, isCultural: false, source: 'usda' },
    { name: 'chicken breast', price: 7.49, quantity: 1.5, unit: 'lb', category: 'lean_protein', healthScore: 4, isCultural: false, source: 'usda' },
    { name: 'paneer', price: 4.00, quantity: 0.5, unit: 'lb', category: 'dairy', healthScore: 3, isCultural: true, source: 'gemini' },
    { name: 'coca cola', price: 1.89, quantity: 2, unit: 'l', category: 'sugary_drink', healthScore: 0, isCultural: false, source: 'usda' },
    { name: 'potato chips', price: 3.50, quantity: 1, unit: 'ea', category: 'processed_snack', healthScore: 1, isCultural: false, source: 'usda' },
    { name: 'waffles', price: 3.99, quantity: 1, unit: 'ea', category: 'refined_grain', healthScore: 2, isCultural: false, source: 'usda' },
];

// User context (would come from Firestore in production)
const uid = 'user_roshini_test';
const currentMonthProgress = 5.00;   // $5 already accumulated this month
const snapAmount = 400;     // $400/month SNAP → target = $100 (25%)

console.log('=== SNAPback: Full Pipeline Test ===\n');
console.log(`User SNAP: $${snapAmount}/month`);
console.log(`Monthly Target: $${snapAmount * 0.25} (25% of SNAP)`);
console.log(`Progress before this trip: $${currentMonthProgress}\n`);

const result = processTrip(classifiedItems, uid, currentMonthProgress, snapAmount);

console.log('\n=== UI OUTPUT ===');
console.log(`\n✅ Trip Contribution Value: $${result.contributionValue}`);
console.log(`🎯 Points Earned This Trip: ${result.pointsEarned} pts`);
console.log(`\n📊 Monthly Progress: $${result.newMonthlyProgress} / $${result.monthlyTarget}`);
console.log(`🏆 Target Hit: ${result.targetHit}`);
if (result.targetHit) {
    console.log(`💰 Reward Unlocked: $${result.rewardAmount} bonus SNAP credit!`);
}

console.log('\n=== Eligible Trip Items (sent to scoring engine) ===');
result.tripItems.forEach(i => {
    console.log(`  • ${i.name}: ${i.weightKg}kg, category: ${i.category}, score: ${i.healthScore}/5`);
});
