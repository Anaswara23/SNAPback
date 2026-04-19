# SNAPback — 2-Minute Pitch & Demo Script

Total time: **120 seconds**
Format: **30–45s pitch (problem + solution, with wow opener) → 75–90s live demo → Q&A**

Speak conversationally. Slow down on the numbers. Smile.

---

## 0:00 — 0:08 · Wow opener (8s)

> "**Forty-two million Americans use SNAP to buy groceries every month — and the cheapest, easiest thing on the shelf is almost always the worst thing for them.** We're here to flip that incentive."

*(Pause for one beat. Hold up the phone.)*

---

## 0:08 — 0:25 · The problem (17s)

> "Families on SNAP and WIC get a debit card and zero guidance. Generic 'eat more vegetables' advice doesn't work for a Caribbean grandmother shopping for callaloo, or a South Asian family buying dal on a $480 monthly budget. The FAO problem statement we picked spells it out — diet-related disease is exploding in low-income, culturally diverse communities, and ultra-processed food is winning because no one's nudging the other way."

---

## 0:25 — 0:45 · The solution (20s)

> "**SNAPback is a Flutter app that turns every grocery receipt into personalized, culturally-aware nutrition guidance — and pays families real cashback when they actually shop healthier.**
>
> We use **Google Gemini 2.5 Flash** to read the receipt multimodally — every item, every price — and then score each item zero to five against the **USDA's healthy-foods criteria**, which the FAO problem statement actually pointed us to. Healthy items earn cashback. Cultural matches earn a bonus. **But here's the part nobody else does** — the cashback only unlocks if your *monthly* health average stays above 4 out of 5. We don't pay you for one healthy haul; we pay you for sustained behavior change."

---

## 0:45 — 2:00 · Live demo (75s)

Have the app open on Home, signed in, with at least one prior trip in History. Have a paper grocery receipt ready.

### 0:45 — 0:55 · Dashboard (10s)
> "This is what a household sees. **Dashboard, Health Score this month — 4.2 out of 5.** They've earned $6.40 of $25 monthly cashback so far, with 18 days left in the cycle. Everything you see is live — no manual refresh."

### 0:55 — 1:15 · Scan a real receipt (20s)
> "Watch this. Bottom nav, **Scan**, snap a photo of this Whole Foods receipt." *(Take photo, confirm.)* "While our classy loader spins, behind the scenes the photo lands in Firebase Storage, a Cloud Function fires Gemini with a strict JSON schema, and we're scoring every line item against USDA criteria."

### 1:15 — 1:40 · Trip Result (25s)
> "Three seconds later — boom. **Trip Health Score: 78. Cashback earned this trip: $1.42.** Item by item — plantains 5 stars, brown rice 4 stars, chips 1 star and zero cashback because we **explicitly excluded** ultra-processed and non-edible items in the prompt."
>
> *(Scroll down.)*
>
> "And because we know they're Caribbean, Gemini suggests **two recipes they can cook tonight from the items they just bought** — green plantain mash and a chickpea curry, both above 4-star nutrition. *That's* equitable, personalized nutrition."

### 1:40 — 1:55 · Redemption gate (15s)
> "And the gate — see this badge? **Cashback is REDEEMABLE because their monthly Health Score is 4.2, above our 4.0 floor.** If they slip, the badge turns amber and the deposit waits. That's the policy lever — not punishment, just the right kind of pressure to make the healthy choice the default one."

### 1:55 — 2:00 · Close (5s)
> "**SNAPback — turn every receipt into real cashback for real behavior change.** Happy to take questions."

---

## Anticipated Q&A — short answers ready

**Q: How is the score calculated?**
We don't calculate it client-side. Gemini 2.5 Flash returns a 0–5 health score per item using a system prompt grounded in the USDA healthy-foods criteria from the FAO resources. We then weight it by item count for the monthly average.

**Q: Why does the cashback gate exist? Isn't that punishing?**
The opposite. Most cashback apps reward *any* purchase. We only release cashback when the monthly average stays at 4/5 or higher. Behavioral economics — make the healthy choice the rewarded default, but make the reward feel earned over a *month*, not a single trip.

**Q: How would this scale to real EBT?**
Today it's a tracked virtual balance. The next step is a state-pilot integration that loads the unlocked cashback directly onto the EBT card on the 1st of the month. The architecture supports it — the monthly cap and redemption logic already runs server-side.

**Q: Where does the cultural bonus list come from?**
We seeded it with 24 cuisines covering the most common SNAP-recipient demographics in the US. It's open-source, so community PRs can extend or correct it.

**Q: What stops a user from gaming it (one healthy trip + ten junk trips)?**
The monthly *average* gate. Cashback accrues per-item, but you can't redeem any of it unless the household's whole month averages 4+. Gaming requires sustained healthy buying — which is exactly the outcome we want.

**Q: Why Flutter?**
SNAP recipients use a mix of cheap Android and older iOS devices. Flutter ships both from one codebase, with native performance and accessibility hooks. We get to spend our budget on the AI pipeline instead of two native teams.

**Q: What's open-source about it?**
Everything in this repo is MIT-licensed — Flutter app, Cloud Functions, Gemini prompts, USDA-aligned scoring rubric, and the cultural cuisine list. Public health programs can fork it tomorrow.

---

## Demo prep checklist

- [ ] Phone fully charged + screen mirrored
- [ ] Test account signed in, profile complete (Caribbean cuisine selected)
- [ ] At least 2 prior trips in History so dashboard isn't empty
- [ ] One real paper receipt in your pocket
- [ ] Light theme (better on projectors)
- [ ] Airplane mode OFF, wifi confirmed
- [ ] Backup: pre-recorded 30s demo video in case wifi dies
