# TestFlight Notes

Status: NEEDS_INPUT

## Beta App Description

Tip Easy is a SwiftUI tip calculator for restaurant bills. Testers can enter a bill amount, choose preset or custom tip values, scan receipts with the camera, save tip history locally, and manage custom tip presets.

## Test Focus Areas

- Launch the app and complete or skip onboarding.
- Enter a bill amount and verify preset tip calculations.
- Switch between custom percentage and custom dollar tip input.
- Save a transaction and confirm it appears in History.
- Search History by restaurant name, amount, date phrase, or tip comparison.
- Add, edit, and delete custom tip presets.
- Use Settings > Privacy & Data > Delete Local Data and confirm saved history/custom presets are removed.
- Change theme and appearance settings.
- Open the receipt scanner on a supported device and verify detected receipt totals.
- Verify service charge or included gratuity warnings when receipt text supports it.
- Test App Shortcuts for calculating, saving, and opening Tip Easy destinations.
- Confirm the ad banner does not block calculator, history, or settings flows.

## Known Issues

- Receipt scanning requires a supported device/camera text recognition environment and may not work in every simulator configuration.
- Apple Intelligence receipt refinement only runs on iOS 26+ when `SystemLanguageModel.default.isAvailable`.
- Final ad consent/privacy behavior needs confirmation before external testing.
- iPhone README screenshots appear low resolution for App Store use and should be recaptured if needed.

## Tester Groups

- Internal testers: NEEDS_CONFIRMATION
- External testers: NEEDS_CONFIRMATION

## External Tester Notes

Please focus on normal restaurant tipping flows: calculating a bill, scanning a receipt, saving the visit, and reviewing saved history. Report any incorrect totals, confusing included-gratuity warnings, scanner failures, layout issues on iPhone/iPad, or ad banner overlap.

## Build Notes

- Bundle ID: com.chiragkular.SwiftUI-TipEasy
- Version: 1.2
- Build: 2
- Minimum OS: iOS 26.0
