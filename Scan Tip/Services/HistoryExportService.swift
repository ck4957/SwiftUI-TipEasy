import Foundation

enum HistoryExportService {
    static func csv(for transactions: [TipTransaction], currencyCode: String) -> String {
        var rows = [
            [
                "Date",
                "Place",
                "Bill",
                "Tip Percent",
                "Tip Amount",
                "Total",
                "Currency",
                "Location"
            ]
        ]

        rows += transactions.map { transaction in
            [
                transaction.date.formatted(.iso8601.year().month().day().time(includingFractionalSeconds: false)),
                transaction.restaurantName,
                decimalString(transaction.billAmount),
                decimalString(transaction.tipPercentage * 100),
                decimalString(transaction.tipAmount),
                decimalString(transaction.totalAmount),
                currencyCode,
                locationDisplayName(for: transaction)
            ]
        }

        return rows
            .map { row in row.map(escapeCSVField).joined(separator: ",") }
            .joined(separator: "\n")
    }

    private static func decimalString(_ value: Double) -> String {
        value.formatted(.number.precision(.fractionLength(2)))
    }

    private static func escapeCSVField(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        if escaped.contains(",") || escaped.contains("\"") || escaped.contains("\n") {
            return "\"\(escaped)\""
        }
        return escaped
    }

    private static func locationDisplayName(for transaction: TipTransaction) -> String {
        if let locationName = transaction.locationName, !locationName.isEmpty {
            return locationName
        }

        let components = [transaction.locationLocality, transaction.locationAdministrativeArea]
            .compactMap { $0?.isEmpty == false ? $0 : nil }
        return components.joined(separator: ", ")
    }
}
