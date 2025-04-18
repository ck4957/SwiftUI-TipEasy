import Foundation

struct SpendingSummary: Identifiable {
    let id = UUID()
    let period: String
    let total: Double
}

enum SpendingChartPeriod: String, CaseIterable, Identifiable {
    case monthly = "Monthly"
    case quarterly = "Quarterly"
    case yearly = "Yearly"

    var id: String { rawValue }
}