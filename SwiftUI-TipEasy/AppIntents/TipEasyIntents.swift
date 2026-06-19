import AppIntents
import Foundation
import SwiftData

enum TipEasyDestination: String, AppEnum {
    case calculator
    case scanner
    case history
    case settings

    static var typeDisplayRepresentation = TypeDisplayRepresentation(name: "Tip Easy Destination")

    static var caseDisplayRepresentations: [TipEasyDestination: DisplayRepresentation] = [
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

struct CalculateTipIntent: AppIntent {
    static var title: LocalizedStringResource = "Calculate Tip"
    static var description = IntentDescription("Calculate a tip and total without opening Tip Easy.")

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

    func perform() async throws -> some IntentResult {
        let tip = billAmount * tipPercent / 100
        let total = billAmount + tip
        let currencyCode = Locale.current.currency?.identifier ?? "USD"

        return .result(dialog: """
        \(Int(tipPercent))% tip is \(tip.formatted(.currency(code: currencyCode))). Total is \(total.formatted(.currency(code: currencyCode))).
        """)
    }
}

struct SaveTipIntent: AppIntent {
    static var title: LocalizedStringResource = "Save Tip"
    static var description = IntentDescription("Save a tip calculation to Tip Easy history.")

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

        return .result(value: TipTransactionEntity(transaction: transaction), dialog: "Saved to Tip Easy history.")
    }
}

struct OpenSavedTipIntent: OpenIntent {
    static var title: LocalizedStringResource = "Open Saved Tip"
    static var description = IntentDescription("Open Tip Easy history for a saved tip.")
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
        UserDefaults.standard.set(TipEasyDestination.history.rawValue, forKey: "pendingTipEasyDestination")
        UserDefaults.standard.set(target.id.uuidString, forKey: "pendingTipEasyTransactionID")
        return .result()
    }
}

struct OpenTipEasyIntent: AppIntent {
    static var title: LocalizedStringResource = "Open Tip Easy"
    static var description = IntentDescription("Open Tip Easy to a specific area.")
    static var openAppWhenRun = true

    @Parameter(title: "Destination")
    var destination: TipEasyDestination

    init() {
        destination = .calculator
    }

    init(destination: TipEasyDestination) {
        self.destination = destination
    }

    func perform() async throws -> some IntentResult {
        UserDefaults.standard.set(destination.rawValue, forKey: "pendingTipEasyDestination")
        UserDefaults.standard.set(destination == .scanner, forKey: "pendingOpenScanner")
        return .result()
    }
}

struct TipEasyShortcuts: AppShortcutsProvider {
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
            intent: SaveTipIntent(),
            phrases: [
                "Save a tip with \(.applicationName)",
                "Add tip to \(.applicationName)"
            ],
            shortTitle: "Save Tip",
            systemImageName: "tray.and.arrow.down"
        )

        AppShortcut(
            intent: OpenTipEasyIntent(destination: .scanner),
            phrases: [
                "Scan a receipt with \(.applicationName)",
                "Open \(.applicationName) scanner"
            ],
            shortTitle: "Scan Receipt",
            systemImageName: "camera.viewfinder"
        )

        AppShortcut(
            intent: OpenTipEasyIntent(destination: .history),
            phrases: [
                "Show \(.applicationName) history",
                "Open my \(.applicationName) tips"
            ],
            shortTitle: "Tip History",
            systemImageName: "clock.arrow.circlepath"
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
