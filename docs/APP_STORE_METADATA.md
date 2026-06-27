# App Store Metadata

Status: NEEDS_INPUT

## App Identity

- App name: Scan Tip
- Bundle ID: com.chiragkular.SwiftUI-TipEasy
- Version: 1.2
- Build: 8
- Platforms: iPhone, iPad
- Minimum OS: iOS 26.0
- Primary category: Food & Drink
- Secondary category: Utilities or Finance - NEEDS_CONFIRMATION

## Product Page Copy

- Subtitle: Tip calculator with receipt scanning
- Promotional text: Calculate tips, scan receipts, save dining history, and customize tip presets.
- Description:

Scan Tip helps you quickly calculate restaurant tips and totals. Enter a bill amount, choose a preset tip, adjust a custom percentage or dollar amount, and see the final total instantly.

The app can save local dining history, summarize recent totals, and detect possible duplicate visits. Receipt scanning uses the device camera to read receipt totals and warn when service charges or included gratuity may already be present. On supported iOS versions, Apple Intelligence can refine receipt details on device.

Scan Tip also supports customizable tip presets, appearance themes, onboarding replay, local data deletion, and App Shortcuts for common calculator actions.

- Keywords: tip calculator, restaurant, receipt scanner, gratuity, dining, bill splitter, tip, calculator, history
- What's new: Version 1.2 adds receipt scanning, saved tip history, on-device tip insights, App Shortcuts, iPad support, and onboarding updates. NEEDS_CONFIRMATION

## Business And Availability

- Business model: Free, no ads, no in-app purchases - NEEDS_CONFIRMATION
- Pricing: Free - NEEDS_CONFIRMATION
- Regions: NEEDS_CONFIRMATION
- Release mode: manual - NEEDS_CONFIRMATION
- Content rights: Uses original app UI and code; third-party SDK content rights need final confirmation.
- Age rating inputs:
  - User-generated content: No known social/user-published content.
  - Web access: No general web browsing found.
  - Ads: No ad SDK found.
  - Purchases: No in-app purchase code found.
  - Location: No active location permission found; future request mentions location/map features only.
  - Camera: Yes, camera is used for receipt scanning.
  - AI/ML: Uses Apple's FoundationModels/SystemLanguageModel on supported devices for receipt field refinement.
  - Final App Store age rating answers: NEEDS_CONFIRMATION

## Routing App Coverage

- Routing app: No. This app does not provide Maps directions or include `MKDirectionsApplicationSupportedModes`.
- Geographic coverage file: Not applicable. Do not upload a `.geojson` routing coverage file unless the app intentionally adds Maps routing support in a future release.

## URLs

- Privacy policy URL: https://ck4957.github.io/ScanTip/privacy.html
- Support URL: https://ck4957.github.io/ScanTip/support.html
- Marketing URL: https://ck4957.github.io/ScanTip/

## Review Support

- Reviewer demo credentials: Not required; no login flow found.
- Notes:
  - Camera access is used only to scan receipt text for bill totals and possible included service charges.
  - Saved tip presets and saved transactions are stored locally with SwiftData.
  - Users can delete local saved tips, custom presets, onboarding status, and pending shortcut state from Settings > Privacy & Data > Delete Local Data.
  - Production analytics provider is not connected in code; `AnalyticsService` prints in DEBUG and has a placeholder for release builds.
