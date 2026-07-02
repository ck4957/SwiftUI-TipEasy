# TestFlight Notes

Status: NEEDS_INPUT

## Beta App Description

Scan Tip is a SwiftUI tip calculator for restaurant bills. Testers can enter a bill amount, choose preset or custom tip values, scan receipts with the camera, save tip history locally, manage custom tip presets, and validate the Scan Tip Pro purchase and restore experience.

## Test Focus Areas

- Launch the app and complete or skip onboarding.
- Enter a bill amount and verify preset tip calculations.
- Switch between custom percentage and custom dollar tip input.
- Save a transaction and confirm it appears in History.
- Confirm free History shows only the latest saved tips and presents the Pro upgrade prompt.
- In a Pro-unlocked state, confirm unlimited history, monthly charts, tip distribution, summaries, search, history export/share, and iCloud sync messaging work as expected.
- Search History by restaurant name, amount, date phrase, or tip comparison.
- Open Scan Tip Pro from Settings, History, history export, and custom preset gates.
- Test StoreKit purchase, cancel, pending/error messaging, successful unlock, app relaunch entitlement persistence, and restore purchase.
- Add, edit, hide, restore, and delete built-in/custom tip presets in the preset manager.
- Use Settings > Privacy & Data > Delete Local Data and confirm saved history/custom presets are removed.
- Grant and deny When In Use location permission, save tips, and confirm optional local place details behave correctly.
- Change theme and appearance settings.
- Open the receipt scanner on a supported device and verify detected receipt totals.
- Verify service charge or included gratuity warnings when receipt text supports it.
- Test App Shortcuts for calculating, saving, and opening Scan Tip destinations.
- Confirm the ad banner does not block calculator, history, or settings flows.

## Known Issues

- Receipt scanning requires a supported device/camera text recognition environment and may not work in every simulator configuration.
- Apple Intelligence receipt refinement only runs on iOS 26+ when `SystemLanguageModel.default.isAvailable`.
- StoreKit sandbox product setup and Pro price text need confirmation before external testing.
- iPhone README screenshots appear low resolution for App Store use and should be recaptured if needed.

## Tester Groups

- Internal testers: NEEDS_CONFIRMATION
- External testers: NEEDS_CONFIRMATION

## External Tester Notes

Please focus on normal restaurant tipping flows: calculating a bill, scanning a receipt, saving the visit, and reviewing saved history. Report any incorrect totals, confusing included-gratuity warnings, scanner failures, layout issues on iPhone/iPad, or ad banner overlap.

## Build Notes

- Bundle ID: com.chiragkular.SwiftUI-TipEasy
- Version: 1.2
- Build: 8
- Minimum OS: iOS 26.0
