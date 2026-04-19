const { onObjectFinalized } = require("firebase-functions/v2/storage");
const { onDocumentUpdated } = require("firebase-functions/v2/firestore");
const { defineSecret } = require("firebase-functions/params");
const { logger } = require("firebase-functions");
const { initializeApp } = require("firebase-admin/app");
const { getFirestore, FieldValue, Timestamp } = require("firebase-admin/firestore");
const { Storage } = require("@google-cloud/storage");
const { GoogleGenAI } = require("@google/genai");

initializeApp();
const db = getFirestore();
const storage = new Storage();

const GEMINI_API_KEY = defineSecret("GEMINI_API_KEY");
const GEMINI_MODEL = "gemini-2.5-flash";

// ─── Receipt parsing schema (unchanged) ───────────────────────────────────────

// Only edible/drinkable categories. Non-edible items (toilet paper, laundry,
// cleaning supplies, paper goods, pet food, etc.) must be excluded entirely
// upstream — never emitted by the parser.
const ALLOWED_CATEGORIES = [
  "fresh_produce",
  "whole_grain",
  "lean_protein",
  "legume",
  "dairy",
  "healthy_fat",
  "processed_snack",
  "beverage",
  "frozen_meal",
  "condiment",
  "bakery",
  "other",
];

const ALLOWED_UNITS = ["ea", "lb", "oz", "kg", "g", "ct", "pk", "fl_oz", "gal"];

const RECEIPT_RESPONSE_SCHEMA = {
  type: "object",
  properties: {
    storeName: { type: "string", description: "Store/merchant name as printed on the receipt." },
    storeLocation: { type: "string", description: "City/address line if visible, otherwise empty string." },
    receiptDate: { type: "string", description: "Receipt date in YYYY-MM-DD if detectable, otherwise empty string." },
    items: {
      type: "array",
      description: "All purchased line items. Skip subtotal/tax/total/store info/payment info/bottle deposits/loyalty discounts.",
      items: {
        type: "object",
        properties: {
          name: {
            type: "string",
            description:
              "Cleaned, human-readable product name. Expand abbreviations: 'ROMAINE' -> 'romaine lettuce', 'GRND BEEF 85/15' -> 'ground beef 85/15', 'WHL MLK' -> 'whole milk', 'LG EGGS' -> 'large eggs', 'PNBTR' -> 'peanut butter', 'YOGHURT' -> 'yogurt', 'CHKN' -> 'chicken', 'STRWBRY' -> 'strawberries', 'TOM' -> 'tomato'. Lowercase, no SKU codes, no trailing tax flags like F/T/FT.",
          },
          quantity: { type: "number", description: "Number of units purchased. Default to 1 if not stated." },
          unit: {
            type: "string",
            enum: ALLOWED_UNITS,
            description: "Unit of measure. Use 'ea' if not specified.",
          },
          unitPrice: { type: "number", description: "Price per single unit in dollars (totalPrice / quantity). Always > 0." },
          totalPrice: { type: "number", description: "Total line price in dollars after any line-item discount. Always > 0." },
          category: {
            type: "string",
            enum: ALLOWED_CATEGORIES,
            description:
              "Best-fit category. fresh_produce=fruits/vegetables. whole_grain=oats/quinoa/brown rice/whole wheat. lean_protein=chicken breast/turkey/fish/tofu/eggs/greek yogurt. legume=beans/lentils/chickpeas. dairy=milk/cheese/regular yogurt. healthy_fat=olive oil/avocado/nuts. processed_snack=chips/cookies/candy/soda. beverage=juice/sparkling water/coffee. bakery=bread/bagels. condiment=salsa/sauces. frozen_meal=frozen dinners. other=anything else EDIBLE that doesn't fit. NEVER emit non-edible items.",
          },
          healthScore: {
            type: "integer",
            description:
              "Health score 1-5. 5=very healthy whole foods. 4=lean proteins, low-sugar dairy. 3=neutral staples. 2=processed snacks/refined grains/sugary drinks. 1=alcohol, candy, soda, fried snacks.",
          },
          isCultural: {
            type: "boolean",
            description:
              "True if item is associated with a specific cultural cuisine (e.g. miso, tofu, plantain, yuca, masala, kimchi, tahini, nopales, paneer, naan, salsa, tortilla, injera, harissa, gochujang, sambal, jerk seasoning).",
          },
        },
        required: ["name", "quantity", "unit", "unitPrice", "totalPrice", "category", "healthScore", "isCultural"],
      },
    },
    subtotal: { type: "number", description: "Subtotal in dollars if visible, else 0." },
    tax: { type: "number", description: "Tax in dollars if visible, else 0." },
    total: { type: "number", description: "Grand total in dollars if visible, else 0." },
  },
  required: ["items"],
};

