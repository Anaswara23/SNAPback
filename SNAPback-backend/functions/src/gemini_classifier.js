const { GoogleGenerativeAI } = require('@google/generative-ai');
const fs = require('fs');
const path = require('path');

const genAI = new GoogleGenerativeAI(process.env.GEMINI_API_KEY || "YOUR_GEMINI_KEY");

// Load cultural foods cache
const culturalFoods = JSON.parse(fs.readFileSync(path.join(__dirname, 'cultural_foods.json'), 'utf8'));

async function classifyItems(items, culturalPrefs) {
  const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash" });

  const prompt = `
    You are a nutrition classifier for a SNAP food rewards app called SNAPback.
    Cultural preferences of this user: ${culturalPrefs.join(", ")}.

    For EACH item, return a JSON array with exactly:
    - name: cleaned item name (string)
    - category: one of [fresh_produce, whole_grain, lean_protein, dairy,
      legume, healthy_fat, canned_veg, frozen_veg, refined_grain,
      processed_snack, sugary_drink, candy, other]
    - healthScore: integer 0 to 5 ONLY
    - isCultural: boolean

    RULES:
    - Plantains, yuca, taro, bitter melon -> fresh_produce, score 5
    - Sofrito, miso, garam masala -> healthy_fat, score 3
    - Score on nutrient density, NOT western food assumptions
    - Return ONLY valid JSON array, zero explanation, no markdown

    Items: ${JSON.stringify(items)}
  `;

  let retries = 1;
  while (retries >= 0) {
    try {
      const result = await model.generateContent(prompt);
      const text = result.response.text();
      let cleaned = text.trim();
      if(cleaned.startsWith('```json')) cleaned = cleaned.replace(/```json/g,'').replace(/```/g,'');
      if(cleaned.startsWith('```')) cleaned = cleaned.replace(/```/g,'');
      
      const parsed = JSON.parse(cleaned);
      return parsed;
    } catch (e) {
      if (retries === 0) {
        // Fallback to cache and defaults
        return items.map(item => {
          const cached = culturalFoods.find(c => c.name.toLowerCase() === item.name.toLowerCase());
          if (cached) {
            return {
              name: item.name,
              category: cached.category,
              healthScore: cached.healthScore,
              isCultural: cached.isCultural
            };
          }
          // Default fallback
          return {
            name: item.name,
            category: "other",
            healthScore: 2,
            isCultural: false
          };
        });
      }
      retries--;
    }
  }
}

module.exports = { classifyItems };
