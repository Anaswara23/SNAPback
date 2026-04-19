const { onDocumentUpdated } = require('firebase-functions/v2/firestore');
const { classifyItems } = require('./gemini_classifier'); // Roshini's module
const admin = require('firebase-admin');

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

exports.classifyTrip = onDocumentUpdated('users/{uid}/trips/{tripId}', async (event) => {
  const before = event.data.before.data();
  const after = event.data.after.data();
  if (before.status === after.status) return; // no change
  if (after.status !== 'ocr_done') return;

  const { uid, tripId } = event.params;
  const userDoc = await db.collection('users').doc(uid).get();
  
  if (!userDoc.exists) {
    console.error(`User document ${uid} not found`);
    return;
  }
  
  const { culturalPrefs = [] } = userDoc.data();

  // Check cache first for each item
  const cachedAndNew = await Promise.all(after.rawItems.map(async (item) => {
    const cacheKey = item.name.toLowerCase().replace(/\s+/g, '_');
    const cached = await db.collection('foodCache').doc(cacheKey).get();
    if (cached.exists) return { ...item, ...cached.data() };
    return item; // will be classified by Gemini
  }));

  const uncached = cachedAndNew.filter(i => !i.healthScore);
  const classified = uncached.length > 0
    ? await classifyItems(uncached, culturalPrefs)
    : [];

  // Merge + save cache
  const allScored = cachedAndNew.map(item => {
    const found = classified.find(c => c.name === item.name);
    return found || item;
  });

  await event.data.after.ref.update({ scoredItems: allScored, status: 'classified' });
});
