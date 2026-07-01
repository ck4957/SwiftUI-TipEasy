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
8. If Pro is not unlocked, use the History or Settings Pro prompt to open the Scan Tip Pro screen.
9. Test purchase or restore using App Store sandbox review tools; Pro unlocks receipt scanning, unlimited history, Smart Check insights, custom tip presets, and history charts.
10. Open Settings to manage presets, replay onboarding, change appearance, restore purchases, or delete local app data.
11. Use Settings > Privacy & Data > Delete Local Data to remove saved tips, custom presets, hidden default presets, onboarding status, and pending shortcut state from the device.
12. On a supported device and Pro-unlocked state, tap the camera/scanner action to scan receipt text and apply a detected total.

## Login Instructions

No login is required. No reviewer account is needed.

## Permissions Explanation

- Camera: used to scan receipt text, detect receipt totals, and identify possible service charges or included gratuity. The app's permission string is: "Scan Tip uses the camera to read receipt totals and show tip suggestions."
- Location: used while the app is open to attach optional local place details to saved tip history when permission is granted. The app's permission string is: "Scan Tip uses your location while the app is open to save where a receipt or tip was captured."
- Local storage: SwiftData stores custom tip presets and saved tip transactions on device.
- StoreKit: Scan Tip Pro is a one-time purchase handled by the App Store. The app observes verified transactions and stores a local unlock flag.
- Local data deletion: Settings includes a Privacy & Data section where users can delete saved tip history, custom presets, hidden default presets, onboarding status, and pending shortcut state from the device.
- Ads: No ad SDK is included.

## Feature Flags Or Demo Data

- No feature flag system was found.
- Demo data is not required; reviewers can create a bill manually and save it locally.
- Receipt scanner behavior depends on camera text recognition availability.
- DEBUG builds include an "Unlock Preview Pro" control, but release builds should rely on StoreKit purchase/restore.

## AI And Deterministic Test Path

The receipt parser first uses deterministic local text parsing. On iOS 26+ devices where Apple's on-device `SystemLanguageModel` is available, the app may refine receipt fields with FoundationModels. A deterministic review path is available by manually entering a bill amount instead of using scanner/AI refinement.

## Unusual Entitlements Or Flows

- App Intents expose shortcuts for calculating tips, saving tips, and opening Scan Tip destinations.
- StoreKit product ID in code: `com.chiragkular.SwiftUI-TipEasy.pro`.

## Support Contact

NEEDS_CONFIRMATION

## Review Blockers

- Confirm support contact and support URL.
- Confirm privacy policy URL.
- Confirm final StoreKit product metadata, price, screenshot, and review status in App Store Connect.
- Confirm final App Privacy answers for purchases, optional local location storage, and local receipt photos.
