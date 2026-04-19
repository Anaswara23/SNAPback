# Contributing to SNAPback

Thanks for your interest! SNAPback exists to help SNAP and WIC families eat better, and we welcome contributions from public-health practitioners, designers, dietitians, and engineers.

## Ways to contribute

- **File an issue** for bugs, UX papercuts, or accuracy gaps in the health rubric.
- **Open a PR** for fixes, accessibility improvements, new cultural cuisines, or recipe quality tweaks.
- **Share feedback** from real SNAP/WIC users — qualitative reports are as valuable as code.

## Dev setup

1. Fork and clone the repo.
2. Follow the **Getting started** section in [`README.md`](README.md).
3. Run `flutter analyze` and `flutter test` before opening a PR.

## Pull request guidelines

- Keep PRs focused — one feature or fix per PR.
- For UI changes, attach before/after screenshots in the PR description.
- For changes to the scoring or cashback logic in `functions/index.js`, include a short rationale and (where possible) a USDA / WHO / CDC source.
- Run `flutter analyze` (clean) and `cd functions && npm run lint` before pushing.

## Code style

- **Flutter / Dart:** follow the lints in `analysis_options.yaml`. Provider for state, MVVM separation (no Firebase imports in `views/`).
- **Cloud Functions:** Node 20, ES modules, `async/await`. Keep Gemini prompts in `functions/index.js` documented inline.

## Reporting security issues

Please email the team privately rather than opening a public issue. We'll respond within 72 hours.

## Code of conduct

Be respectful and assume good faith. We're building this for vulnerable populations — empathy first, code second.
