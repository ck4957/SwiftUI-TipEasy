import AppIntents
import Foundation
import SwiftData

enum ScanTipDestination: String, AppEnum {
    case calculator
    case scanner
    case history
    case settings

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Scan Tip Destination")

    static var caseDisplayRepresentations: [ScanTipDestination: DisplayRepresentation] = [
        .calculator: "Calculator",
        .scanner: "Receipt Scanner",
        .history: "History",
        .settings: "Settings"
    ]
}

struct TipTransactionEntity: AppEntity, Identifiable {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Saved Tip")
    static var defaultQuery = TipTransactionQuery()

    let id: UUID
    let date: Date
    let restaurantName: String
    let billAmount: Double
    let tipPercentage: Double
    let tipAmount: Double
    let totalAmount: Double

    var displayRepresentation: DisplayRepresentation {
        let currencyCode = Locale.current.currency?.identifier ?? "USD"
        let title = restaurantName.isEmpty ? "Saved Tip" : restaurantName
        let subtitle = "\(Int((tipPercentage * 100).rounded()))% tip, total \(totalAmount.formatted(.currency(code: currencyCode)))"

        return DisplayRepresentation(
            title: "\(title)",
            subtitle: "\(subtitle)",
            image: .init(systemName: "receipt")
        )
    }
}

struct TipTransactionQuery: EntityStringQuery {
    func entities(for identifiers: [TipTransactionEntity.ID]) async throws -> [TipTransactionEntity] {
        let identifierSet = Set(identifiers)
        return try fetchEntities().filter { identifierSet.contains($0.id) }
    }

    func entities(matching string: String) async throws -> [TipTransactionEntity] {
        let query = string.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            return try await suggestedEntities()
        }

        return try fetchEntities().filter { entity in
            entity.restaurantName.localizedCaseInsensitiveContains(query)
            || entity.date.formatted(date: .abbreviated, time: .omitted).localizedCaseInsensitiveContains(query)
        }
    }

    func suggestedEntities() async throws -> [TipTransactionEntity] {
        try Array(fetchEntities().prefix(10))
    }

    private func fetchEntities() throws -> [TipTransactionEntity] {
        let container = try ModelContainer(for: TipPreset.self, TipTransaction.self)
        let context = ModelContext(container)
        var descriptor = FetchDescriptor<TipTransaction>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        descriptor.fetchLimit = 50

        return try context.fetch(descriptor).map(TipTransactionEntity.init(transaction:))
    }
}

struct TipCalculationRequestEntity: AppEntity, Identifiable {
    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Tip Calculation")
    static var defaultQuery = TipCalculationRequestQuery()

    let id: String
    let request: String
    let billAmount: Double
    let tipPercent: Double

    var displayRepresentation: DisplayRepresentation {
        let calculation = TipCalculation.calculate(billAmount: billAmount, tipPercent: tipPercent)
        return DisplayRepresentation(
            title: "\(request)",
            subtitle: "\(calculation.summary)",
            image: .init(systemName: "percent")
        )
    }
}

struct TipCalculationRequestQuery: EntityStringQuery {
    func entities(for identifiers: [TipCalculationRequestEntity.ID]) async throws -> [TipCalculationRequestEntity] {
        identifiers.compactMap(TipCalculationRequestEntity.init(request:))
    }

    func entities(matching string: String) async throws -> [TipCalculationRequestEntity] {
        guard let entity = TipCalculationRequestEntity(request: string) else {
            return []
        }

        return [entity]
    }

    func suggestedEntities() async throws -> [TipCalculationRequestEntity] {
        [
            TipCalculationRequestEntity(request: "$250 with 15% tip"),
            TipCalculationRequestEntity(request: "$100 with 20% tip"),
            TipCalculationRequestEntity(request: "15 percent on 50 dollars")
        ].compactMap { $0 }
    }
}

struct CalculateTipIntent: AppIntent {
    static var title: LocalizedStringResource = "Calculate Tip"
    static var description = IntentDescription("Calculate a tip and total without opening Scan Tip.")
    static var parameterSummary: some ParameterSummary {
        Summary("Calculate a \(\.$tipPercent) percent tip for \(\.$billAmount)")
    }

    @Parameter(title: "Bill Amount")
    var billAmount: Double

    @Parameter(title: "Tip Percent")
    var tipPercent: Double

    init() {
        billAmount = 50
        tipPercent = 20
    }

    init(billAmount: Double, tipPercent: Double) {
        self.billAmount = billAmount
        self.tipPercent = tipPercent
    }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let calculation = TipCalculation.calculate(billAmount: billAmount, tipPercent: tipPercent)
        return .result(value: calculation.summary, dialog: "\(calculation.summary)")
    }
}

