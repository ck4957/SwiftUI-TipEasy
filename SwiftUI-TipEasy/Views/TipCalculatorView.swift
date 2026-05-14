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
                headerView
                billCard
                suggestionsCard
                intelligenceCard
                customTipCard
                totalCard
                actionsCard
            }
            .padding(.horizontal)
            .padding(.top, 12)
            .padding(.bottom, 84)
        }
        .background(backgroundGradient)
        .navigationTitle("Tip Easy")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingScanner = true
                } label: {
                    Image(systemName: "camera.viewfinder")
                        .symbolRenderingMode(.hierarchical)
                }
                .glassEffect(.regular.interactive())
                .accessibilityLabel("Scan receipt")
            }
        }
        .tint(palette.accent)
        .safeAreaInset(edge: .bottom) {
            AdBannerView(adUnitID: "ca-app-pub-3911596373332918/3954995797")
                .frame(height: 50)
                .background(.bar)
        }
        .sheet(isPresented: $showingScanner) {
            ReceiptScannerSheet { result in
                if let total = result.total {
                    billAmount = total.formatted(.number.precision(.fractionLength(2)))
                }

                if !result.merchantName.isEmpty {
                    restaurantName = result.merchantName
                }

                receiptScanResult = result
                showingScanner = false
            }
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
                showingScanner = true
            }
        }
    }

    private var headerView: some View {
        VStack(alignment: .leading, spacing: .spacingSmall) {
            Text("Settle the bill without the clutter.")
                .font(.title2.weight(.semibold))
            Text("Enter the total, compare common tip options, then save the visit when it matters.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var billCard: some View {
        VStack(alignment: .leading, spacing: .spacingMedium) {
            Label("Bill", systemImage: "receipt")
                .font(.headline)

            TextField("Restaurant or place", text: $restaurantName)
                .textInputAutocapitalization(.words)
                .textFieldStyle(GlassTextFieldStyle(palette: palette))

            HStack(spacing: .spacingMedium) {
                Text(Locale.current.currencySymbol ?? "$")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(width: 28)

                TextField("0.00", text: $billAmount)
                    .keyboardType(.decimalPad)
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .textFieldStyle(.plain)
                    .submitLabel(.done)
                    .accessibilityLabel("Bill amount")
            }
            .padding()
            .frame(minHeight: 76)
            .background(palette.field, in: RoundedRectangle(cornerRadius: .cornerRadiusLarge))
        }
        .glassCard(palette: palette)
    }

    private var intelligenceCard: some View {
        VStack(alignment: .leading, spacing: .spacingMedium) {
            Label("Smart Check", systemImage: "brain")
                .font(.headline)

            if let tipExplanation {
                InsightRow(insight: tipExplanation)
            }

            ForEach(anomalyInsights) { insight in
                InsightRow(insight: insight)
            }

            if tipExplanation == nil, anomalyInsights.isEmpty {
                Text("Enter a bill or scan a receipt to see context, duplicate checks, and receipt warnings.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let receiptScanResult, receiptScanResult.usedAppleIntelligence {
                Label("Receipt details refined with Apple Intelligence on device.", systemImage: "apple.intelligence")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
        }
        .glassCard(palette: palette, tint: anomalyInsights.isEmpty ? palette.card : palette.highlight.opacity(0.24))
    }

    private var suggestionsCard: some View {
        VStack(alignment: .leading, spacing: .spacingMedium) {
            HStack {
                Label("Tip Suggestions", systemImage: "sparkles")
                    .font(.headline)
                Spacer()
                Text("\(Int(computedTipPercentage * 100))% selected")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 144), spacing: 10)], spacing: 10) {
                ForEach(presetPercentageValues, id: \.self) { percentage in
                    Button {
                        selectPreset(percentage)
                    } label: {
                        TipSuggestionTile(
                            percentage: percentage,
                            bill: bill,
                            currencyCode: currencyCode,
                            isSelected: abs(percentage - computedTipPercentage) < 0.001
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .glassCard(palette: palette)
    }

    private var customTipCard: some View {
        VStack(alignment: .leading, spacing: .spacingMedium) {
            Label("Custom Tip", systemImage: "slider.horizontal.below.rectangle")
                .font(.headline)

            Picker("Tip input mode", selection: $tipInputMode) {
                Label("Percent", systemImage: "percent").tag(TipInputMode.percentage)
                Label("Amount", systemImage: "dollarsign").tag(TipInputMode.dollar)
            }
            .pickerStyle(.segmented)

            TextField(tipInputMode == .percentage ? "Custom percentage" : "Custom tip amount", text: $customTipValue)
                .keyboardType(.decimalPad)
                .textFieldStyle(GlassTextFieldStyle(palette: palette))
                .onChange(of: customTipValue) { _, newValue in
                    if !newValue.isEmpty {
                        synchronizeCustomTip()
                    }
                }
        }
        .glassCard(palette: palette)
    }

    private var totalCard: some View {
        VStack(alignment: .leading, spacing: .spacingMedium) {
            Label("Today", systemImage: "checkmark.circle")
                .font(.headline)

            HStack {
                AmountColumn(title: "Tip", amount: computedTipAmount, currencyCode: currencyCode)
                Divider()
                AmountColumn(title: "Total", amount: totalAmount, currencyCode: currencyCode, isPrimary: true)
            }
            .frame(minHeight: 88)

            HStack {
                Text("Bill")
                Spacer()
                Text(bill, format: .currency(code: currencyCode))
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
        }
        .glassCard(palette: palette, tint: palette.secondaryAccent.opacity(0.22))
        .animation(.snappy, value: totalAmount)
    }

    private var actionsCard: some View {
        HStack(spacing: .spacingMedium) {
            Button {
                resetCalculator()
            } label: {
                Label("Clear", systemImage: "xmark.circle")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)

            Button {
                saveTransaction()
            } label: {
                Label("Save", systemImage: "tray.and.arrow.down")
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

        let transaction = TipTransaction(
            restaurantName: restaurantName.trimmingCharacters(in: .whitespacesAndNewlines),
            billAmount: bill,
            tipPercentage: computedTipPercentage,
            tipAmount: computedTipAmount,
            totalAmount: totalAmount
        )
        modelContext.insert(transaction)
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

private struct TipSuggestionTile: View {
    @Environment(\.appPalette) private var palette

    let percentage: Double
    let bill: Double
    let currencyCode: String
    let isSelected: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("\(Int(percentage * 100))%")
                    .font(.title3.weight(.bold))
                Spacer()
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(isSelected ? palette.accent : palette.secondaryAccent.opacity(0.72))
            }

            Text(bill * percentage, format: .currency(code: currencyCode))
                .font(.headline)
                .contentTransition(.numericText())

            Text("Total \((bill + bill * percentage).formatted(.currency(code: currencyCode)))")
                .font(.caption)
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .padding()
        .frame(maxWidth: .infinity, minHeight: 116, alignment: .leading)
        .background(isSelected ? palette.selectedTile : palette.tile, in: RoundedRectangle(cornerRadius: 16))
        .overlay {
            RoundedRectangle(cornerRadius: 16)
                .strokeBorder(isSelected ? palette.accent.opacity(0.50) : palette.highlight.opacity(0.20), lineWidth: 1)
        }
        .glassEffect(isSelected ? .regular.tint(palette.accent.opacity(0.14)).interactive() : .regular.tint(palette.glassTint).interactive(), in: .rect(cornerRadius: 16))
    }
}

private struct AmountColumn: View {
    let title: String
    let amount: Double
    let currencyCode: String
    var isPrimary = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(amount, format: .currency(code: currencyCode))
                .font(isPrimary ? .title.weight(.bold) : .title2.weight(.semibold))
                .fontDesign(.rounded)
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
}
