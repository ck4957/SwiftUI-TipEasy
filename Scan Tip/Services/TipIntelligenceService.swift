import Foundation

struct TipInsight: Identifiable, Equatable {
    enum Kind {
        case info
        case warning
    }

    let id = UUID()
    let title: String
    let message: String
    let kind: Kind
}

struct HistorySummary {
    let title: String
    let message: String
    let highlights: [String]
}

enum TipIntelligenceService {
    static func explanation(
        bill: Double,
        tipPercentage: Double,
        tipAmount: Double,
        scanResult: ReceiptScanResult?
    ) -> TipInsight? {
        guard bill > 0 else { return nil }

        if let scanResult, scanResult.hasIncludedService {
            let included = (scanResult.serviceCharge ?? 0) + (scanResult.includedGratuity ?? 0)
            return TipInsight(
                title: "Service may already be included",
                message: "The receipt appears to include \(included.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))). Consider whether an extra tip is needed.",
                kind: .warning
            )
        }

        let percentage = Int((tipPercentage * 100).rounded())
        let message: String
        if tipPercentage < 0.15 {
            message = "\(percentage)% is below the common dining range. It can still fit counter service or a bill with an included charge."
        } else if tipPercentage < 0.20 {
            message = "\(percentage)% is a standard dining tip. It adds \(tipAmount.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))) to this bill."
        } else {
            message = "\(percentage)% is a generous option for attentive service. It adds \(tipAmount.formatted(.currency(code: Locale.current.currency?.identifier ?? "USD"))) to this bill."
        }

        return TipInsight(title: "Tip context", message: message, kind: .info)
    }

    static func anomalies(
        bill: Double,
        tipPercentage: Double,
        restaurantName: String,
        scanResult: ReceiptScanResult?,
        transactions: [TipTransaction]
    ) -> [TipInsight] {
        guard bill > 0 else { return [] }

        var insights: [TipInsight] = []
        let trimmedName = restaurantName.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()

        if let scanResult, scanResult.hasIncludedService {
            insights.append(TipInsight(
                title: "Check included charges",
                message: "This receipt looks like it already includes a service charge or gratuity.",
                kind: .warning
            ))
        }

        if transactions.contains(where: { transaction in
            Calendar.current.isDate(transaction.date, inSameDayAs: .now)
                && abs(transaction.billAmount - bill) < 0.01
                && (trimmedName.isEmpty || transaction.restaurantName.lowercased() == trimmedName)
        }) {
            insights.append(TipInsight(
                title: "Possible duplicate",
                message: "A similar bill is already saved today.",
                kind: .warning
            ))
        }

        if !transactions.isEmpty {
            let averageTip = transactions.reduce(0) { $0 + $1.tipPercentage } / Double(transactions.count)
            if tipPercentage > max(0.30, averageTip + 0.10) {
                insights.append(TipInsight(
                    title: "Higher than usual",
                    message: "This tip is above your usual range of about \(Int(averageTip * 100))%.",
                    kind: .warning
                ))
            }
        }

        return insights
    }

    static func summary(for transactions: [TipTransaction], currencyCode: String) -> HistorySummary? {
        guard !transactions.isEmpty else { return nil }

        let calendar = Calendar.current
        let thisMonth = transactions.filter { calendar.isDate($0.date, equalTo: .now, toGranularity: .month) }
        let scope = thisMonth.isEmpty ? transactions : thisMonth
        let total = scope.reduce(0) { $0 + $1.totalAmount }
        let averageTip = scope.reduce(0) { $0 + $1.tipPercentage } / Double(scope.count)
        let weekendCount = scope.filter { date in
            calendar.isDateInWeekend(date.date)
        }.count

        let topPlace = Dictionary(grouping: scope.filter { !$0.restaurantName.isEmpty }, by: \.restaurantName)
            .map { (name: $0.key, total: $0.value.reduce(0) { $0 + $1.totalAmount }) }
            .max { $0.total < $1.total }?
            .name

        let title = thisMonth.isEmpty ? "Saved history summary" : "This month"
        var highlights = [
            "\(scope.count) saved visit\(scope.count == 1 ? "" : "s")",
            "Average tip \(Int(averageTip * 100))%",
            "\(total.formatted(.currency(code: currencyCode))) total"
        ]

        if weekendCount > 0 {
            highlights.append("\(weekendCount) weekend visit\(weekendCount == 1 ? "" : "s")")
        }

        if let topPlace {
            highlights.append("Top place: \(topPlace)")
        }

        return HistorySummary(
            title: title,
            message: "Scan Tip summarized your local saved dining activity.",
            highlights: highlights
        )
    }
}

enum HistorySearchService {
    static func filter(_ transactions: [TipTransaction], query: String) -> [TipTransaction] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return transactions }

        let lowercased = trimmed.lowercased()
        return transactions.filter { transaction in
            matchesText(transaction, query: lowercased)
                || matchesRelativeDate(transaction, query: lowercased)
                || matchesTipComparison(transaction, query: lowercased)
                || matchesAmount(transaction, query: lowercased)
        }
    }

    private static func matchesText(_ transaction: TipTransaction, query: String) -> Bool {
        transaction.restaurantName.lowercased().contains(query)
    }

    private static func matchesRelativeDate(_ transaction: TipTransaction, query: String) -> Bool {
        let calendar = Calendar.current

        if query.contains("this month") {
            return calendar.isDate(transaction.date, equalTo: .now, toGranularity: .month)
        }

        if query.contains("last month"),
           let lastMonth = calendar.date(byAdding: .month, value: -1, to: .now)
        {
            return calendar.isDate(transaction.date, equalTo: lastMonth, toGranularity: .month)
        }

        if query.contains("this year") || query.contains("ytd") {
            return calendar.isDate(transaction.date, equalTo: .now, toGranularity: .year)
        }

        if query.contains("last year"),
           let lastYear = calendar.date(byAdding: .year, value: -1, to: .now)
        {
            return calendar.isDate(transaction.date, equalTo: lastYear, toGranularity: .year)
        }

        return false
    }

    private static func matchesTipComparison(_ transaction: TipTransaction, query: String) -> Bool {
        guard let percent = firstNumber(in: query) else { return false }
        let fraction = percent / 100

        if query.contains("over") || query.contains("above") || query.contains(">") {
            return transaction.tipPercentage > fraction
        }

        if query.contains("under") || query.contains("below") || query.contains("<") {
            return transaction.tipPercentage < fraction
        }

        return false
    }

    private static func matchesAmount(_ transaction: TipTransaction, query: String) -> Bool {
        guard query.contains("$") || query.contains("spent") || query.contains("total"),
              let amount = firstNumber(in: query)
        else {
            return false
        }

        if query.contains("over") || query.contains("above") || query.contains(">") {
            return transaction.totalAmount > amount
        }

        if query.contains("under") || query.contains("below") || query.contains("<") {
            return transaction.totalAmount < amount
        }

        return abs(transaction.totalAmount - amount) < 1
    }

    private static func firstNumber(in text: String) -> Double? {
        let pattern = #"(\d+(?:\.\d+)?)"#
        guard let regex = try? NSRegularExpression(pattern: pattern),
              let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..<text.endIndex, in: text)),
              let range = Range(match.range(at: 1), in: text)
        else {
            return nil
        }

        return Double(text[range])
    }
}