struct CalculateTipFromTextIntent: AppIntent {
    static var title: LocalizedStringResource = "Calculate Tip From Phrase"
    static var description = IntentDescription("Calculate a tip from a natural language phrase, such as '$250 with 15% tip'.")
    static var parameterSummary: some ParameterSummary {
        Summary("Calculate tip for \(\.$request)")
    }

    @Parameter(
        title: "Request",
        description: "For example: $250 with 15% tip, 15 percent on 250, or tip for 250 at 15 percent."
    )
    var request: TipCalculationRequestEntity

    init() {
        request = TipCalculationRequestEntity(request: "$250 with 15% tip")!
    }

    init(request: TipCalculationRequestEntity) {
        self.request = request
    }

    func perform() async throws -> some IntentResult & ReturnsValue<String> {
        let calculation = TipCalculation.calculate(
            billAmount: request.billAmount,
            tipPercent: request.tipPercent
        )

        return .result(value: calculation.summary, dialog: "\(calculation.summary)")
    }
}

struct SaveTipIntent: AppIntent {
    static var title: LocalizedStringResource = "Save Tip"
    static var description = IntentDescription("Save a tip calculation to Scan Tip history.")

    @Parameter(title: "Bill Amount")
    var billAmount: Double

    @Parameter(title: "Tip Percent")
    var tipPercent: Double

    @Parameter(title: "Restaurant")
    var restaurantName: String

    init() {
        billAmount = 50
        tipPercent = 20
        restaurantName = ""
    }

    func perform() async throws -> some IntentResult & ReturnsValue<TipTransactionEntity> {
        let tip = billAmount * tipPercent / 100
        let total = billAmount + tip
        let container = try ModelContainer(for: TipPreset.self, TipTransaction.self)
        let context = ModelContext(container)
        let transaction = TipTransaction(
            restaurantName: restaurantName,
            billAmount: billAmount,
            tipPercentage: tipPercent / 100,
            tipAmount: tip,
            totalAmount: total
        )

        context.insert(transaction)
        try context.save()

        return .result(value: TipTransactionEntity(transaction: transaction), dialog: "Saved to Scan Tip history.")
    }
}

struct OpenSavedTipIntent: OpenIntent {
    static var title: LocalizedStringResource = "Open Saved Tip"
    static var description = IntentDescription("Open Scan Tip history for a saved tip.")
    static var openAppWhenRun = true

    @Parameter
    var target: TipTransactionEntity

    init() {
        target = TipTransactionEntity.placeholder
    }

    init(target: TipTransactionEntity) {
        self.target = target
    }

    func perform() async throws -> some IntentResult {
        UserDefaults.standard.set(ScanTipDestination.history.rawValue, forKey: "pendingScanTipDestination")
        UserDefaults.standard.set(target.id.uuidString, forKey: "pendingScanTipTransactionID")
        return .result()
    }
}

struct OpenScanTipIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Scan Tip"
    static var description = IntentDescription("Open Scan Tip to a specific area.")
    static var openAppWhenRun = true

    @Parameter(title: "Destination")
    var destination: ScanTipDestination

    init() {
        destination = .calculator
    }

    init(destination: ScanTipDestination) {
        self.destination = destination
    }

    func perform() async throws -> some IntentResult {
        UserDefaults.standard.set(destination.rawValue, forKey: "pendingScanTipDestination")
        UserDefaults.standard.set(destination == .scanner, forKey: "pendingOpenScanner")
        return .result()
    }
}

struct ScanTipShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: CalculateTipIntent(),
            phrases: [
                "Calculate a tip with \(.applicationName)",
                "Calculate \(.applicationName) tip"
            ],
            shortTitle: "Calculate Tip",
            systemImageName: "percent"
        )

        AppShortcut(
            intent: CalculateTipFromTextIntent(),
            phrases: [
                "Calculate tip for \(\.$request) with \(.applicationName)",
                "Ask \(.applicationName) to calculate \(\.$request)"
            ],
            shortTitle: "Tip From Phrase",
            systemImageName: "text.magnifyingglass"
        )

        AppShortcut(
            intent: SaveTipIntent(),
            phrases: [
                "Save a tip with \(.applicationName)",
                "Add tip to \(.applicationName)"
            ],
            shortTitle: "Save Tip",
            systemImageName: "tray.and.arrow.down"
        )

        AppShortcut(
            intent: OpenScanTipIntent(destination: .scanner),
            phrases: [
                "Scan a receipt with \(.applicationName)",
                "Open \(.applicationName) scanner"
            ],
            shortTitle: "Scan Receipt",
            systemImageName: "camera.viewfinder"
        )

        AppShortcut(
            intent: OpenScanTipIntent(destination: .history),
            phrases: [
                "Show \(.applicationName) history",
                "Open my \(.applicationName) tips"
            ],
            shortTitle: "Tip History",
            systemImageName: "clock.arrow.circlepath"
        )
    }
}