const SYSTEM_PROMPT = `You are an expert grocery receipt parser focused on FOOD AND BEVERAGES ONLY. You will be given a photo of a printed retail receipt.

Extract every EDIBLE line item that a shopper would recognize as food or drink. For each item:
- Expand short abbreviations into normal English product names (e.g. "ROMAINE" -> "romaine lettuce").
- Determine quantity, unit, unit price, and total price in US dollars.
- Pick the best category from the allowed enum (food/beverage categories only).
- Assign an honest health score from 1 (least healthy) to 5 (most healthy).
- Mark items associated with a specific cultural cuisine as isCultural=true.

CRITICAL — EXCLUDE all NON-EDIBLE items entirely. Do NOT emit them at all:
- Toilet paper, paper towels, napkins, tissues
- Laundry detergent, fabric softener, dryer sheets, bleach
- Dish soap, hand soap, body wash, shampoo, conditioner, toothpaste, deodorant
- Cleaning supplies (sprays, wipes, sponges, mops)
- Trash bags, ziplock/storage bags, aluminum foil, plastic wrap, parchment paper
- Pet food, pet treats, pet litter, pet supplies
- Diapers, baby wipes, feminine hygiene
- Vitamins, supplements, medicine, OTC drugs
- Cosmetics, makeup, skincare
- Batteries, light bulbs, candles, matches, lighters
- Charcoal, lighter fluid, propane
- Greeting cards, gift wrap, magazines, books
- Tobacco, cigarettes, vapes, lottery tickets
- Anything else that is not consumed as food or drink

Also strictly EXCLUDE these LINE TYPES:
- Subtotals, taxes, totals, payment lines (VISA, CASH, CHANGE)
- Store header (name, address, phone, store #)
- Bottle deposits, container deposits, bag fees
- Loyalty/coupon/discount lines that aren't actual products
- Receipt footers, dates, transaction IDs

If you are unsure whether an item is edible, EXCLUDE it. False negatives are acceptable; false positives are not. The parsed list must contain only food and beverages a person would consume.

If a line is just a price with no product name on the same OR adjacent line, infer the product name from the line above/below using receipt layout.

Return STRICT JSON matching the provided schema. Do not include any commentary outside JSON.`;

// ─── Recipe-generation schema ────────────────────────────────────────────────

const RECIPES_RESPONSE_SCHEMA = {
  type: "object",
  properties: {
    recipes: {
      type: "array",
      description: "2 to 3 nutritious recipe suggestions using items from the trip.",
      items: {
        type: "object",
        properties: {
          title: { type: "string", description: "Short recipe name." },
          description: {
            type: "string",
            description:
              "1-2 sentence description that mentions why it's nutritious.",
          },
          usesItems: {
            type: "array",
            items: { type: "string" },
            description: "Names of items from the user's trip that this recipe uses.",
          },
          cuisine: {
            type: "string",
            description:
              "Cuisine label, e.g. 'Mediterranean', 'South Asian', 'Mexican', 'American'.",
          },
          prepTimeMinutes: {
            type: "integer",
            description: "Total prep + cook time in minutes (10-60 typical).",
          },
          healthScore: {
            type: "integer",
            description: "Recipe health score 1-5 (5 = healthiest).",
          },
          steps: {
            type: "array",
            items: { type: "string" },
            description: "3-5 short prep/cook steps.",
          },
        },
        required: [
          "title",
          "description",
          "usesItems",
          "cuisine",
          "prepTimeMinutes",
          "healthScore",
          "steps",
        ],
      },
    },
  },
  required: ["recipes"],
};

