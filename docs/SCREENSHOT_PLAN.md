# Screenshot Plan

Status: NEEDS_INPUT

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

## Required Device Families

| Device family | Required sizes | Source screen | Caption/copy | Source type | Asset status | Open work |
| --- | --- | --- | --- | --- | --- | --- |
| iPhone | 6.9" display, 1320 x 2868 portrait | Calculator with bill and tip total | Calculate tips in seconds | Simulator | Captured | `screenshots/generated/iphone-6.9-01-calculator.png` |
| iPhone | App Store Connect size set for current iPhone requirements | Receipt scanner with detected total | Scan receipts and spot included gratuity | Simulator or device | Needs asset | NEEDS_CONFIRMATION |
| iPhone | App Store Connect size set for current iPhone requirements | Saved history summary | Track local dining totals | Simulator or device | Needs asset | NEEDS_CONFIRMATION |
| iPhone | App Store Connect size set for current iPhone requirements | Custom presets/settings | Make tip presets your own | Simulator or device | Partial | Capture final setting screen |
| iPad | 13" display, 2064 x 2752 portrait | Calculator or dashboard layout | Scan Tip on iPad | Simulator | Captured | `screenshots/generated/ipad-13-01-calculator.png` |
| iPad | App Store Connect size set for current iPad requirements | History or settings | Review saved tips locally | Simulator or device | Partial | Confirm final copy |

## Required User Journeys

- Onboarding or first launch: show the three-page onboarding flow if it will be part of the submitted experience.
- Primary app value: bill amount, preset/custom tip, computed tip, and total.
- Receipt scanning: camera scanner with detected merchant/total and included service-charge warning.
- Saved history: monthly totals, saved visits, search, and local summaries.
- Settings: theme, appearance, onboarding replay, and custom tip presets.
- Ads: final screenshots should reflect whether the ad banner appears in submitted builds.

## Screenshot Copy Drafts

- Calculate tips in seconds
- Scan receipts for totals
- Catch included gratuity
- Save local dining history
- Customize your tip presets

## Open Questions

- Final iPhone and iPad screenshot device sizes are confirmed from Apple App Store Connect screenshot specifications: iPhone 6.9" and iPad 13".
- Confirm final screenshot ordering and captions.
- Confirm whether marketing copy overlays should be used or whether raw simulator screenshots are preferred.
