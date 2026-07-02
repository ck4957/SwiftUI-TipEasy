# Screenshot Plan

Status: AUTOMATED_DRAFT

## Automated Capture Workflow

Run the App Store screenshot suite whenever the UI changes or before preparing a release:

```bash
./scripts/generate-screenshots.sh
```

The script runs `Scan TipUITests/AppStoreScreenshotUITests` on the configured iPhone 6.9-inch and iPad 13-inch simulators, launches the app with deterministic screenshot fixtures, keeps named `XCTAttachment` screenshots in the `.xcresult` bundle, exports them with `xcresulttool`, and writes stable PNG filenames into:

- `screenshots/app-store/iphone-6.9/`
- `screenshots/app-store/ipad-13/`

The UI test suite does not depend on AI or manual screen navigation. It uses Xcode UI automation, launch arguments, an in-memory SwiftData store, seeded sample history, English locale/language arguments, and a debug-only Pro unlock. The default destinations are pinned to iOS 26.5 on this machine because the iOS 27.0 iPad simulator currently hangs during raw `xcodebuild` result finalization. Override `IPHONE_DESTINATION` or `IPAD_DESTINATION` when a local Xcode install uses a different simulator name or runtime.

By default, the script replaces `.png`, `.jpg`, and `.jpeg` files in those display folders while preserving app preview videos and other non-image assets. For a dry run, set `SCREENSHOT_ROOT=build/screenshot-dry-run`.

## App Preview Video Conversion

Use the local ffmpeg wrapper when App Store Connect asks for an app preview at `886 x 1920` portrait or `1920 x 886` landscape:

```bash
./scripts/convert-app-preview-video.sh <input-video> <output-video> portrait
./scripts/convert-app-preview-video.sh <input-video> <output-video> landscape
```

Example:

```bash
./scripts/convert-app-preview-video.sh \
  screenshots/CreativeAssets/ScanTipAppStorePromo.mp4 \
  screenshots/app-store/iphone-6.9/ScanTipProductVideo-app-preview-iphone-6.9.mp4 \
  portrait
```

The script scales/crops to the exact requested canvas, outputs H.264/AAC `.mp4`, moves the file metadata to the front for upload/playback, and prints the resulting width, height, frame rate, and duration.

## Existing Screenshot Inventory

| Asset | Device family | Size | Source | Status |
| --- | --- | --- | --- | --- |
| `screenshots/IMG-1.jpeg` | iPhone | 300 x 649 | Existing README screenshot | May be too small for App Store upload |
| `screenshots/IMG-2.jpeg` | iPhone | 300 x 649 | Existing README screenshot | May be too small for App Store upload |
| `screenshots/IPAD_IMG_1.png` | iPad | 2064 x 2752 | Existing screenshot | Candidate App Store asset |
| `screenshots/IPAD_IMG_2.png` | iPad | 2064 x 2752 | Existing screenshot | Candidate App Store asset |
| `screenshots/IPAD_IMG_3.png` | iPad | 2064 x 2752 | Existing screenshot | Candidate App Store asset |
| `screenshots/generated/iphone-01-calculator-empty.png` | iPhone | 1206 x 2622 | Previous generated simulator screenshot | Not an accepted 6.9" App Store size |
| `screenshots/generated/ipad-01-calculator-empty.png` | iPad | 2064 x 2752 | Generated simulator screenshot | Candidate App Store asset |
| `screenshots/generated/iphone-6.9-01-calculator.png` | iPhone | 1320 x 2868 | Regenerated iPhone 17 Pro Max simulator screenshot | App Store-ready 6.9" asset |
| `screenshots/generated/ipad-13-01-calculator.png` | iPad | 2064 x 2752 | Regenerated iPad Pro 13-inch simulator screenshot | App Store-ready 13" asset |
| `screenshots/app-store/iphone-6.9/*.png` and `*.jpg` | iPhone | 1320 x 2868 | App Store screenshot set | Existing set; needs refresh for Pro and UI changes |
| `screenshots/app-store/ipad-13/*.png` and `*.jpg` | iPad | 2064 x 2752 | App Store screenshot set | Existing set; needs refresh for Pro and UI changes |

## Required Device Families

| Device family | Required sizes | Source screen | Caption/copy | Source type | Asset status | Open work |
| --- | --- | --- | --- | --- | --- | --- |
| iPhone | 6.9" display, 1320 x 2868 portrait | Calculator with bill and tip total | Calculate tips in seconds | Simulator | Captured | `screenshots/generated/iphone-6.9-01-calculator.png` |
| iPhone | App Store Connect size set for current iPhone requirements | Receipt scanner with detected total | Scan receipts and spot included gratuity | Simulator or device | Needs asset | NEEDS_CONFIRMATION |
| iPhone | App Store Connect size set for current iPhone requirements | Saved history summary | Track local dining totals | Simulator or device | Needs asset | NEEDS_CONFIRMATION |
| iPhone | App Store Connect size set for current iPhone requirements | Custom presets/settings | Make tip presets your own | Simulator or device | Partial | Capture final setting screen |
| iPhone | 6.9" display, 1320 x 2868 portrait | Scan Tip Pro upgrade | Unlock Pro tools once | Simulator or device | Needs asset | Capture after StoreKit sandbox copy/price is available |
| iPhone | 6.9" display, 1320 x 2868 portrait | Preset management sheet | Customize built-in and custom presets | Simulator or device | Needs asset | Capture Pro-unlocked state |
| iPhone | 6.9" display, 1320 x 2868 portrait | History charts and summaries | See dining totals over time | Simulator or device | Needs asset | Capture Pro-unlocked state with sample history |
| iPhone | 6.9" display, 1320 x 2868 portrait | Location-aware history detail | Remember where tips were saved | Simulator or device | Needs asset | Capture only if location feature remains in release |
| iPad | 13" display, 2064 x 2752 portrait | Calculator or dashboard layout | Scan Tip on iPad | Simulator | Captured | `screenshots/generated/ipad-13-01-calculator.png` |
| iPad | App Store Connect size set for current iPad requirements | History or settings | Review saved tips locally | Simulator or device | Partial | Confirm final copy |
| iPad | 13" display, 2064 x 2752 portrait | Scan Tip Pro upgrade or history charts | Unlock deeper tip history | Simulator or device | Needs asset | Capture final iPad layout |

## Required User Journeys

- Automated UI test coverage: onboarding pages, calculator empty state, filled calculator total, seeded history, and settings.
- Onboarding or first launch: show the three-page onboarding flow if it will be part of the submitted experience.
- Primary app value: bill amount, preset/custom tip, computed tip, and total.
- Receipt scanning: camera scanner with detected merchant/total and included service-charge warning.
- Saved history: monthly totals, saved visits, search, and local summaries.
- Settings: theme, appearance, onboarding replay, and custom tip presets.
- Pro upgrade: one-time unlock, feature list, purchase button, restore button, and completed entitlement state if useful.
- Location-aware history: saved place details and map/place preview if included in final release.
- Ads: final screenshots should reflect whether the ad banner appears in submitted builds.

## Screenshot Copy Drafts

- Calculate tips in seconds
- Scan receipts for totals
- Catch included gratuity
- Save local dining history
- Customize your tip presets
- Unlock Scan Tip Pro
- See history trends

## Open Questions

- Final iPhone and iPad screenshot device sizes are confirmed from Apple App Store Connect screenshot specifications: iPhone 6.9" and iPad 13".
- Confirm final screenshot ordering and captions.
- Confirm whether marketing copy overlays should be used or whether raw simulator screenshots are preferred.
- Recapture README and GitHub Pages screenshots after the Pro/history/preset UI settles.
