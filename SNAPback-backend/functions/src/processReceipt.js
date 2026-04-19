const { onObjectFinalized } = require('firebase-functions/v2/storage');
const { ImageAnnotatorClient } = require('@google-cloud/vision');
const { parseReceiptText } = require('./receipt_parser'); // Roshini's module
const admin = require('firebase-admin');

if (!admin.apps.length) admin.initializeApp();

const visionClient = new ImageAnnotatorClient();
const db = admin.firestore();

exports.processReceipt = onObjectFinalized({ cpu: 2, region: 'us-east1' }, async (event) => {
  const filePath = event.data.name; // receipts/{uid}/{tripId}.jpg
  const parts = filePath.split('/');
  
  // Example path: receipts/user123/trip456.jpg
  if (parts.length < 3 || parts[0] !== 'receipts') {
    console.log(`Skipping OCR for non-receipt file: ${filePath}`);
    return;
  }
  
  const uid = parts[1];
  const tripId = parts[2].split('.')[0]; // remove extension

  // Call Google Cloud Vision OCR
  const [result] = await visionClient.textDetection(`gs://${event.data.bucket}/${filePath}`);
  const rawText = result.fullTextAnnotation?.text || '';

  // Parse raw text into structured items
  const items = parseReceiptText(rawText); // Roshini's parser

  // Save and trigger next function
  await db.collection('users').doc(uid).collection('trips').doc(tripId)
    .update({ rawItems: items, status: 'ocr_done' });
});
