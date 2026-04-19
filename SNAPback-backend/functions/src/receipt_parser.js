/**
 * receipt_parser.js
 * Parses raw OCR text from Google Vision into structured items.
 * Extracts: name, price, quantity, unit
 * Example output: { name: "lentils", price: 3.99, quantity: 2, unit: "lb" }
 */

const SKIP_KEYWORDS = [
    'subtotal', 'sub total', 'tax', 'total', 'cashier', 'rewards',
    'points', 'visa', 'mastercard', 'cash', 'change', 'balance',
    'credit', 'debit', 'amount due', 'receipt', 'thank you',
    'member', 'savings', 'loyalty', 'phone', 'address', 'manager',
    'walmart', 'kroger', 'target', 'costco', 'aldi', 'trader joe',
    'whole foods', 'safeway', 'publix', 'cvs', 'walgreens', 'store #',
    'market', 'grocery', 'supermarket'
];

// Skip lines that look like dates or store IDs
const DATE_PATTERN = /^\d{1,2}[\/\-]\d{1,2}[\/\-]\d{2,4}$/;
const STOREID_PATTERN = /^\d{4,}$/;

// Unit patterns to detect on a receipt line
const UNIT_PATTERNS = [
    { regex: /(\d+\.?\d*)\s*lb[s]?\b/i, unit: 'lb' },
    { regex: /(\d+\.?\d*)\s*oz\b/i, unit: 'oz' },
    { regex: /(\d+\.?\d*)\s*kg\b/i, unit: 'kg' },
    { regex: /(\d+\.?\d*)\s*g\b/i, unit: 'g' },
    { regex: /(\d+\.?\d*)\s*ea\b/i, unit: 'ea' },
    { regex: /(\d+\.?\d*)\s*ct\b/i, unit: 'ct' },
    { regex: /(\d+\.?\d*)\s*pk\b/i, unit: 'pk' },
    { regex: /(\d+\.?\d*)\s*l\b/i, unit: 'l' },
    { regex: /(\d+\.?\d*)\s*ml\b/i, unit: 'ml' },
    { regex: /(\d+)\s*x\s*\d+/i, unit: 'ct' }, // e.g. 2x3 packs
];

// Abbreviation expansions
const ABBREVIATIONS = {
    'org': 'organic', 'whl': 'whole', 'brn': 'brown', 'chkn': 'chicken',
    'chix': 'chicken', 'bf': 'beef', 'grnd': 'ground', 'frsh': 'fresh',
    'frzn': 'frozen', 'lf': 'loaf', 'slcd': 'sliced', 'nfc': 'not from concentrate',
    'fc': 'from concentrate', 'rte': 'ready to eat', 'bn': 'bean',
    'veg': 'vegetable', 'tom': 'tomato', 'broc': 'broccoli', 'spnch': 'spinach'
};

function expandAbbreviations(name) {
    return name.split(' ').map(word => ABBREVIATIONS[word.toLowerCase()] || word).join(' ');
}

function extractUnitAndQuantity(line) {
    for (const pattern of UNIT_PATTERNS) {
        const match = line.match(pattern.regex);
        if (match) {
            return {
                quantity: parseFloat(match[1]) || 1,
                unit: pattern.unit
            };
        }
    }
    return { quantity: 1, unit: 'ea' };
}

function isSkipLine(line) {
    const lower = line.toLowerCase().trim();
    if (DATE_PATTERN.test(lower.replace(/\s/g, ''))) return true;
    if (STOREID_PATTERN.test(lower)) return true;
    return SKIP_KEYWORDS.some(kw => lower.includes(kw));
}

function parseReceiptText(rawText) {
    if (!rawText) return [];

    const lines = rawText.split('\n').map(l => l.trim()).filter(l => l.length > 0);
    const items = [];
    let pendingName = [];

    for (let i = 0; i < lines.length; i++) {
        const line = lines[i];

        if (isSkipLine(line)) {
            pendingName = [];
            continue;
        }

        // Detect price at end of line (e.g. "1.99", "$1.99", "- 1.99")
        const priceMatch = line.match(/(?:[-\$\s])([\d]+\.[\d]{2})$/);

        if (priceMatch) {
            const price = parseFloat(priceMatch[1]);
            if (price <= 0) { pendingName = []; continue; }

            // Strip the price from the line to get raw name portion
            let namePart = line.substring(0, line.lastIndexOf(priceMatch[0])).trim();

            // Combine with any multi-line pending name
            if (pendingName.length > 0) {
                namePart = pendingName.join(' ') + ' ' + namePart;
                pendingName = [];
            }

            // Extract unit and quantity from name
            const { quantity, unit } = extractUnitAndQuantity(namePart);

            // Clean name: remove unit patterns, special chars, expand abbreviations
            let cleanedName = namePart
                .replace(/(\d+\.?\d*)\s*(lbs?|oz|kg|g|ea|ct|pk|ml|l)\b/gi, '')
                .replace(/(\d+)\s*x\s*\d+/gi, '')
                .replace(/[^a-z0-9\s]/gi, '')
                .replace(/\s+/g, ' ')
                .trim()
                .toLowerCase();

            cleanedName = expandAbbreviations(cleanedName);

            if (cleanedName.length > 2) {
                items.push({ name: cleanedName, price, quantity, unit });
            }

        } else {
            // Could be a partial item name spread across lines (skip pure-number lines)
            if (!/^[\d\s\.\$]+$/.test(line) && !isSkipLine(line)) {
                pendingName.push(line.toLowerCase().trim());
            }
        }
    }

    return items;
}

module.exports = { parseReceiptText };
