# App Privacy Matrix

Status: NEEDS_INPUT

Privacy answers must be reviewed before App Store submission. This file records repo evidence and uncertainty; it is not a final legal disclosure.

| Data type | Collected | Linked to user | Used for tracking | Purpose | Evidence | Status |
| --- | --- | --- | --- | --- | --- | --- |
| Contact Info | No evidence found | No evidence found | No evidence found | Not used by current app code | No login, account, email, or contact fields found | NEEDS_CONFIRMATION |
| Identifiers | No evidence found | No evidence found | No evidence found | Not used by current app code | No ad SDK, login, analytics SDK, or tracking identifier usage found | NEEDS_CONFIRMATION |
| Usage Data | Local app events only in DEBUG current code | No evidence found | No evidence found | App analytics debugging only | `AnalyticsService` prints events only in DEBUG and has no production provider connected | NEEDS_CONFIRMATION |
| Diagnostics | No evidence found | No evidence found | No evidence found | Not used by current app code | No crash reporting or diagnostics SDK found | NEEDS_CONFIRMATION |
| Purchases | StoreKit purchase entitlement only | Apple ID handled by App Store, no app account link found | No evidence found | App functionality: unlock and restore Scan Tip Pro | `PurchaseManager` loads product `com.chiragkular.SwiftUI-TipEasy.pro`, observes transactions, and stores local unlock flag | NEEDS_CONFIRMATION |
| Financial Info | Local only when user saves tip transactions | No account link found | No evidence found | App functionality: saved bill, tip, and total history | `TipTransaction` stores billAmount, tipAmount, totalAmount in SwiftData | NEEDS_CONFIRMATION |
| Location | Local only when permission is granted and user saves a tip | No account link found | No evidence found | App functionality: saved tip place details and map preview | `LocationManager` requests When In Use permission; `TipTransaction` stores optional coordinates/place fields in SwiftData | NEEDS_CONFIRMATION |
| Photos or Videos | Local only when user saves a scanned receipt | No account link found | No evidence found | App functionality: saved receipt image preview in history | `ReceiptPhotoStore` saves captured receipt JPEG data to local application support storage | NEEDS_CONFIRMATION |
| Camera | Used for live receipt text scanning | No evidence of remote linking | No evidence found | App functionality: read receipt totals and service charges | `NSCameraUsageDescription`, `ReceiptScannerSheet`, VisionKit scanner flow | NEEDS_CONFIRMATION |
| User Content | Receipt text is transient unless user saves a transaction | No account link found | No evidence found | App functionality: receipt parsing and tip suggestions | `ReceiptScanResult.rawText` is transient; saved records store restaurant/bill/tip totals | NEEDS_CONFIRMATION |

## SDK-Driven Collection Notes

- No ad, analytics, crash-reporting, attribution, or consent SDK is present in the current project.
- `Info.plist` does not contain `GADApplicationIdentifier` or `SKAdNetworkItems`.

## Local Storage Notes

- SwiftData stores `TipPreset` and `TipTransaction` locally and can sync those records through the user's private iCloud container.
- User preferences are stored with `AppStorage` / `UserDefaults`, including onboarding completion, selected theme, appearance, and pending shortcut routing.
- Receipt OCR text and parsed receipt scan results are described as transient unless the user saves a transaction.
- If location permission is granted, saved transactions may include optional coordinates and reverse-geocoded place details stored with the saved SwiftData record.
- Users can delete local saved tips, custom presets, onboarding status, and pending shortcut state from Settings > Privacy & Data > Delete Local Data.

## Unresolved Privacy Questions

- Confirm whether any production analytics provider will be connected before release.
- Confirm App Store privacy treatment for StoreKit purchase history/entitlements.
- Confirm final disclosure treatment for saved bill totals, restaurant names, and receipt-derived fields.
- Confirm whether the privacy policy URL covers SwiftData/iCloud sync, camera scanning, Apple Intelligence on-device processing, saved receipt photos, and permission-gated location storage.
