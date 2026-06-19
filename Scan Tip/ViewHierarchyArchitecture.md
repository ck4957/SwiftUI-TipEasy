# View Hierarchy Architecture

## App Shell

The root app type is `ScanTipApp` in `SwiftUI_ScanTipApp.swift`.

Launch responsibilities:

- Initializes Google Mobile Ads through `AppDelegate`.
- Creates the main `WindowGroup`.
- Presents `ContentView`.
- Attaches a SwiftData model container for `TipPreset` and `TipTransaction`.

## Root View

`ContentView` owns the app-level UI structure.

Primary responsibilities:

- Displays a `TabView` with calculator, history, and settings tabs.
- Wraps each tab in its own `NavigationStack`.
- Stores selected tab state.
- Reads and applies theme and appearance preferences from `AppStorage`.
- Presents onboarding as a full-screen cover until completed.
- Routes App Intent destinations by reading `pendingScanTipDestination` from `UserDefaults`.
- Sets `pendingOpenScanner` when the scanner shortcut is requested.

Tab structure:

```text
ScanTipApp
└── ContentView
    ├── Calculator tab
    │   └── NavigationStack
    │       └── TipCalculatorView
    ├── History tab
    │   └── NavigationStack
    │       └── TipHistoryView
    └── Settings tab
        └── NavigationStack
            └── TipPresetSettingsView
```

`ContentView` also defines `AdBannerView`, a `UIViewRepresentable` wrapper around Google Mobile Ads `BannerView`.

## Onboarding Flow

`OnboardingView` is presented from `ContentView` using `fullScreenCover` while `hasCompletedOnboarding` is false.

Structure:

```text
OnboardingView
├── Header
│   ├── Scan Tip title
│   └── Skip button
├── Page TabView
│   └── OnboardingPageView
└── Primary action button
```

Pages:

- Calculate - explains bill entry, tip options, and final total.
- Scan - explains receipt total scanning and scanner suggestions.
- Save - explains restaurant names, monthly history, and local totals.

The final action or Skip sets `hasCompletedOnboarding` to true through a binding owned by `ContentView`.

## Calculator Tab

`TipCalculatorView` is the main product workflow. It uses a vertical `ScrollView` with card-like sections.

High-level structure:

```text
TipCalculatorView
├── headerView
├── billCard
├── suggestionsCard
├── intelligenceCard
├── customTipCard
├── totalCard
└── actionsCard
```

State and data sources:

- `@Query` reads `TipPreset` for quick tip buttons.
- `@Query` reads `TipTransaction` for duplicate and historical anomaly checks.
- Local `@State` stores restaurant name, bill amount, custom tip value, tip input mode, selected tip percentage, scanner presentation, save confirmation, and current receipt scan result.
- `@FocusState` manages keyboard focus.

Key sections:

- `billCard` contains restaurant and bill amount inputs.
- `suggestionsCard` renders preset percentage tiles using `TipSuggestionTile`.
- `intelligenceCard` renders `InsightRow` entries from `TipIntelligenceService`.
- `customTipCard` lets the user enter either a custom percentage or a custom dollar tip.
- `totalCard` displays computed tip and total using `AmountColumn`.
- `actionsCard` clears the calculator or saves a `TipTransaction`.

Toolbar and sheets:

- The navigation toolbar has a camera button that presents `ReceiptScannerSheet`.
- The keyboard toolbar has a Done button to dismiss focus.
- Saving triggers success feedback and a confirmation alert.
- A bottom safe-area inset hosts the AdMob banner.

Calculator save flow:

```text
User taps Save
└── saveTransaction()
    ├── validates bill > 0
    ├── creates TipTransaction
    ├── inserts into modelContext
    ├── dismisses keyboard
    ├── resets calculator state
    └── presents Saved to History alert
```

## Receipt Scanner Sheet

`ReceiptScannerSheet` is presented modally from `TipCalculatorView`.

Structure:

```text
ReceiptScannerSheet
└── NavigationStack
    └── ZStack
        ├── ReceiptDataScannerView or unavailable-state view
        └── scannerOverlay
```

Scanning flow:

1. `ReceiptDataScannerView` wraps VisionKit `DataScannerViewController`.
2. The scanner delegate collects recognized text transcripts from visible items.
3. `recognizedText` changes trigger `analyzeRecognizedText()`.
4. `ReceiptIntelligenceService` parses the text into `ReceiptScanResult`.
5. The overlay shows detected total, merchant name, tip previews, and scanner status.
6. Tapping Use calls `onDetectedResult(scanResult)`.
7. `TipCalculatorView` receives the result, fills the bill and restaurant fields, stores the result, and dismisses the sheet.

The scanner gracefully falls back to `ContentUnavailableView` if VisionKit scanning is unsupported or unavailable.

## History Tab

`TipHistoryView` displays saved transactions from SwiftData.

Structure:

```text
TipHistoryView
├── summaryCards
├── MonthlySummaryCard, when available
├── ContentUnavailableView, when no visible transactions exist
└── historyList
    └── month group
        └── TipHistoryRow
```

State and data sources:

- `@Query` reads `TipTransaction` sorted newest first.
- `searchText` drives filtering through `HistorySearchService`.
- Derived totals compute spent, tips, and year-to-date tips from visible transactions.
- Transactions are grouped by year and month for display.

User actions:

- Search filters saved transactions by text, relative date, tip comparison, or amount query.
- Each row has a context menu delete action that removes the transaction from SwiftData.

## Settings Tab

`TipPresetSettingsView` manages appearance, onboarding replay, and tip presets.

Structure:

```text
TipPresetSettingsView
├── appearanceCard
├── themeCard
├── guideCard
├── introCard
└── presetCard
    ├── defaultPresetPreview, when no custom presets exist
    └── presetRow, for each saved preset
```

State and data sources:

- `@Query` reads `TipPreset` sorted by percentage.
- `@AppStorage` stores selected theme, appearance mode, and onboarding completion.
- Local state controls add/edit sheet presentation and the preset being edited.

Preset editing flow:

```text
User taps plus or pencil
└── AddEditPresetSheet
    ├── validates percentage input from 1 to 100
    ├── updates existing TipPreset or inserts a new one
    └── dismisses
```

Preset rows also include a delete button that removes the preset from SwiftData.

## Theme and Palette Flow

`AppPalette.swift` defines the visual theme system.

Important types:

- `AppAppearance` - system, light, or dark mode.
- `AppTheme` - Harvest, Garden, or Berry.
- `ThemePalette` - semantic color slots consumed by views.
- `appTheme` environment value - injected by `ContentView`.
- `appPalette` environment value - derived from the current theme.

`ContentView` applies:

- `.environment(\.appTheme, selectedTheme)`
- `.preferredColorScheme(appAppearance.colorScheme)`
- `.tint(selectedTheme.palette.accent)`

Child views then use `@Environment(\.appPalette)` for consistent colors.

## App Intent Routing

`OpenScanTipIntent` writes the requested destination to `UserDefaults` and opens the app.

Routing flow:

```text
OpenScanTipIntent
├── writes pendingScanTipDestination
├── writes pendingOpenScanner when destination is scanner
└── opens app

ContentView
└── routePendingDestination()
    ├── switches selected tab
    └── clears pendingScanTipDestination

TipCalculatorView
└── onAppear
    └── opens scanner if pendingOpenScanner is true
```

This keeps shortcut-triggered navigation outside the persisted domain models while still allowing App Intents to open specific areas of the app.
