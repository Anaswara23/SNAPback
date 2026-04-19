const { parseReceiptText } = require('./receipt_parser');

describe('parseReceiptText', () => {
    test('Format 1: Clean basic receipt', () => {
        const text = `
            Organic Bananas  $1.99
            Whole Milk 2.50
            Subtotal 4.49
            Tax 0.25
            Total 4.74
        `;
        const items = parseReceiptText(text);
        expect(items.length).toBe(2);
        expect(items[0]).toEqual({ name: 'organic bananas', price: 1.99, quantity: 1, unit: 'ea' });
        expect(items[1]).toEqual({ name: 'whole milk', price: 2.5, quantity: 1, unit: 'ea' });
    });

    test('Format 2: Abbreviations and split names', () => {
        const text = `
            Fresh
            Tomatoes ORG
            $3.99
            CHICKEN BREAST LB
            $5.50
            TOTAL $9.49
        `;
        const items = parseReceiptText(text);
        expect(items.length).toBe(2);
        expect(items[0].name.includes('organic')).toBe(true);
        expect(items[0].price).toBe(3.99);
        expect(items[1].name.includes('chicken breast')).toBe(true);
        expect(items[1].unit).toBe('ea');
        expect(items[1].price).toBe(5.5);
    });

    test('Format 3: Messy data with rewards', () => {
        const text = `
            APPLES 2.00
            PlaNtAiNs 3.00
            REWARDS PTS 100
            CASHIER: JOHN
            TOTAL DUE 5.00
        `;
        const items = parseReceiptText(text);
        expect(items.length).toBe(2);
        expect(items[0].name.includes('apples')).toBe(true);
        expect(items[1].name.includes('plantains')).toBe(true);
    });

    test('Format 4: Items with numbers in name or no dollar sign', () => {
        const text = `
            12PK EGGS 4.99
            TOFU 2.50
            Subtotal 7.49
        `;
        const items = parseReceiptText(text);
        expect(items.length).toBe(2);
        expect(items[0].name).toBe('eggs');
        expect(items[0].quantity).toBe(12);
        expect(items[1].name).toBe('tofu');
    });

    test('Format 5: Cultural items mixed with junk', () => {
        const text = `
            STORE #1234
            Yuca Root $1.50
            Ackee Can 4.00
            VISA BALANCE 5.50
        `;
        const items = parseReceiptText(text);
        expect(items.length).toBe(2);
        expect(items[0].name).toBe('yuca root');
        expect(items[1].name).toBe('ackee can');
    });
});
