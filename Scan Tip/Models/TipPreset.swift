import Foundation
import SwiftData

@Model
final class TipPreset: Identifiable {
    var id: UUID = UUID()
    var percentage: Double = 0

    init(percentage: Double) {
        self.percentage = percentage
    }
}
