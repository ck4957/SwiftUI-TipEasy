# Data Model Architecture

## Overview

Tip Easy is a SwiftUI app backed by SwiftData for local persistence. The persistent domain is intentionally small: saved tip presets and saved tip transactions. Receipt scanning and calculator state are treated as transient view state unless a user explicitly saves a transaction.

The SwiftData container is configured in `SwiftUI_TipEasyApp.swift` for:

- `TipPreset`
- `TipTransaction`

Google Mobile Ads is initialized through the app delegate at launch, but ad state is not part of the app data model.

## Persistent Models

### TipPreset

`TipPreset` is a SwiftData `@Model` used to store user-configured quick tip percentages.

Fields:

- `id: UUID` - stable identity for SwiftUI lists.
- `percentage: Double` - stored as a fractional value, such as `0.18` for 18%.

Usage:

- Queried by `TipCalculatorView` to build the tip suggestion grid.
- Queried and edited by `TipPresetSettingsView`.
- If no presets exist, the app falls back to default values: 15%, 18%, 20%, and 25%.

### TipTransaction

`TipTransaction` is a SwiftData `@Model` representing a saved calculator result.

Fields:

- `id: UUID` - stable identity for SwiftUI lists.
- `date: Date` - defaults to `.now` when created.
- `restaurantName: String` - optional user-entered or scanner-detected place name.
- `billAmount: Double` - pre-tip bill amount used for the calculation.
- `tipPercentage: Double` - stored as a fraction, such as `0.20` for 20%.
- `tipAmount: Double` - calculated tip amount.
- `totalAmount: Double` - bill plus tip.

Usage:

- Inserted by `TipCalculatorView.saveTransaction()`.
- Inserted by `SaveTipIntent` when saving through App Intents.
- Queried by `TipHistoryView` for grouped history, totals, and search.
- Queried by `TipCalculatorView` for duplicate and higher-than-usual checks.

## Transient Models

### ReceiptScanResult

`ReceiptScanResult` is a value type used to move structured receipt details through the scanner and calculator flow.

Fields:

- `merchantName: String`
- `subtotal: Double?`
- `tax: Double?`
- `serviceCharge: Double?`
- `includedGratuity: Double?`
- `total: Double?`
- `rawText: String`
- `usedAppleIntelligence: Bool`

Important behavior:

- `empty` provides a default blank result for scanner state.
- `hasIncludedService` returns true when either a service charge or included gratuity is present.

Usage:

- Created by `ReceiptIntelligenceService` from OCR text.
- Returned from `ReceiptScannerSheet` to `TipCalculatorView`.
- Used by `TipIntelligenceService` to warn about included service charges or gratuity.

### TipCalculatorModel

`TipCalculatorModel` is an `ObservableObject` with published calculator fields and basic total calculations. The current main calculator screen mostly uses local `@State` instead, so this model appears to be legacy or reserved for future extraction.

Fields:

- `billAmount: String`
- `selectedTipPercentage: Double`
- `customTipPercentage: String`

Behavior:

- `totalAmount` parses the bill string and applies the selected percentage.
- `setTipPercentage(_:)` converts whole-number percentages to fractions.
- `calculateCustomTip()` applies a custom percentage to the current total.

## Services

### TipIntelligenceService

`TipIntelligenceService` derives display-ready insights from calculator and history data.

Main outputs:

- `TipInsight` - a small identifiable message model with `info` or `warning` kind.
- `HistorySummary` - a title, message, and highlight list for history summaries.

Responsibilities:

- Explain whether the selected tip is below common range, standard, or generous.
- Warn when a scanned receipt appears to include service or gratuity.
- Warn about possible duplicate saved bills from the same day.
- Warn when a tip is much higher than the user's saved average.
- Summarize history totals, average tip, weekend visits, and top place.

`HistorySearchService` is defined in the same file and filters saved transactions by:

- Restaurant text.
- Relative date phrases like `this month`, `last month`, `this year`, and `ytd`.
- Tip comparisons like `over 20%` or `under 15%`.
- Amount comparisons like `over $50` or `under total 25`.

### ReceiptIntelligenceService

`ReceiptIntelligenceService` converts OCR text into `ReceiptScanResult`.

Flow:

1. `ReceiptTextParser.analyze(_:)` performs local parsing first.
2. On iOS 26 and newer, if `SystemLanguageModel.default.isAvailable`, a `LanguageModelSession` asks FoundationModels to refine the receipt fields.
3. If model output parses as JSON, the service merges model results over the local fallback.
4. If model use fails or is unavailable, the local parse result is returned.

`ReceiptTextParser` extracts:

- Candidate merchant name from early non-amount lines.
- Labeled subtotal, tax, service charge, gratuity, and total values.
- Fallback total as the maximum detected amount when no labeled total is found.

## App Intent Data Access

`TipEasyIntents.swift` exposes shortcuts for calculator-related work:

- `CalculateTipIntent` calculates a tip and total without opening the app.
- `SaveTipIntent` creates its own SwiftData `ModelContainer`, inserts a `TipTransaction`, and saves it.
- `OpenTipEasyIntent` writes pending navigation state to `UserDefaults` so `ContentView` can route when the app opens.

Shared destination values are modeled by `TipEasyDestination`, with cases for calculator, scanner, history, and settings.

## Storage Boundaries

Persisted locally:

- Tip presets.
- Saved tip transactions.
- User preferences in `AppStorage`, including theme, appearance, onboarding completion, and pending scanner state.

Not persisted as domain records:

- Current calculator inputs.
- Scanner OCR text.
- Receipt scan result details unless the user saves a transaction.
- Intelligence messages, which are derived on demand.
