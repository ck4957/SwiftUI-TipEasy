import SwiftData
import SwiftUI

enum TipInputMode {
    case percentage
    case dollar
}

extension CGFloat {
    static let cornerRadiusSmall: CGFloat = 8
    static let cornerRadiusMedium: CGFloat = 12
    static let cornerRadiusLarge: CGFloat = 20
    static let minimumTouchTarget: CGFloat = 44
    static let spacingSmall: CGFloat = 8
    static let spacingMedium: CGFloat = 12
    static let spacingLarge: CGFloat = 20
}

struct TipCalculatorView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appPalette) private var palette
    @Environment(PurchaseManager.self) private var purchaseManager
    @AppStorage("pendingOpenScanner") private var pendingOpenScanner = false
    @Query(sort: \TipPreset.percentage) private var tipPresets: [TipPreset]
    @Query(sort: \TipTransaction.date, order: .reverse) private var transactions: [TipTransaction]

    @State private var restaurantName: String = ""
    @State private var billAmount: String = ""
    @State private var customTipValue: String = ""
    @State private var tipInputMode: TipInputMode = .percentage
    @State private var selectedTipPercentage: Double = 0.18
    @State private var showingScanner = false
    @State private var showingSavedConfirmation = false
    @State private var receiptScanResult: ReceiptScanResult?
    @State private var proUpgradeRequest: ProUpgradeRequest?
    @FocusState private var focusedInput: CalculatorInput?

    private let defaultPresets: [Double] = [0.15, 0.18, 0.20, 0.25]
    private let currencyCode = Locale.current.currency?.identifier ?? "USD"

    private var bill: Double {
        parseAmount(billAmount)
    }

    private var computedTipPercentage: Double {
        guard bill > 0, let customValue = Double(customTipValue), !customTipValue.isEmpty else {
            return selectedTipPercentage
        }

        switch tipInputMode {
        case .percentage:
            return customValue / 100
        case .dollar:
            return customValue / bill
        }
    }

    private var computedTipAmount: Double {
        switch tipInputMode {
        case .percentage:
            return bill * computedTipPercentage
        case .dollar:
            if let customValue = Double(customTipValue), !customTipValue.isEmpty {
                return customValue
            }
            return bill * selectedTipPercentage
        }
    }

    private var totalAmount: Double {
        bill + computedTipAmount
    }

    private var presetPercentageValues: [Double] {
        tipPresets.isEmpty ? defaultPresets : tipPresets.map(\.percentage)
    }

    private var tipExplanation: TipInsight? {
        TipIntelligenceService.explanation(
            bill: bill,
            tipPercentage: computedTipPercentage,
            tipAmount: computedTipAmount,
            scanResult: receiptScanResult
        )
    }

    private var anomalyInsights: [TipInsight] {
        TipIntelligenceService.anomalies(
            bill: bill,
            tipPercentage: computedTipPercentage,
            restaurantName: restaurantName,
            scanResult: receiptScanResult,
            transactions: transactions
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .spacingLarge) {
                heroCalculatorCard
                tipControlCard
                if shouldShowSmartCheck {
                    intelligenceCard
                }
                actionsCard
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, .spacingLarge)
        }
        .scrollDismissesKeyboard(.interactively)
        .background(backgroundGradient)
        .navigationTitle("Scan Tip")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    openScanner(source: "toolbar")
                } label: {
                    Image(systemName: "camera.viewfinder")
                        .symbolRenderingMode(.hierarchical)
                }
                .glassEffect(.regular.interactive())
                .accessibilityLabel("Scan receipt")
            }
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") {
                    dismissKeyboard()
                }
                .fontWeight(.semibold)
            }
        }
        .tint(palette.accent)
        .sheet(isPresented: $showingScanner) {
            ReceiptScannerSheet { result in
                if let total = result.total {
                    billAmount = total.formatted(.number.precision(.fractionLength(2)))
                }

                if !result.merchantName.isEmpty {
                    restaurantName = result.merchantName
                }

                receiptScanResult = result
                AnalyticsService.track(
                    .receiptScanCompleted,
                    properties: [
                        "has_total": String(result.total != nil),
                        "has_merchant": String(!result.merchantName.isEmpty),
                        "used_apple_intelligence": String(result.usedAppleIntelligence)
                    ]
                )
                showingScanner = false
            }
        }
        .sheet(item: $proUpgradeRequest) { request in
            ProUpgradeView(source: request.source)
        }
        .sensoryFeedback(.success, trigger: showingSavedConfirmation)
        .alert("Saved to History", isPresented: $showingSavedConfirmation) {
            Button("Done", role: .cancel) {}
        } message: {
            Text("This tip calculation is now stored locally on this device.")
        }
        .onAppear {
            if pendingOpenScanner {
                pendingOpenScanner = false
                openScanner(source: "app_intent")
            }
        }
    }

    private var shouldShowSmartCheck: Bool {
        tipExplanation != nil || !anomalyInsights.isEmpty || receiptScanResult?.usedAppleIntelligence == true
    }

    private var customTipLabel: String {
        switch tipInputMode {
        case .percentage:
            "Custom %"
        case .dollar:
            "Custom $"
        }
    }

    private var heroCalculatorCard: some View {
        VStack(alignment: .leading, spacing: .spacingLarge) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Bill")
                        .font(.headline)
                    Text("Enter the check amount.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    openScanner(source: "hero")
                } label: {
                    Label(purchaseManager.isProUnlocked ? "Scan" : "Pro Scan", systemImage: "camera.viewfinder")
                        .labelStyle(.titleAndIcon)
                }
                .buttonStyle(.glass)
                .controlSize(.small)
            }

            HStack(spacing: .spacingMedium) {
                Text(Locale.current.currencySymbol ?? "$")
                    .font(.system(.largeTitle, design: .rounded).weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 36)

                TextField("0.00", text: $billAmount)
                    .keyboardType(.decimalPad)
                    .font(.system(size: 52, weight: .bold, design: .rounded))
                    .textFieldStyle(.plain)
                    .submitLabel(.done)
                    .focused($focusedInput, equals: .billAmount)
                    .minimumScaleFactor(0.55)
                    .accessibilityLabel("Bill amount")
            }
            .padding(.vertical, 4)

            TextField("Place name (optional)", text: $restaurantName)
                .textInputAutocapitalization(.words)
                .submitLabel(.done)
                .focused($focusedInput, equals: .restaurantName)
                .onSubmit {
                    dismissKeyboard()
                }
                .textFieldStyle(CompactGlassTextFieldStyle(palette: palette))

            if receiptScanResult != nil {
                Label("Receipt scanned", systemImage: "checkmark.seal.fill")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(palette.secondaryAccent)
            }

            Divider()

            HStack(alignment: .firstTextBaseline, spacing: .spacingLarge) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Tip")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(computedTipAmount, format: .currency(code: currencyCode))
                        .font(.title3.weight(.semibold))
                        .fontDesign(.rounded)
                        .contentTransition(.numericText())
                        .lineLimit(1)
                        .minimumScaleFactor(0.75)
                }

                Spacer(minLength: .spacingMedium)

                VStack(alignment: .trailing, spacing: 6) {
                    Text("Total")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(totalAmount, format: .currency(code: currencyCode))
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                        .contentTransition(.numericText())
                        .lineLimit(1)
                        .minimumScaleFactor(0.62)
                }
            }
        }
        .glassCard(palette: palette, tint: palette.card)
        .animation(.snappy, value: totalAmount)
    }

    private var tipControlCard: some View {
        VStack(alignment: .leading, spacing: .spacingMedium) {
            HStack(alignment: .firstTextBaseline) {
                Text("Tip")
                    .font(.headline)
                Spacer()
                Text("\(Int((computedTipPercentage * 100).rounded()))%")
                    .font(.headline.monospacedDigit())
                    .foregroundStyle(palette.accent)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 10)], spacing: 10) {
                ForEach(presetPercentageValues, id: \.self) { percentage in
                    Button {
                        selectPreset(percentage)
                    } label: {
                        TipPercentChip(
                            percentage: percentage,
                            isSelected: customTipValue.isEmpty && abs(percentage - selectedTipPercentage) < 0.001
                        )
                    }
                    .buttonStyle(.plain)
                }

                Button {
                    withAnimation(.snappy) {
                        tipInputMode = .percentage
                        customTipValue = Int((computedTipPercentage * 100).rounded()).formatted()
                    }
                } label: {
                    TipCustomChip(isSelected: !customTipValue.isEmpty)
                }
                .buttonStyle(.plain)
            }

            if !customTipValue.isEmpty {
                VStack(alignment: .leading, spacing: .spacingMedium) {
                    Picker("Custom tip type", selection: $tipInputMode) {
                        Label("Percent", systemImage: "percent").tag(TipInputMode.percentage)
                        Label("Amount", systemImage: "dollarsign").tag(TipInputMode.dollar)
                    }
                    .pickerStyle(.segmented)

                    HStack(spacing: .spacingMedium) {
                        TextField(customTipLabel, text: $customTipValue)
                            .keyboardType(.decimalPad)
                            .submitLabel(.done)
                            .focused($focusedInput, equals: .customTip)
                            .textFieldStyle(CompactGlassTextFieldStyle(palette: palette))
                            .onChange(of: customTipValue) { _, newValue in
                                if !newValue.isEmpty {
                                    synchronizeCustomTip()
                                }
                            }

                        Button {
                            selectPreset(selectedTipPercentage)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                                .foregroundStyle(.secondary)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel("Clear custom tip")
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .glassCard(palette: palette)
    }

    private var intelligenceCard: some View {
        VStack(alignment: .leading, spacing: .spacingMedium) {
            Label("Smart Check", systemImage: "checkmark.shield")
                .font(.headline)

            if let tipExplanation {
                InsightRow(insight: tipExplanation)
            }

            ForEach(anomalyInsights) { insight in
                InsightRow(insight: insight)
            }

            if let receiptScanResult, receiptScanResult.usedAppleIntelligence {
                Label("Receipt details refined on device.", systemImage: "apple.intelligence")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .glassCard(palette: palette, tint: anomalyInsights.isEmpty ? palette.card : palette.highlight.opacity(0.24))
    }

    private var actionsCard: some View {
        HStack(spacing: .spacingMedium) {
            Button {
                AnalyticsService.track(.calculatorCleared)
                resetCalculator()
            } label: {
                Label("Clear", systemImage: "xmark.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)

            Button {
                saveTransaction()
            } label: {
                Label(freeHistoryLimitReached ? "Unlock Save" : "Save", systemImage: "tray.and.arrow.down")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .disabled(bill <= 0)
        }
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                palette.backgroundTop,
                palette.backgroundMid,
                palette.backgroundBottom
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private func selectPreset(_ percentage: Double) {
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.impactOccurred()

        AnalyticsService.track(
            .presetSelected,
            properties: ["tip_percent": String(Int((percentage * 100).rounded()))]
        )

        withAnimation(.snappy) {
            selectedTipPercentage = percentage
            customTipValue = ""
            tipInputMode = .percentage
        }
    }

    private func synchronizeCustomTip() {
        guard bill > 0 else { return }
        switch tipInputMode {
        case .percentage:
            selectedTipPercentage = (Double(customTipValue) ?? 0) / 100
        case .dollar:
            selectedTipPercentage = (Double(customTipValue) ?? 0) / bill
        }
    }

    private func saveTransaction() {
        guard bill > 0 else { return }
        guard purchaseManager.isProUnlocked || !freeHistoryLimitReached else {
            showProUpgrade(source: "save_limit")
            return
        }

        let receiptPhotoFilename = receiptScanResult?.receiptPhotoData.flatMap { try? ReceiptPhotoStore.save($0) }
        let transaction = TipTransaction(
            restaurantName: restaurantName.trimmingCharacters(in: .whitespacesAndNewlines),
            billAmount: bill,
            tipPercentage: computedTipPercentage,
            tipAmount: computedTipAmount,
            totalAmount: totalAmount,
            receiptPhotoFilename: receiptPhotoFilename
        )
        modelContext.insert(transaction)
        AnalyticsService.track(
            .transactionSaved,
            properties: [
                "bill_bucket": AnalyticsService.billBucket(for: bill),
                "tip_bucket": AnalyticsService.percentBucket(for: computedTipPercentage),
                "tip_percent": String(Int((computedTipPercentage * 100).rounded())),
                "used_receipt_scan": String(receiptScanResult != nil),
                "has_restaurant_name": String(!restaurantName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            ]
        )
        dismissKeyboard()
        resetCalculator()
        showingSavedConfirmation = true
    }

    private func resetCalculator() {
        withAnimation(.snappy) {
            restaurantName = ""
            billAmount = ""
            customTipValue = ""
            tipInputMode = .percentage
            selectedTipPercentage = presetPercentageValues.first ?? 0.18
            receiptScanResult = nil
        }
    }

    private func parseAmount(_ text: String) -> Double {
        let allowed = CharacterSet(charactersIn: "0123456789.")
        let filtered = String(text.unicodeScalars.filter { allowed.contains($0) })
        return Double(filtered) ?? 0
    }

    private var freeHistoryLimitReached: Bool {
        !purchaseManager.isProUnlocked && transactions.count >= ProFeatureCopy.freeHistoryLimit
    }

    private func openScanner(source: String) {
        guard purchaseManager.isProUnlocked else {
            showProUpgrade(source: "receipt_scan_\(source)")
            return
        }

        AnalyticsService.track(.receiptScanStarted, properties: ["source": source])
        showingScanner = true
    }

    private func showProUpgrade(source: String) {
        AnalyticsService.track(.proGateTapped, properties: ["source": source])
        proUpgradeRequest = ProUpgradeRequest(source: source)
    }

    private func dismissKeyboard() {
        focusedInput = nil
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }

    private enum CalculatorInput: Hashable {
        case restaurantName
        case billAmount
        case customTip
    }
}

private struct ProUpgradeRequest: Identifiable {
    let source: String
    var id: String { source }
}

private struct InsightRow: View {
    @Environment(\.appPalette) private var palette
    let insight: TipInsight

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: insight.kind == .warning ? "exclamationmark.triangle.fill" : "info.circle.fill")
                .foregroundStyle(insight.kind == .warning ? palette.highlight : palette.secondaryAccent)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 4) {
                Text(insight.title)
                    .font(.subheadline.weight(.semibold))
                Text(insight.message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct TipPercentChip: View {
    @Environment(\.appPalette) private var palette

    let percentage: Double
    let isSelected: Bool

    var body: some View {
        Text("\(Int((percentage * 100).rounded()))%")
            .font(.headline.weight(.semibold))
            .fontDesign(.rounded)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .foregroundStyle(isSelected ? palette.accentDeep : .primary)
            .background(isSelected ? palette.selectedTile : palette.tile, in: RoundedRectangle(cornerRadius: .cornerRadiusMedium))
            .overlay {
                RoundedRectangle(cornerRadius: .cornerRadiusMedium)
                    .strokeBorder(isSelected ? palette.accent.opacity(0.55) : palette.stroke, lineWidth: 1)
            }
            .glassEffect(.regular.tint(isSelected ? palette.accent.opacity(0.14) : palette.glassTint).interactive(), in: .rect(cornerRadius: .cornerRadiusMedium))
            .accessibilityLabel("\(Int((percentage * 100).rounded())) percent tip")
    }
}

private struct TipCustomChip: View {
    @Environment(\.appPalette) private var palette

    let isSelected: Bool

    var body: some View {
        Label("Custom", systemImage: "slider.horizontal.3")
            .font(.headline.weight(.semibold))
            .labelStyle(.titleAndIcon)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .foregroundStyle(isSelected ? palette.accentDeep : .primary)
            .background(isSelected ? palette.selectedTile : palette.tile, in: RoundedRectangle(cornerRadius: .cornerRadiusMedium))
            .overlay {
                RoundedRectangle(cornerRadius: .cornerRadiusMedium)
                    .strokeBorder(isSelected ? palette.accent.opacity(0.55) : palette.stroke, lineWidth: 1)
            }
            .glassEffect(.regular.tint(isSelected ? palette.accent.opacity(0.14) : palette.glassTint).interactive(), in: .rect(cornerRadius: .cornerRadiusMedium))
    }
}

struct GlassTextFieldStyle: TextFieldStyle {
    let palette: ThemePalette

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding()
            .frame(minHeight: .minimumTouchTarget)
            .background(palette.field, in: RoundedRectangle(cornerRadius: .cornerRadiusMedium))
            .overlay {
                RoundedRectangle(cornerRadius: .cornerRadiusMedium)
                    .strokeBorder(palette.stroke, lineWidth: 1)
            }
    }
}

private struct CompactGlassTextFieldStyle: TextFieldStyle {
    let palette: ThemePalette

    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 14)
            .frame(minHeight: .minimumTouchTarget)
            .background(palette.field, in: RoundedRectangle(cornerRadius: .cornerRadiusMedium))
            .overlay {
                RoundedRectangle(cornerRadius: .cornerRadiusMedium)
                    .strokeBorder(palette.stroke, lineWidth: 1)
            }
    }
}

private extension View {
    func glassCard(palette: ThemePalette, tint: Color? = nil) -> some View {
        self
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(tint ?? palette.card, in: RoundedRectangle(cornerRadius: .cornerRadiusLarge))
            .glassEffect(.regular.tint(palette.glassTint), in: .rect(cornerRadius: .cornerRadiusLarge))
    }
}

#Preview {
    NavigationStack {
        TipCalculatorView()
    }
    .modelContainer(for: [TipPreset.self, TipTransaction.self], inMemory: true)
    .environment(PurchaseManager())
}