// ─── Helpers ─────────────────────────────────────────────────────────────────

function toNumber(value, fallback = 0) {
  if (typeof value === "number" && Number.isFinite(value)) return value;
  if (typeof value === "string") {
    const parsed = Number(value);
    if (Number.isFinite(parsed)) return parsed;
  }
  return fallback;
}

function clamp(value, min, max) {
  return Math.max(min, Math.min(max, value));
}

function round2(value) {
  return Math.round(value * 100) / 100;
}

// Defensive substring blocklist — last line of defense against non-edible
// items that the model might still emit despite the system prompt.
const NON_EDIBLE_KEYWORDS = [
  "toilet paper", "paper towel", "napkin", "tissue", "kleenex",
  "detergent", "fabric softener", "dryer sheet", "bleach",
  "dish soap", "dishwasher", "hand soap", "body wash", "shampoo",
  "conditioner", "toothpaste", "toothbrush", "deodorant", "lotion",
  "cleaner", "cleaning", "disinfectant", "sanitizer", "bleach",
  "wipes", "sponge", "scrubber", "mop", "broom",
  "trash bag", "garbage bag", "ziplock", "ziploc", "foil",
  "plastic wrap", "saran", "parchment",
  "diaper", "baby wipe", "tampon", "pad ", "pads ", "pantyliner",
  "vitamin", "supplement", "medicine", "tylenol", "advil",
  "ibuprofen", "aspirin", "antacid",
  "makeup", "lipstick", "mascara", "skincare", "razor",
  "battery", "batteries", "light bulb", "lightbulb", "candle",
  "match", "lighter",
  "charcoal", "lighter fluid", "propane",
  "greeting card", "gift wrap", "magazine",
  "tobacco", "cigarette", "vape", "lottery",
  "pet food", "dog food", "cat food", "cat litter", "pet treat",
];

function isLikelyNonEdible(name) {
  const n = name.toLowerCase();
  return NON_EDIBLE_KEYWORDS.some((kw) => n.includes(kw));
}

function normalizeItem(raw) {
  const name = String(raw.name || "").trim().toLowerCase();
  if (!name) return null;
  if (isLikelyNonEdible(name)) {
    logger.info("Dropping non-edible item from receipt", { name });
    return null;
  }
  const quantity = Math.max(0.01, toNumber(raw.quantity, 1));
  const unit = ALLOWED_UNITS.includes(String(raw.unit)) ? String(raw.unit) : "ea";
  let totalPrice = toNumber(raw.totalPrice, 0);
  let unitPrice = toNumber(raw.unitPrice, 0);
  if (totalPrice <= 0 && unitPrice > 0) totalPrice = round2(unitPrice * quantity);
  if (unitPrice <= 0 && totalPrice > 0) unitPrice = round2(totalPrice / quantity);
  if (totalPrice <= 0) return null;
  const category = ALLOWED_CATEGORIES.includes(String(raw.category)) ? String(raw.category) : "other";
  const healthScore = clamp(Math.round(toNumber(raw.healthScore, 3)), 1, 5);
  return {
    name,
    quantity,
    unit,
    unitPrice: round2(unitPrice),
    totalPrice: round2(totalPrice),
    category,
    healthScore,
    isCultural: Boolean(raw.isCultural),
    source: "gemini_2_5_flash",
  };
}

async function downloadReceiptBuffer(bucketName, filePath) {
  const file = storage.bucket(bucketName).file(filePath);
  const [buffer] = await file.download();
  return buffer;
}

