const { onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { calculateScore, calculateBonuses } = require('./scoring_engine'); // Hidhayath
const admin = require('firebase-admin');
const { FieldValue } = require('firebase-admin/firestore');

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

exports.scoreTrip = onDocumentUpdated('users/{uid}/trips/{tripId}', async (event) => {
  const after = event.data.after.data();
  if (after.status !== 'classified') return;
  const { uid } = event.params;

  const userDoc = await db.collection('users').doc(uid).get();
  
  if (!userDoc.exists) {
    console.error(`User document ${uid} not found`);
    return;
  }
  
  const { snapAmount = 0, familySize = 1 } = userDoc.data();

  // Hidhayath's scoring engine
  const result = calculateScore(after.scoredItems, snapAmount, familySize);
  const bonuses = await calculateBonuses(uid, result, db);

  const totalPoints = result.score + bonuses.total;
  const credit = totalPoints / 100;

  const batch = db.batch();
  batch.update(event.data.after.ref, {
    ...result, 
    pointsEarned: totalPoints,
    credit, 
    status: 'done', 
    bonuses: bonuses.details
  });
  
  batch.update(db.collection('users').doc(uid), {
    totalPoints: FieldValue.increment(totalPoints),
    monthlyCredit: FieldValue.increment(credit),
    currentStreak: result.newStreak || 0
  });
  
  await batch.commit();
});
