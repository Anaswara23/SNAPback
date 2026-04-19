// Main entry point - Export Anaswara's Cloud Functions

const { processReceipt } = require('./src/processReceipt');
const { classifyTrip } = require('./src/classifyTrip');
const { scoreTrip } = require('./src/scoreTrip');

exports.processReceipt = processReceipt;
exports.classifyTrip = classifyTrip;
exports.scoreTrip = scoreTrip;
