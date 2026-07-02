# Next Release Draft

Status: DRAFT
Branch reviewed: `feature/free-pro-pricing`
Branch base: `2e455333fe6df6c903c466cb43c69e9305c1ec13`
Last updated: July 1, 2026

Use this file as the living release log while the branch is in progress. When new user-facing work lands, update the change summary, App Store "What's New" draft, TestFlight focus areas, screenshot needs, privacy/review notes, and README checklist in the same PR or commit.

## Major Changes Since Branch Creation

### Scan Tip Pro And StoreKit

- Added `PurchaseManager` with StoreKit product loading, one-time Pro purchase, transaction update observation, entitlement refresh, restore purchases, and debug preview unlock/reset helpers.
- Added `ProUpgradeView`, a Scan Tip Pro paywall with feature copy, purchase and restore actions, error handling, and analytics events.
- Added Pro gates across paid features. Free users keep the calculator, receipt scanning, and the latest saved history items; Pro unlocks unlimited history, Smart Check insights, custom tip presets, richer history views, history export/share, and iCloud sync.
- Added purchase analytics events for paywall views, gated feature taps, purchase completion, purchase failure, and restore completion.

### Tip Presets

- Added `TipPresetCatalog` to merge built-in defaults with custom presets, deduplicate values, sort presets, and persist hidden built-in presets.
- Reworked Settings preset management into a dedicated manager sheet.
- Consolidated the Settings tip suggestions section so preset guidance, active preset preview, Pro messaging, and the Manage Presets action live in one card.
- Users can now hide built-in presets, add custom presets, edit custom presets, and restore a hidden default by adding the same percentage again.
- Preset deletion analytics now include whether the deleted preset was built-in or custom.

### History Enhancements

- Added Pro-aware history limits for free users and an upgrade prompt from History.
- Added Pro history charts and summaries, including monthly flow and tip distribution views.
- Added Pro history export/share as CSV from the History toolbar.
- Added a shared SwiftData `ScanTipModelContainer` configured for private CloudKit sync.
- Added richer history detail support for saved receipt images and optional saved place details.
- Added local location snapshot storage fields to `TipTransaction` for latitude, longitude, place name, locality, administrative area, and capture date.

### Location-Aware Saved Tips

- Added `LocationManager` for When In Use permission, location refresh, and reverse-geocoded local place snapshots.
- Added `NSLocationWhenInUseUsageDescription` explaining that location is used while the app is open to save where a receipt or tip was captured.
- Updated privacy documentation to describe permission-gated place details for saved tip history and private iCloud sync behavior.

### Receipt Scanner And Calculator

- Receipt scanner tip tiles now show both tip amount and final total for each suggested percentage.
- Scanner tip tiles have improved adaptive layout sizing and accessibility labels.
- Calculator save flows can attach the latest local location snapshot to saved transactions when permission has been granted.
- Receipt scanning is free in the current branch; Smart Check insights remain a Pro feature.

### Marketing And App Store Assets

- Added App Store-ready iPhone 6.9-inch and iPad 13-inch screenshot/video assets under `screenshots/app-store/`.
- Added overlay text creative assets for receipt scanning and history.
- Existing README and public docs now need refreshed screenshot coverage for Pro, preset management, history charts, receipt scanner totals, and location-aware history details.

## Draft App Store "What's New"

Scan Tip now includes a Pro unlock for unlimited saved history, Smart Check insights, custom tip presets, history charts, history export/share, and iCloud sync. Receipt scanning remains free, and this update improves scanner tip suggestions with final totals, adds richer preset management, and can save optional local place details with your tip history when location permission is granted.

NEEDS_CONFIRMATION before submission:

- Final marketing version and build number.
- Final Pro product availability, price, and App Store Connect product ID setup.
- Whether all listed Pro features are enabled in the submitted build.
- Whether location permission should be requested on first launch or later in the save/history flow.

## Documentation Update Checklist

- [x] Add this next-release living draft.
- [x] Update README feature summary and release notes.
- [x] Update App Store metadata draft with Pro and location-aware history.
- [x] Update privacy matrix for StoreKit purchases and local location fields.
- [x] Update TestFlight focus areas for Pro purchase/restore, gated features, preset management, and history charts.
- [x] Update App Review notes for Pro purchase flow and location permission.
- [x] Update screenshot plan with new Pro and UI-update capture requirements.
- [ ] Replace README screenshots after fresh simulator/device captures.
- [ ] Replace public `docs/screenshots/` marketing screenshots after fresh captures.
- [ ] Confirm App Store Connect pricing, in-app purchase metadata, review notes, and privacy answers.
- [ ] Run `./scripts/release-doctor.sh` before a release commit.

## Screenshot Refresh Plan

Capture new screenshots whenever the UI stabilizes. Prefer final simulator or device screenshots over mockups.

Required new or replacement screenshots:

- Calculator with the current Pro/free treatment visible only if relevant to the submitted build.
- Pro upgrade screen showing one-time unlock, feature list, purchase button, and restore button.
- Receipt scanner suggestions showing tip amount and final total.
- History free state with the Pro unlock prompt.
- History Pro state with monthly chart, tip distribution, and saved receipt/photo detail.
- Preset management sheet with built-in and custom presets.
- Location-aware saved history detail or map/place preview, if this remains in the release.
- Settings Pro card and privacy/data controls.

Target App Store folders:

- `screenshots/app-store/iphone-6.9/`: 1320 x 2868 portrait PNG/JPG assets.
- `screenshots/app-store/ipad-13/`: 2064 x 2752 portrait PNG/JPG assets.

README/public site folders:

- `screenshots/`: repository screenshots shown by README.
- `docs/screenshots/`: GitHub Pages marketing screenshots.

## Release Preparation Guidelines

When adding more features to this branch:

1. Update `docs/NEXT_RELEASE.md` in the same change that adds user-facing behavior.
2. If data collection, permissions, StoreKit, networking, analytics, or persistence changes, update `docs/APP_PRIVACY_MATRIX.md`, `docs/privacy.html`, and `docs/REVIEW_NOTES.md`.
3. If App Store copy changes, update `docs/APP_STORE_METADATA.md` and keep the README release notes aligned.
4. If the UI changes, update `docs/SCREENSHOT_PLAN.md` with the screen, device class, required size, and asset status.
5. If tester behavior changes, update `docs/TESTFLIGHT_NOTES.md`.
6. Before release commits or upload attempts, run `./scripts/release-doctor.sh`.
7. For another upload with the same marketing version, run `./scripts/bump-build-number.sh` before archiving.

## Open Release Questions

- NEEDS_CONFIRMATION: final version/build for this release.
- NEEDS_CONFIRMATION: final Pro product title, price, product ID, and App Store Connect in-app purchase review metadata.
- NEEDS_CONFIRMATION: whether Pro is a one-time non-consumable purchase in App Store Connect.
- NEEDS_CONFIRMATION: final free-tier limits and Apple Developer/App Store CloudKit container setup.
- NEEDS_CONFIRMATION: final screenshot order and whether overlay text assets or raw screenshots should be submitted.
- NEEDS_CONFIRMATION: final App Privacy answers for purchases and optional local location storage.
- NEEDS_CONFIRMATION: support contact and release mode.
