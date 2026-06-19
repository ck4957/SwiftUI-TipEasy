# App Review Notes

Status: NEEDS_INPUT

## Reviewer Walkthrough

1. Launch Scan Tip.
2. Complete or skip onboarding.
3. On the Calculator tab, enter a restaurant name and bill amount.
4. Select a preset tip or enter a custom percentage/dollar tip.
5. Review the computed tip amount and total.
6. Tap Save to store the transaction locally.
7. Open the History tab to view saved transactions and summary totals.
8. Open Settings to edit tip presets, replay onboarding, change appearance, or delete local app data.
9. Use Settings > Privacy & Data > Delete Local Data to remove saved tips and custom presets from the device.
10. On a supported device, tap the camera/scanner action to scan receipt text and apply a detected total.

## Login Instructions

No login is required. No reviewer account is needed.

## Permissions Explanation

- Camera: used to scan receipt text, detect receipt totals, and identify possible service charges or included gratuity. The app's permission string is: "Scan Tip uses the camera to read receipt totals and show tip suggestions."
- Local storage: SwiftData stores custom tip presets and saved tip transactions on device.
- Local data deletion: Settings includes a Privacy & Data section where users can delete saved tip history, custom presets, onboarding status, and pending shortcut state from the device.
- Ads: Google Mobile Ads SDK is included. Final App Store privacy and tracking answers require confirmation.

## Feature Flags Or Demo Data

- No feature flag system was found.
- Demo data is not required; reviewers can create a bill manually and save it locally.
- Receipt scanner behavior depends on camera text recognition availability.

## AI And Deterministic Test Path

The receipt parser first uses deterministic local text parsing. On iOS 26+ devices where Apple's on-device `SystemLanguageModel` is available, the app may refine receipt fields with FoundationModels. A deterministic review path is available by manually entering a bill amount instead of using scanner/AI refinement.

## Unusual Entitlements Or Flows

- App Intents expose shortcuts for calculating tips, saving tips, and opening Scan Tip destinations.
- Google Mobile Ads is initialized at launch and an ad banner is shown in the app shell.
- SKAdNetwork identifiers are configured in `Info.plist`.

## Support Contact

NEEDS_CONFIRMATION

## Review Blockers

- Confirm support contact and support URL.
- Confirm privacy policy URL.
- Confirm final ad privacy/tracking/consent answers.
