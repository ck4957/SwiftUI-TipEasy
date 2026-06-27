import Foundation

struct ReceiptScanResult: Equatable {
    var merchantName: String
    var subtotal: Double?
    var tax: Double?
    var serviceCharge: Double?
    var includedGratuity: Double?
    var total: Double?
    var rawText: String
    var usedAppleIntelligence: Bool
    var receiptPhotoData: Data?

    static let empty = ReceiptScanResult(
        merchantName: "",
        subtotal: nil,
        tax: nil,
        serviceCharge: nil,
        includedGratuity: nil,
        total: nil,
        rawText: "",
        usedAppleIntelligence: false,
        receiptPhotoData: nil
    )

    var hasIncludedService: Bool {
        (serviceCharge ?? 0) > 0 || (includedGratuity ?? 0) > 0
    }
}
