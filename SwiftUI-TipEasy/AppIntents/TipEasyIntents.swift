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

    func perform() async throws -> some IntentResult {
        let tip = billAmount * tipPercent / 100
        let total = billAmount + tip
        let container = try ModelContainer(for: TipPreset.self, TipTransaction.self)
        let context = ModelContext(container)

        context.insert(TipTransaction(
            restaurantName: restaurantName,
            billAmount: billAmount,
            tipPercentage: tipPercent / 100,
            tipAmount: tip,
            totalAmount: total
        ))
        try context.save()

        return .result(dialog: "Saved to Tip Easy history.")
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
