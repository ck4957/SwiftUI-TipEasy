import Foundation
import SwiftData

@Model
final class TipTransaction: Identifiable {
    var id: UUID = UUID()
    var date: Date
    var restaurantName: String
    var billAmount: Double
    var tipPercentage: Double
    var tipAmount: Double
    var totalAmount: Double
    var receiptPhotoFilename: String?

    init(
        date: Date = .now,
        restaurantName: String = "",
        billAmount: Double,
        tipPercentage: Double,
        tipAmount: Double,
        totalAmount: Double,
        receiptPhotoFilename: String? = nil
    ) {
        self.date = date
        self.restaurantName = restaurantName
        self.billAmount = billAmount
        self.tipPercentage = tipPercentage
        self.tipAmount = tipAmount
        self.totalAmount = totalAmount
        self.receiptPhotoFilename = receiptPhotoFilename
    }
}
