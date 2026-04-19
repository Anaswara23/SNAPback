/**
 * test_full_pipeline.js
 * Full end-to-end live test:
 * Receipt Text → Parser → USDA/Gemini Classifier → Bridge → Scoring Engine → UI Output
 */

require('dotenv').config();
const { parseReceiptText } = require('./src/receipt_parser');
const { classifyItems } = require('./src/gemini_classifier');
const { processTrip } = require('./src/usda_to_scoring_bridge');

// --- Simulated realistic receipt (OCR output from Google Vision) ---
const rawReceiptText = `
WALMART SUPERCENTER
123 MAIN ST, ATLANTA GA
04/19/2026  09:42AM

PRODUCE
ONION 3LB             $2.49
TOMATOES 1LB          $1.99
PLANTAINS 2LB         $2.50
BOK CHOY 0.5LB        $1.89

PROTEIN
CHICKEN BREAST 1.5LB  $7.99
LENTILS 2LB           $3.49

GRAINS
BROWN RICE 2LB        $3.29
WHITE BREAD            $2.49

DAIRY
PANEER 0.5LB          $4.99

SNACKS/DRINKS
POTATO CHIPS           $3.50
COCA COLA 2L           $1.89
GUMMY BEARS            $2.00

SUBTOTAL              $38.60
TAX                    $1.20
TOTAL                 $39.80
`;

// --- User context (from Firestore in production) ---
const USER = {
    uid: 'test_user_roshini',
    culturalPrefs: ['Caribbean', 'South Asian'],
    snapAmount: 400,          // $400/month SNAP
    currentMonthProgress: 12.00,        // $12 already earned this month
};

async function runFullPipeline() {
    console.log('╔══════════════════════════════════════════╗');
    console.log('║   SNAPback — Full Pipeline Live Test     ║');
    console.log('╚══════════════════════════════════════════╝\n');

    // ── STEP 1: Parse Receipt ──
    console.log('📄 STEP 1: Parsing receipt...');
    const parsedItems = parseReceiptText(rawReceiptText);
    console.log(`   Found ${parsedItems.length} items:\n`);
    parsedItems.forEach(i => console.log(`   • ${i.name} (${i.quantity} ${i.unit}) — $${i.price}`));

    // ── STEP 2: Classify with USDA + Gemini ──
    console.log('\n🔬 STEP 2: Classifying items (USDA → Gemini fallback)...\n');
    const classifiedItems = await classifyItems(parsedItems, USER.culturalPrefs);
    console.log('\n   Classification results:');
    classifiedItems.forEach(i => {
        const src = i.source === 'usda' ? '🟢 USDA' : i.source === 'gemini' ? '🤖 Gemini' : '⚪ Default';
        console.log(`   ${src} | ${i.name} → score: ${i.healthScore}/5, category: ${i.category}${i.isCultural ? ' 🌍 cultural' : ''}`);
    });

    // ── STEP 3: Bridge → Scoring Engine ──
    console.log('\n⚙️  STEP 3: Running through scoring engine...\n');
    const result = processTrip(
        classifiedItems,
        USER.uid,
        USER.currentMonthProgress,
        USER.snapAmount
    );

    // ── STEP 4: UI Output ──
    console.log('\n╔══════════════════════════════════════════╗');
    console.log('║           UI DASHBOARD OUTPUT            ║');
    console.log('╚══════════════════════════════════════════╝\n');

    console.log(`👤 User SNAP budget:      $${USER.snapAmount}/month`);
    console.log(`🎯 Monthly Target:         $${(USER.snapAmount * 0.25).toFixed(2)} (25% of SNAP)`);
    console.log(`📊 Progress before trip:   $${USER.currentMonthProgress.toFixed(2)}`);
    console.log(`\n✅ This trip contributed:  $${result.contributionValue}`);
    console.log(`🎮 Points earned:          ${result.pointsEarned} pts`);
    console.log(`\n📈 New monthly progress:   $${result.newMonthlyProgress} / $${result.monthlyTarget}`);
    console.log(`   Progress bar:           ${Math.min(100, Math.round((result.newMonthlyProgress / result.monthlyTarget) * 100))}%`);
    console.log(`\n🏆 Target Hit:             ${result.targetHit ? '✅ YES — SHOW CELEBRATION UI!' : '❌ Not yet'}`);
    if (result.targetHit) {
        console.log(`💰 Reward Amount:          $${result.rewardAmount} bonus SNAP credit deposited!`);
    }

    console.log('\n── Eligible Items That Earned Points ──');
    result.tripItems.forEach(i => {
        const rate = { fresh_produce: 3, fresh_fruit: 3, whole_grains: 1.5, legumes: 1.5, lean_protein: 4, cultural_staple: 2 }[i.category];
        const val = (i.weightKg * rate).toFixed(2);
        console.log(`   • ${i.name}: ${i.weightKg}kg × $${rate}/kg = $${val} | score: ${i.healthScore}/5`);
    });

    console.log('\n── Items Filtered Out (no points) ──');
    classifiedItems
        .filter(i => i.healthScore < 3)
        .forEach(i => console.log(`   ✗ ${i.name} (score: ${i.healthScore}/5)`));
}

runFullPipeline().catch(console.error);