async function callGeminiReceipt(apiKey, imageBase64, mimeType) {
  const ai = new GoogleGenAI({ apiKey });
  const response = await ai.models.generateContent({
    model: GEMINI_MODEL,
    contents: [
      {
        role: "user",
        parts: [
          { inlineData: { mimeType, data: imageBase64 } },
          { text: "Parse this receipt according to the schema. Return only JSON." },
        ],
      },
    ],
    config: {
      systemInstruction: SYSTEM_PROMPT,
      responseMimeType: "application/json",
      responseJsonSchema: RECEIPT_RESPONSE_SCHEMA,
      temperature: 0.1,
      thinkingConfig: { thinkingBudget: 0 },
    },
  });
  const text = response.text || "";
  if (!text) throw new Error("Gemini returned empty response");
  try {
    return JSON.parse(text);
  } catch (e) {
    logger.error("Failed to parse Gemini receipt JSON", { textPreview: text.slice(0, 500) });
    throw new Error("Gemini returned non-JSON output");
  }
}

async function callGeminiRecipes(apiKey, items, prefs) {
  if (!items.length) return [];
  const ai = new GoogleGenAI({ apiKey });
  const itemList = items
    .map(
      (i) =>
        `- ${i.name} (${i.category}, health ${i.healthScore}/5${i.isCultural ? ", cultural" : ""})`,
    )
    .join("\n");
  const prefLine =
    prefs && prefs.length
      ? `The household enjoys these cuisines: ${prefs.join(", ")}. Lean recipes toward these where it makes sense.`
      : "No specific cuisine preferences. Pick globally familiar nutritious recipes.";

  const prompt = `The user just bought these items at the grocery store:
${itemList}

${prefLine}

Suggest 2 or 3 nutritious recipes that USE THE ITEMS THEY ALREADY OWN as primary ingredients. Each recipe should:
- Be realistic for a home cook (no obscure equipment)
- Heavily favor the higher-health items (4-5 stars) for the main components
- Take 10-45 minutes typically
- Include 3-5 concise steps

Return STRICT JSON matching the schema. Do not include commentary.`;

  const response = await ai.models.generateContent({
    model: GEMINI_MODEL,
    contents: [{ role: "user", parts: [{ text: prompt }] }],
    config: {
      responseMimeType: "application/json",
      responseJsonSchema: RECIPES_RESPONSE_SCHEMA,
      temperature: 0.6,
      thinkingConfig: { thinkingBudget: 0 },
    },
  });
  const text = response.text || "";
  if (!text) return [];
  try {
    const parsed = JSON.parse(text);
    return Array.isArray(parsed.recipes) ? parsed.recipes : [];
  } catch (e) {
    logger.warn("Failed to parse Gemini recipes JSON", { textPreview: text.slice(0, 500) });
    return [];
  }
}

// ─── processReceipt (unchanged behavior) ─────────────────────────────────────

