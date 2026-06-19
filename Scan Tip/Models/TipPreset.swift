import Foundation
import SwiftData

@Model
final class TipPreset: Identifiable {
    var id: UUID = UUID()
    var percentage: Double

    init(percentage: Double) {
        self.percentage = percentage
    }
}
