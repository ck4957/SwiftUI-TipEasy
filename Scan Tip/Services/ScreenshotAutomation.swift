import Foundation
import SwiftData

enum ScreenshotAutomation {
    static var isEnabled: Bool {
        ProcessInfo.processInfo.arguments.contains("-scanTipScreenshotAutomation")
    }

    static var scenario: String {
        argumentValue(after: "-scanTipScreenshotScenario") ?? "main-flow"
    }

    static var shouldShowOnboarding: Bool {
        scenario == "onboarding"
    }

    static func configureUserDefaults() {
        guard isEnabled else { return }

        let defaults = UserDefaults.standard
        defaults.set(!shouldShowOnboarding, forKey: "hasCompletedOnboarding")
        defaults.removeObject(forKey: "pendingOpenScanner")
        defaults.removeObject(forKey: "pendingScanTipDestination")
        defaults.removeObject(forKey: "pendingScanTipTransactionID")
    }

    @MainActor
    static func seedSampleData(in container: ModelContainer) throws {
        guard isEnabled, !shouldShowOnboarding else { return }

        let context = ModelContext(container)
        try context.delete(model: TipTransaction.self)
        try context.delete(model: TipPreset.self)

        let calendar = Calendar(identifier: .gregorian)
        let now = Date()
        let samples: [(String, Double, Double, Int)] = [
            ("Juniper Table", 84.20, 0.20, -3),
            ("Cafe Luna", 32.40, 0.18, -12),
            ("Soba House", 58.75, 0.22, -28),
            ("Market Grill", 96.10, 0.20, -46),
            ("North Pier", 124.80, 0.19, -72)
        ]

        for sample in samples {
            let tipAmount = sample.1 * sample.2
            let date = calendar.date(byAdding: .day, value: sample.3, to: now) ?? now
            context.insert(
                TipTransaction(
                    date: date,
                    restaurantName: sample.0,
                    billAmount: sample.1,
                    tipPercentage: sample.2,
                    tipAmount: tipAmount,
                    totalAmount: sample.1 + tipAmount
                )
            )
        }

        context.insert(TipPreset(percentage: 0.18))
        context.insert(TipPreset(percentage: 0.22))

        try context.save()
    }

    private static func argumentValue(after flag: String) -> String? {
        let arguments = ProcessInfo.processInfo.arguments
        guard let index = arguments.firstIndex(of: flag),
              arguments.indices.contains(arguments.index(after: index)) else {
            return nil
        }

        return arguments[arguments.index(after: index)]
    }
}
