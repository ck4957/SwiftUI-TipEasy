import Foundation
import FoundationModels

enum ReceiptIntelligenceService {
    static func analyzeReceiptText(_ text: String) async -> ReceiptScanResult {
        var localResult = ReceiptTextParser.analyze(text)

        guard #available(iOS 26.0, *), SystemLanguageModel.default.isAvailable else {
            return localResult
        }

        do {
            let session = LanguageModelSession(
                instructions: """
                You extract structured receipt data for a tip calculator. Return JSON only.
                Keys: merchantName, subtotal, tax, serviceCharge, includedGratuity, total.
                Use numbers for amounts. Use null when a field is absent. Do not guess beyond the receipt text.
                """
            )

            let response = try await session.respond(to: """
            Receipt OCR:
            \(text)
            """)

            if let modelResult = parseModelJSON(response.content, rawText: text) {
                localResult = merge(localResult, with: modelResult)
                localResult.usedAppleIntelligence = true
            }
        } catch {
            return localResult
        }

        return localResult
    }

    private static func parseModelJSON(_ json: String, rawText: String) -> ReceiptScanResult? {
        guard let data = json.data(using: .utf8),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return nil
        }

        return ReceiptScanResult(
            merchantName: object["merchantName"] as? String ?? "",
            subtotal: number(for: "subtotal", in: object),
            tax: number(for: "tax", in: object),
            serviceCharge: number(for: "serviceCharge", in: object),
            includedGratuity: number(for: "includedGratuity", in: object),
            total: number(for: "total", in: object),
            rawText: rawText,
            usedAppleIntelligence: true
        )
    }

    private static func number(for key: String, in object: [String: Any]) -> Double? {
        if let value = object[key] as? Double {
            return value
        }

        if let value = object[key] as? Int {
            return Double(value)
        }

        if let value = object[key] as? String {
            return ReceiptTextParser.parseAmount(value)
        }

        return nil
    }

    private static func merge(_ fallback: ReceiptScanResult, with model: ReceiptScanResult) -> ReceiptScanResult {
        ReceiptScanResult(
            merchantName: model.merchantName.isEmpty ? fallback.merchantName : model.merchantName,
            subtotal: model.subtotal ?? fallback.subtotal,
            tax: model.tax ?? fallback.tax,
            serviceCharge: model.serviceCharge ?? fallback.serviceCharge,
            includedGratuity: model.includedGratuity ?? fallback.includedGratuity,
            total: model.total ?? fallback.total,
            rawText: fallback.rawText,
            usedAppleIntelligence: true
        )
    }
}

enum ReceiptTextParser {
    static func analyze(_ text: String) -> ReceiptScanResult {
        let lines = text
            .components(separatedBy: .newlines)
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        let subtotal = labeledAmount(in: lines, labels: ["subtotal", "sub total"])
        let tax = labeledAmount(in: lines, labels: ["tax", "sales tax"])
        let service = labeledAmount(in: lines, labels: ["service", "service charge", "surcharge"])
        let gratuity = labeledAmount(in: lines, labels: ["gratuity", "included tip", "auto gratuity", "tip included"])
        let total = labeledAmount(in: lines, labels: ["total", "amount due", "balance due", "paid"])
            ?? amounts(in: text).max()

        return ReceiptScanResult(
            merchantName: merchantName(from: lines),
            subtotal: subtotal,
            tax: tax,
            serviceCharge: service,
            includedGratuity: gratuity,
            total: total,
            rawText: text,
            usedAppleIntelligence: false
        )
    }

    static func amounts(in text: String) -> [Double] {
        let pattern = #"(?<!\d)(?:[$€£]\s*)?(\d{1,4}(?:[,.]\d{3})*(?:[,.]\d{2})|\d{1,4}[,.]\d{2})(?!\d)"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }

        let range = NSRange(text.startIndex..<text.endIndex, in: text)
        return regex.matches(in: text, range: range).compactMap { match in
            guard let amountRange = Range(match.range(at: 1), in: text) else { return nil }
            return parseAmount(String(text[amountRange]))
        }
        .filter { $0 > 0 }
    }

    static func parseAmount(_ rawValue: String) -> Double? {
        var value = rawValue.replacingOccurrences(of: " ", with: "")

        if value.contains(","), value.contains(".") {
            value = value.replacingOccurrences(of: ",", with: "")
        } else {
            value = value.replacingOccurrences(of: ",", with: ".")
        }

        return Double(value.filter { "0123456789.".contains($0) })
    }

    private static func labeledAmount(in lines: [String], labels: [String]) -> Double? {
        for line in lines.reversed() {
            let lowercased = line.lowercased()
            guard labels.contains(where: { lowercased.contains($0) }) else { continue }
            if let amount = amounts(in: line).last {
                return amount
            }
        }

        return nil
    }

    private static func merchantName(from lines: [String]) -> String {
        let ignoredTerms = ["receipt", "invoice", "order", "table", "server", "date", "time", "total", "tax", "subtotal"]

        return lines
            .prefix(6)
            .first { line in
                let lowercased = line.lowercased()
                return line.count >= 3
                    && amounts(in: line).isEmpty
                    && !ignoredTerms.contains(where: { lowercased.contains($0) })
            } ?? ""
    }
}