exports.processReceipt = onObjectFinalized(
  {
    cpu: 2,
    memory: "1GiB",
    timeoutSeconds: 120,
    region: "us-east1",
    maxInstances: 20,
    secrets: [GEMINI_API_KEY],
  },
  async (event) => {
    const filePath = String(event.data?.name || "");
    const bucket = String(event.data?.bucket || "");
    const contentType = String(event.data?.contentType || "image/jpeg");
    const parts = filePath.split("/");
    if (parts.length < 3 || parts[0] !== "receipts") {
      logger.info("processReceipt: skipping non-receipt object", { filePath });
      return;
    }

    const uid = parts[1];
    const tripId = parts[2].replace(/\.[^.]+$/, "");
    const tripRef = db.collection("users").doc(uid).collection("trips").doc(tripId);

    logger.info("processReceipt: start", { tripId, uid, filePath });

    try {
      const apiKey = GEMINI_API_KEY.value();
      if (!apiKey) throw new Error("GEMINI_API_KEY secret is not configured");

      const buffer = await downloadReceiptBuffer(bucket, filePath);
      logger.info("processReceipt: downloaded receipt", { tripId, bytes: buffer.length });

      const imageBase64 = buffer.toString("base64");
      const geminiResult = await callGeminiReceipt(apiKey, imageBase64, contentType);

      const rawItems = Array.isArray(geminiResult.items) ? geminiResult.items : [];
      const scoredItems = rawItems.map(normalizeItem).filter((i) => i !== null);

      logger.info("processReceipt: gemini parsed", {
        tripId,
        rawItemsCount: rawItems.length,
        scoredItemsCount: scoredItems.length,
        storeName: geminiResult.storeName || null,
      });

      await tripRef.set(
        {
          receiptPath: filePath,
          storeName: String(geminiResult.storeName || ""),
          storeLocation: String(geminiResult.storeLocation || ""),
          receiptDate: String(geminiResult.receiptDate || ""),
          subtotal: toNumber(geminiResult.subtotal, 0),
          tax: toNumber(geminiResult.tax, 0),
          totalAmount: toNumber(geminiResult.total, 0),
          rawItems: scoredItems,
          scoredItems,
          status: "classified",
          processingError: FieldValue.delete(),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    } catch (error) {
      logger.error("processReceipt: failed", {
        tripId,
        error: String(error),
        stack: error?.stack,
      });
      await tripRef.set(
        {
          status: "failed_processing",
          processingError: String(error?.message || error),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
    }
  },
);

// ─── classifyTrip: legacy ocr_done promoter ──────────────────────────────────

exports.classifyTrip = onDocumentUpdated(
  {
    document: "users/{uid}/trips/{tripId}",
    region: "us-central1",
    maxInstances: 5,
  },
  async (event) => {
    const before = event.data?.before?.data() || {};
    const after = event.data?.after?.data() || {};
    if (before.status === after.status) return;
    if (String(after.status || "") !== "ocr_done") return;
    if (Array.isArray(after.scoredItems) && after.scoredItems.length > 0) return;

    logger.info("classifyTrip: legacy ocr_done doc detected, promoting to classified", {
      tripId: event.params.tripId,
    });
    await event.data.after.ref.set(
      {
        status: "classified",
        scoredItems: Array.isArray(after.rawItems) ? after.rawItems : [],
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  },
);

// ─── New reward model ────────────────────────────────────────────────────────

/**
 * Tier rates by health score. Cultural items get +1pp on top.
 * 5★ = 5%, 4★ = 3%, 3★ = 1%, 2★/1★ = 0%.
 */
function cashbackRate(healthScore, isCultural) {
  let base = 0;
  if (healthScore >= 5) base = 0.05;
  else if (healthScore === 4) base = 0.03;
  else if (healthScore === 3) base = 0.01;
  else base = 0;
  if (base > 0 && isCultural) base += 0.01;
  return base;
}

/**
 * Monthly cashback cap: min(10% × snapAmount, $25 × familySize).
 * Falls back to a sensible default for users without a profile.
 */
function computeMonthlyCap(snapAmount, familySize) {
  const snap = toNumber(snapAmount, 480);
  const size = Math.max(1, Math.round(toNumber(familySize, 1)));
  const snapTier = snap * 0.10;
  const familyTier = 25 * size;
  return round2(Math.max(5, Math.min(snapTier, familyTier)));
}

function startOfCurrentMonthUtc() {
  const now = new Date();
  return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1));
}

function startOfNextMonthUtc() {
  const now = new Date();
  return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 1));
}

async function fetchUserProfile(uid) {
  try {
    const snap = await db.collection("users").doc(uid).get();
    if (!snap.exists) return {};
    return snap.data() || {};
  } catch (e) {
    logger.warn("fetchUserProfile failed", { uid, error: String(e) });
    return {};
  }
}

/**
 * Cashback is only redeemable when the household's average health score for
 * the calendar month is at or above this floor (out of 5). This nudges users
 * toward genuinely healthy spending — they can still earn cashback on
 * individual healthy items, but to actually receive the money on the 1st
 * they have to sustain a strong pattern across the whole month (4★ average
 * means they're consistently buying lean proteins / produce / whole grains).
 */
const REDEMPTION_THRESHOLD = 4.0;

async function sumPriorMonthStats(uid, currentTripId) {
  const monthStart = Timestamp.fromDate(startOfCurrentMonthUtc());
  const monthEnd = Timestamp.fromDate(startOfNextMonthUtc());
  const snap = await db
    .collection("users")
    .doc(uid)
    .collection("trips")
    .where("processedAt", ">=", monthStart)
    .where("processedAt", "<", monthEnd)
    .get();

  let totalCashback = 0;
  let weightedHealthSum = 0;
  let totalItemCount = 0;
  snap.forEach((doc) => {
    if (doc.id === currentTripId) return;
    const data = doc.data() || {};
    if (String(data.status || "") !== "completed") return;
    totalCashback += toNumber(data.contributionValue, 0);

    const items = Array.isArray(data.tripItems) ? data.tripItems : [];
    items.forEach((item) => {
      const score = clamp(toNumber(item.healthScore, 0), 0, 5);
      if (score > 0) {
        weightedHealthSum += score;
        totalItemCount += 1;
      }
    });
  });
  return {
    priorCashback: round2(totalCashback),
    priorWeightedHealth: weightedHealthSum,
    priorItemCount: totalItemCount,
  };
}

function extractTripItems(payload) {
  const candidates = [
    payload.scoredItems,
    payload.classifiedItems,
    payload.rawItems,
    payload.items,
    payload.parsedItems,
    payload.tripItems,
  ];
  const list = candidates.find((entry) => Array.isArray(entry)) || [];
  return list
    .map((item) => {
      const name = String(item.name || item.item || "").trim();
      if (!name) return null;
      const quantity = toNumber(item.quantity ?? 1, 1);
      const unit = String(item.unit || "ea");
      const unitPrice = toNumber(item.unitPrice ?? item.price ?? 0, 0);
      const totalPrice = toNumber(
        item.totalPrice ?? (quantity > 0 ? unitPrice * quantity : unitPrice),
        0,
      );
      const healthScore = clamp(
        Math.round(toNumber(item.healthScore ?? item.score ?? 3, 3)),
        1,
        5,
      );
      const category = String(item.category || "other");
      const isCultural = Boolean(item.isCultural);
      return {
        name,
        quantity,
        unit,
        unitPrice: round2(unitPrice),
        totalPrice: round2(totalPrice),
        healthScore,
        category,
        isCultural,
      };
    })
    .filter((item) => item !== null);
}

exports.scoreTrip = onDocumentUpdated(
  {
    document: "users/{uid}/trips/{tripId}",
    region: "us-central1",
    maxInstances: 20,
    secrets: [GEMINI_API_KEY],
    timeoutSeconds: 90,
    memory: "512MiB",
  },
  async (event) => {
    const afterRef = event.data?.after?.ref;
    const after = event.data?.after?.data();
    if (!afterRef || !after) return;

    const status = String(after.status || "");
    // Don't reprocess finalized docs.
    if (status === "completed" || status === "completed_no_items") return;

    const allowedTriggers = ["classified", "done", "ocr_done"];
    if (status && !allowedTriggers.includes(status)) return;

    const uid = event.params.uid;
    const tripId = event.params.tripId;

    const profile = await fetchUserProfile(uid);
    const monthlyCap = computeMonthlyCap(profile.snapAmount, profile.familySize);
    const priorStats = await sumPriorMonthStats(uid, tripId);

    // ── Empty-trip safeguard: still finalize the doc so the UI stops polling.
    const baseItems = extractTripItems(after);
    if (baseItems.length === 0) {
      const priorAvg =
        priorStats.priorItemCount > 0
          ? priorStats.priorWeightedHealth / priorStats.priorItemCount
          : 0;
      const redeemable =
        priorStats.priorCashback > 0 && priorAvg >= REDEMPTION_THRESHOLD;
      await afterRef.set(
        {
          tripItems: [],
          contributionValue: 0,
          monthlyCap,
          monthlyEarned: priorStats.priorCashback,
          monthlyAvgHealthScore: round2(priorAvg),
          redeemable,
          redemptionThreshold: REDEMPTION_THRESHOLD,
          // Legacy aliases for older clients still reading these names.
          monthlyTarget: monthlyCap,
          newMonthlyProgress: priorStats.priorCashback,
          status: "completed_no_items",
          processedAt: FieldValue.serverTimestamp(),
          updatedAt: FieldValue.serverTimestamp(),
        },
        { merge: true },
      );
      logger.info("scoreTrip: finalized empty result", { tripId });
      return;
    }

    // ── Compute per-item cashback (uncapped first).
    const enrichedItems = baseItems.map((item) => {
      const rate = cashbackRate(item.healthScore, item.isCultural);
      const cashbackEarned = round2(item.totalPrice * rate);
      return {
        ...item,
        cashbackRate: rate,
        cashbackEarned,
      };
    });

    const rawCashback = round2(
      enrichedItems.reduce((sum, i) => sum + i.cashbackEarned, 0),
    );

    // ── Apply monthly cap (per household), based on prior earnings this month.
    const remainingCap = Math.max(
      0,
      round2(monthlyCap - priorStats.priorCashback),
    );
    const cappedCashback = round2(Math.min(rawCashback, remainingCap));
    const monthlyEarnedAfter = round2(priorStats.priorCashback + cappedCashback);
    const wasCapped = cappedCashback < rawCashback - 0.005;

    // ── Rescale per-item cashback so the UI's "per-item earn" sums cleanly.
    let scaledItems = enrichedItems;
    if (wasCapped && rawCashback > 0) {
      const scale = cappedCashback / rawCashback;
      scaledItems = enrichedItems.map((i) => ({
        ...i,
        cashbackEarned: round2(i.cashbackEarned * scale),
      }));
    }

    // ── Compute monthly weighted health score (this trip + prior trips).
    const tripWeightedHealth = enrichedItems.reduce(
      (sum, i) => sum + i.healthScore,
      0,
    );
    const tripItemCount = enrichedItems.length;
    const tripAvgHealthScore = round2(tripWeightedHealth / tripItemCount);
    const monthlyWeightedHealth =
      priorStats.priorWeightedHealth + tripWeightedHealth;
    const monthlyItemCount = priorStats.priorItemCount + tripItemCount;
    const monthlyAvgHealthScore =
      monthlyItemCount > 0
        ? round2(monthlyWeightedHealth / monthlyItemCount)
        : 0;
    const redeemable =
      monthlyEarnedAfter > 0 && monthlyAvgHealthScore >= REDEMPTION_THRESHOLD;

    // ── Recipe suggestions (best-effort, never blocks scoring).
    let recipes = [];
    try {
      const apiKey = GEMINI_API_KEY.value();
      if (apiKey) {
        const prefs = Array.isArray(profile.culturalPrefs)
          ? profile.culturalPrefs
          : [];
        recipes = await callGeminiRecipes(apiKey, scaledItems, prefs);
        logger.info("scoreTrip: generated recipes", {
          tripId,
          count: recipes.length,
        });
      }
    } catch (e) {
      logger.warn("scoreTrip: recipe generation failed", {
        tripId,
        error: String(e),
      });
      recipes = [];
    }

    await afterRef.set(
      {
        tripItems: scaledItems,
        rawCashback,
        contributionValue: cappedCashback,
        wasCapped,
        monthlyCap,
        monthlyEarned: monthlyEarnedAfter,
        tripAvgHealthScore,
        monthlyAvgHealthScore,
        monthlyItemCount,
        redeemable,
        redemptionThreshold: REDEMPTION_THRESHOLD,
        // Legacy aliases for older clients still reading these names.
        monthlyTarget: monthlyCap,
        newMonthlyProgress: monthlyEarnedAfter,
        suggestedRecipes: recipes,
        status: "completed",
        processedAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

    logger.info("scoreTrip: wrote final payload", {
      tripId,
      itemCount: tripItemCount,
      rawCashback,
      cappedCashback,
      monthlyCap,
      monthlyEarnedAfter,
      tripAvgHealthScore,
      monthlyAvgHealthScore,
      redeemable,
      recipeCount: recipes.length,
      wasCapped,
    });
  },
);
