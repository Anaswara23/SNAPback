# SNAPback

> **Healthy choices, real cashback.** SNAPback turns every grocery receipt into personalized, culturally-aware nutrition guidance — and rewards SNAP / WIC families with real cashback when they sustain healthier shopping habits.

Built for **George Hacks × United Nations — Reboot the Earth Hackathon 2026**
**Track:** FAO — *AI for equitable and personalized nutrition in diverse U.S. communities*

---

## The problem

The U.S. is living through a dual crisis of malnutrition. Diet-related diseases — obesity, diabetes, heart disease — disproportionately hit low-income and marginalized households, while ultra-processed food is the cheapest, most available option on the shelf. In ethnically diverse cities like New York, families on **SNAP** and **WIC** rarely get nutrition guidance that respects their budget *and* their culture. Generic "eat more vegetables" advice doesn't help a Caribbean grandmother shopping for callaloo, or a South Asian family buying atta and dal on a $480/month budget.

## Our solution

**SNAPback is a Flutter mobile app** that closes the loop between *what families actually buy* and *how their government benefits could reward better choices*.

1. Snap a photo of any grocery receipt.
2. **Gemini 2.5 Flash** reads it multimodally — every line item, quantity, and price.
3. Each edible item is scored 0–5 against a **USDA-derived healthy-foods rubric** (per the resources provided in the FAO problem statement) and tagged for cultural relevance to the user's declared cuisines.
4. The app awards **per-item cashback** (5% for 5★ items, 3% for 4★, 1% for 3★, +1pp cultural bonus) — but the cashback is only **redeemable** when the household's monthly average health score stays at or above **4 / 5**.
5. We also generate **nutritious recipe suggestions** from what they just bought, in their preferred cuisines.

The redemption gate is the heart of the design: families are nudged toward sustained healthy patterns, not one-off "healthy hauls."

## Why this matters / why it's different

- **Personalized to budget *and* culture** — our cultural bonus rewards Caribbean, South Asian, West African, Latin American, East Asian, and 19 other cuisines, not a one-size-fits-all "Mediterranean" recommendation.
- **Behavior-gated cashback** — most cashback apps reward any purchase. We only release cashback when the *monthly* health average crosses 4/5. That's the policy lever that turns nutrition science into action.
- **Closed loop with Gemini multimodal** — no separate OCR step. One model reads the receipt, classifies items, scores them against USDA criteria, and powers the recipe suggestions.
- **Designed for the people who actually use SNAP** — large fonts, bouncing scroll, light/dark themes, household-level case ID, and a redemption summary that makes "what I'd actually get" plain.

## How it works (data flow)

```
Receipt photo
   ↓ (Flutter — image_picker + crop)
Firebase Storage  →  Cloud Function: processReceipt
                       ↓ (Gemini 2.5 Flash, structured JSON, USDA rubric)
                     Firestore: items + per-item health score
                       ↓ trigger
                     Cloud Function: scoreTrip
                       ↓ tiered cashback + monthly cap + redemption gate + recipes
                     Firestore: trip result + monthly stats
                       ↓ live stream
Flutter UI  ←  Dashboard / History / Trip Result auto-update in real time
```

## Tech stack

| Layer | Choice |
|---|---|
| Mobile | Flutter (Dart) — iOS + Android |
| State | Provider (MVVM) |
| Navigation | `go_router` + `IndexedStack` for persistent tabs |
| Auth | Firebase Auth (email / password) |
| Database | Cloud Firestore (real-time streams) |
| Storage | Firebase Storage |
| Server logic | Firebase Cloud Functions (Node 20, 2nd gen) |
| AI | Gemini 2.5 Flash via `@google/genai` (structured JSON output) |
| Charts | `fl_chart` |
| Health rubric | USDA-derived healthy-foods criteria (per FAO problem statement resources) |

## Repository layout

```
lib/
  core/        constants, router, theme, utils
  models/      UserProfile, TripResult, TripItem, RecipeSuggestion, UserStats
  services/    Firebase wrappers (auth, profile, trips, receipt, preferences)
  viewmodels/  one per screen — pure Provider, no Firebase imports in UI
  views/
    screens/   onboarding, home, scan, trip_result, history, profile
    shared/    widgets (ScoreRing, GlassCard, SnapbackLoader, ItemHealthBar, …)
    shells/    main_shell with persistent bottom nav
functions/
  index.js     processReceipt + scoreTrip (Gemini integration, scoring, recipes)
firestore.rules
storage.rules
```

## Getting started

### Prerequisites

- Flutter SDK 3.22+
- Node.js 20 (for Cloud Functions)
- Firebase CLI (`npm i -g firebase-tools`)
- A Firebase project with Auth (Email/Password), Firestore, Storage, and Functions enabled
- A `GEMINI_API_KEY` from Google AI Studio

### Setup

```bash
git clone https://github.com/<your-org>/SNAPback.git
cd SNAPback

# 1. Configure Firebase for your account
flutterfire configure

# 2. Set the Gemini secret
firebase functions:secrets:set GEMINI_API_KEY

# 3. Deploy backend
firebase deploy --only firestore:rules,storage,functions

# 4. Run the app
flutter pub get
flutter run
```

### Try it

1. Sign up with email + password.
2. Complete onboarding (3 steps: name + language → SNAP amount + family size → cultural preferences).
3. Tap **Scan** → snap a grocery receipt.
4. Within a few seconds the Trip Result screen shows item-by-item scoring, cashback earned, redemption status, and recipe suggestions.

## Reward model (the part judges ask about)

Per item:
- 5★ item → **5%** cashback on its line total
- 4★ → **3%**
- 3★ → **1%**
- ≤2★ → 0%
- Cultural-match item → **+1pp** bonus

Monthly cap: `min(10% × monthly SNAP amount, $25 × family size)`

**Redemption gate:** the accumulated cashback for the month is only released when the household's **item-weighted average health score ≥ 4 / 5** for that calendar month. Below the gate, cashback keeps accruing but stays locked — the UI shows exactly how far away the family is from unlocking.

## Accessibility

- Screen-reader labels on the score ring, redemption badge, scan button, and trip rows
- Light + dark themes that meet WCAG AA contrast on primary surfaces
- Bouncing scroll physics + persistent bottom nav for predictable navigation
- Large, bold typography on key numerics
- Tap targets ≥ 44 pt across primary actions

## Roadmap

- Real localization (Spanish + Mandarin ARB files) — language picker is currently English-only
- FCM push: "Cashback unlocked" on the 1st of each month + monthly progress nudges
- WIC-specific item recognition (formula, eligible categories)
- Direct EBT credit integration via state pilots
- Open API for community-vetted cultural food databases

## Team

Prithvi Saran · Roshini · Anaswara · Hidhayath

## License

[MIT](LICENSE) — built for open collaboration with public health programs.

## Acknowledgements

- **USDA** — healthy-foods criteria used to score items (per FAO problem statement resources)
- **Google Gemini** — multimodal receipt understanding
- **Firebase** — auth, storage, Firestore, functions, hosting
- **George Hacks × UN Reboot the Earth 2026** — for the prompt and the platform
