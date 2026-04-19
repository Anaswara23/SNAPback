function parseReceiptText(rawText) {
    if (!rawText) return [];

    const lines = rawText.split('\n').map(l => l.trim()).filter(l => l.length > 0);
    const items = [];

    // Non-food line keywords to explicitly skip
    const skipKeywords = ['subtotal', 'tax', 'total', 'cashier', 'rewards', 'points', 'store', 'date', 'visa', 'mastercard', 'cash', 'change', 'balance', 'credit', 'debit', 'amount'];

    // Handle multi-word items across lines by simple tracking (or just grouping on prices)
    let currentItemName = [];

    for (let i = 0; i < lines.length; i++) {
        const line = lines[i].toLowerCase();

        if (skipKeywords.some(kw => line.includes(kw))) {
            continue;
        }

        // Usually prices end the line, e.g., "1.99" or "$1.99"
        const priceMatch = line.match(/(?:[\$])?([\d]+\.[\d]{2})$/);

        if (priceMatch) {
            const priceStr = priceMatch[0];
            const matchIndex = line.lastIndexOf(priceStr);
            let nameStr = line.substring(0, matchIndex).trim();

            // If name is blank on this line, it might have been on the previous line
            if (!nameStr && currentItemName.length > 0) {
                nameStr = currentItemName.join(' ');
                currentItemName = [];
            } else if (nameStr && currentItemName.length > 0) {
                nameStr = currentItemName.join(' ') + ' ' + nameStr;
                currentItemName = [];
            }

            const price = parseFloat(priceMatch[1]);

            if (nameStr.length > 2 && price > 0) {
                // Handle common abbreviations
                let cleanedName = nameStr
                    .replace(/\borg\b/g, 'organic')
                    .replace(/\blb\b/g, 'per pound')
                    .replace(/\bea\b/g, 'each')
                    .replace(/[^a-z0-9\s]/gi, '') // Remove weird chars
                    .trim();

                items.push({ name: cleanedName, price: price });
            }
        } else {
            // Line might be just part of an item name
            if (!line.match(/^[\d]+$/)) { // avoid just numbers
                currentItemName.push(line);
            }
        }
    }

    return items;
}

module.exports = { parseReceiptText };