private enum TipCalculation {
    struct ParsedRequest {
        let billAmount: Double
        let tipPercent: Double
    }

    struct Result {
        let tip: Double
        let total: Double
        let summary: String
    }

    static func calculate(billAmount: Double, tipPercent: Double) -> Result {
        let tip = billAmount * tipPercent / 100
        let total = billAmount + tip
        let currencyCode = Locale.current.currency?.identifier ?? "USD"
        let percent = tipPercent.formatted(.number.precision(.fractionLength(0...2)))
        let summary = "\(percent)% tip is \(tip.formatted(.currency(code: currencyCode))). Total is \(total.formatted(.currency(code: currencyCode)))."

        return Result(tip: tip, total: total, summary: summary)
    }

    static func parse(_ request: String) -> ParsedRequest? {
        let normalized = request
            .lowercased()
            .replacingOccurrences(of: ",", with: "")

        guard let tipPercent = percentValue(in: normalized),
              let billAmount = billAmount(in: normalized, excluding: tipPercent.rawRange)
        else {
            return nil
        }

        return ParsedRequest(billAmount: billAmount, tipPercent: tipPercent.value)
    }

    private static func percentValue(in text: String) -> (value: Double, rawRange: Range<String.Index>)? {
        let patterns = [
            #"(\d+(?:\.\d+)?)\s*%"#,
            #"(\d+(?:\.\d+)?)\s*(?:percent|percentage)"#
        ]

        for pattern in patterns {
            guard let match = firstMatch(pattern: pattern, in: text),
                  let valueRange = Range(match.range(at: 1), in: text),
                  let rawRange = Range(match.range, in: text),
                  let value = Double(text[valueRange])
            else {
                continue
            }

            return (value, rawRange)
        }

        return nil
    }

    private static func billAmount(in text: String, excluding excludedRange: Range<String.Index>) -> Double? {
        let patterns = [
            #"\$\s*(\d+(?:\.\d+)?)"#,
            #"(\d+(?:\.\d+)?)\s*\$"#,
            #"(\d+(?:\.\d+)?)\s*(?:dollars|dollar|bucks)"#,
            #"(?:for|on|bill|check|total)\s+\$?\s*(\d+(?:\.\d+)?)"#
        ]

        for pattern in patterns {
            let matches = allMatches(pattern: pattern, in: text)
            for match in matches {
                guard let rawRange = Range(match.range, in: text),
                      !rawRange.overlaps(excludedRange),
                      let valueRange = Range(match.range(at: 1), in: text),
                      let value = Double(text[valueRange])
                else {
                    continue
                }

                return value
            }
        }

        return allNumberMatches(in: text)
            .first { match in
                !match.range.overlaps(excludedRange)
            }?
            .value
    }

    private static func firstMatch(pattern: String, in text: String) -> NSTextCheckingResult? {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        return regex.firstMatch(in: text, range: NSRange(text.startIndex..<text.endIndex, in: text))
    }

    private static func allMatches(pattern: String, in text: String) -> [NSTextCheckingResult] {
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        return regex.matches(in: text, range: NSRange(text.startIndex..<text.endIndex, in: text))
    }

    private static func allNumberMatches(in text: String) -> [(value: Double, range: Range<String.Index>)] {
        allMatches(pattern: #"(\d+(?:\.\d+)?)"#, in: text).compactMap { match in
            guard let rawRange = Range(match.range, in: text),
                  let valueRange = Range(match.range(at: 1), in: text),
                  let value = Double(text[valueRange])
            else {
                return nil
            }

            return (value, rawRange)
        }
    }
}

private extension TipCalculationRequestEntity {
    init?(request: String) {
        let trimmed = request.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let parsed = TipCalculation.parse(trimmed) else {
            return nil
        }

        self.init(
            id: trimmed.lowercased(),
            request: trimmed,
            billAmount: parsed.billAmount,
            tipPercent: parsed.tipPercent
        )
    }
}

private extension TipTransactionEntity {
    init(transaction: TipTransaction) {
        self.init(
            id: transaction.id,
            date: transaction.date,
            restaurantName: transaction.restaurantName,
            billAmount: transaction.billAmount,
            tipPercentage: transaction.tipPercentage,
            tipAmount: transaction.tipAmount,
            totalAmount: transaction.totalAmount
        )
    }

    static var placeholder: TipTransactionEntity {
        TipTransactionEntity(
            id: UUID(),
            date: .now,
            restaurantName: "",
            billAmount: 0,
            tipPercentage: 0,
            tipAmount: 0,
            totalAmount: 0
        )
    }
}
