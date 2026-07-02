import Foundation
import SwiftData

@Model
final class TipTransaction: Identifiable {
    var id: UUID = UUID()
    var date: Date = Date()
    var restaurantName: String = ""
    var billAmount: Double = 0
    var tipPercentage: Double = 0
    var tipAmount: Double = 0
    var totalAmount: Double = 0
    var receiptPhotoFilename: String?
    var locationLatitude: Double?
    var locationLongitude: Double?
    var locationName: String?
    var locationLocality: String?
    var locationAdministrativeArea: String?
    var locationCapturedAt: Date?

    init(
        date: Date = .now,
        restaurantName: String = "",
        billAmount: Double,
        tipPercentage: Double,
        tipAmount: Double,
        totalAmount: Double,
        receiptPhotoFilename: String? = nil,
        location: TipLocationSnapshot? = nil
    ) {
        self.date = date
        self.restaurantName = restaurantName
        self.billAmount = billAmount
        self.tipPercentage = tipPercentage
        self.tipAmount = tipAmount
        self.totalAmount = totalAmount
        self.receiptPhotoFilename = receiptPhotoFilename
        self.locationLatitude = location?.latitude
        self.locationLongitude = location?.longitude
        self.locationName = location?.name
        self.locationLocality = location?.locality
        self.locationAdministrativeArea = location?.administrativeArea
        self.locationCapturedAt = location?.capturedAt
    }
}
