# App Privacy Matrix

Status: NEEDS_INPUT

Privacy answers must be reviewed before App Store submission. This file records repo evidence and uncertainty; it is not a final legal disclosure.

| Data type | Collected | Linked to user | Used for tracking | Purpose | Evidence | Status |
| --- | --- | --- | --- | --- | --- | --- |
| Contact Info | No evidence found | No evidence found | No evidence found | Not used by current app code | No login, account, email, or contact fields found | NEEDS_CONFIRMATION |
| Identifiers | No evidence found | No evidence found | No evidence found | Not used by current app code | No ad SDK, login, analytics SDK, or tracking identifier usage found | NEEDS_CONFIRMATION |
| Usage Data | Local app events only in DEBUG current code | No evidence found | No evidence found | App analytics debugging only | `AnalyticsService` prints events only in DEBUG and has no production provider connected | NEEDS_CONFIRMATION |
| Diagnostics | No evidence found | No evidence found | No evidence found | Not used by current app code | No crash reporting or diagnostics SDK found | NEEDS_CONFIRMATION |
| Financial Info | Local only when user saves tip transactions | No account link found | No evidence found | App functionality: saved bill, tip, and total history | `TipTransaction` stores billAmount, tipAmount, totalAmount in SwiftData | NEEDS_CONFIRMATION |
| Location | No current collection found | No evidence found | No evidence found | Not used in current release code | No CoreLocation/MapKit usage found; feature request mentions future location/map work | NEEDS_CONFIRMATION |
| Photos or Videos | No current collection found | No evidence found | No evidence found | Not used in current release code | No Photos framework or photo picker usage found; future request mentions photo | NEEDS_CONFIRMATION |
| Camera | Used for live receipt text scanning | No evidence of remote linking | No evidence found | App functionality: read receipt totals and service charges | `NSCameraUsageDescription`, `ReceiptScannerSheet`, VisionKit scanner flow | NEEDS_CONFIRMATION |
| User Content | Receipt text is transient unless user saves a transaction | No account link found | No evidence found | App functionality: receipt parsing and tip suggestions | `ReceiptScanResult.rawText` is transient; saved records store restaurant/bill/tip totals | NEEDS_CONFIRMATION |

## SDK-Driven Collection Notes

- No ad, analytics, crash-reporting, attribution, or consent SDK is present in the current project.
- `Info.plist` does not contain `GADApplicationIdentifier` or `SKAdNetworkItems`.

## Local Storage Notes

- SwiftData stores `TipPreset` and `TipTransaction` locally.
- User preferences are stored with `AppStorage` / `UserDefaults`, including onboarding completion, selected theme, appearance, and pending shortcut routing.
- Receipt OCR text and parsed receipt scan results are described as transient unless the user saves a transaction.
- Users can delete local saved tips, custom presets, onboarding status, and pending shortcut state from Settings > Privacy & Data > Delete Local Data.

## Unresolved Privacy Questions

- Confirm whether any production analytics provider will be connected before release.
- Confirm final disclosure treatment for saved bill totals, restaurant names, and receipt-derived fields.
- Confirm whether a privacy policy URL exists and covers local storage, camera scanning, and Apple Intelligence on-device processing.
