import Foundation

enum TipPresetCatalog {
    static let hiddenDefaultPresetsKey = "hiddenDefaultTipPresetBasisPoints"
    static let defaultPercentages: [Double] = [0.15, 0.18, 0.20, 0.25]

    static func activePercentages(customPercentages: [Double], hiddenDefaultStorage: String) -> [Double] {
        let hiddenDefaults = hiddenDefaultBasisPoints(from: hiddenDefaultStorage)
        let visibleDefaults = defaultPercentages.filter { !hiddenDefaults.contains(basisPoints(for: $0)) }
        return sortedUnique(visibleDefaults + customPercentages)
    }

    static func hiddenDefaultBasisPoints(from storage: String) -> Set<Int> {
        Set(
            storage
                .split(separator: ",")
                .compactMap { Int($0.trimmingCharacters(in: .whitespacesAndNewlines)) }
        )
    }

    static func storageString(from basisPoints: Set<Int>) -> String {
        basisPoints
            .sorted()
            .map(String.init)
            .joined(separator: ",")
    }

    static func basisPoints(for percentage: Double) -> Int {
        Int((percentage * 10_000).rounded())
    }

    static func percentage(fromBasisPoints basisPoints: Int) -> Double {
        Double(basisPoints) / 10_000
    }

    static func sortedUnique(_ percentages: [Double]) -> [Double] {
        let uniqueBasisPoints = Set(percentages.map { basisPoints(for: $0) })
        return uniqueBasisPoints
            .sorted()
            .map { percentage(fromBasisPoints: $0) }
    }
}

struct TipPresetDisplayItem: Identifiable {
    enum Source {
        case builtIn
        case custom(TipPreset)
    }

    let percentage: Double
    let source: Source

    var id: String {
        switch source {
        case .builtIn:
            "built-in-\(TipPresetCatalog.basisPoints(for: percentage))"
        case .custom(let preset):
            "custom-\(preset.id.uuidString)"
        }
    }

    var sourceLabel: String {
        switch source {
        case .builtIn:
            "Built-in"
        case .custom:
            "Custom"
        }
    }
}
