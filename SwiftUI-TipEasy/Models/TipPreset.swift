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

@Model
class CalculationHistory {
    var billAmount: Double
    var tipPercentage: Double
    var tipAmount: Double
    var totalAmount: Double
    var timestamp: Date
    var location: String?
    var photo: Data?

    init(billAmount: Double, tipPercentage: Double, tipAmount: Double, totalAmount: Double, timestamp: Date, location: String? = nil, photo: Data? = nil) {
        self.billAmount = billAmount
        self.tipPercentage = tipPercentage
        self.tipAmount = tipAmount
        self.totalAmount = totalAmount
        self.timestamp = timestamp
        self.location = location
        self.photo = photo
    }
}

extension CalculationHistory {
    static var sampleTransactions: [CalculationHistory] {
        let locations = ["San Francisco, CA", "New York, NY", "Seattle, WA", "Austin, TX"]
        let calendar = Calendar.current
        let today = Date()

        return (0 ..< 10).map { i in
            let daysAgo = i * 3 // Spread over last 30 days
            let date = calendar.date(byAdding: .day, value: -daysAgo, to: today)!

            let transaction = CalculationHistory(
                billAmount: Double.random(in: 20...200).rounded(to: 2),
                tipPercentage: [0.15, 0.18, 0.20].randomElement()!, tipAmount: Double.random(in: 5...40).rounded(to: 2),
                totalAmount: Double.random(in: 25...240).rounded(to: 2), timestamp: Date(),
                location: locations.randomElement(),
                photo: nil
            )
            transaction.timestamp = date
            return transaction
        }
    }
}

extension Double {
    func rounded(to places: Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return (self * divisor).rounded() / divisor
    }
}
