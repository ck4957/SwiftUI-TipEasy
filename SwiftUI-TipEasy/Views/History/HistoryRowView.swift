
import SwiftUI

struct HistoryRowView: View {
    let calculation: CalculationHistory
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Label(calculation.category.rawValue, systemImage: calculation.category.icon)
                    .font(.headline)
                Spacer()
                Text(currencyFormatter.string(from: NSNumber(value: calculation.totalAmount)) ?? "$0.00")
                    .font(.headline)
            }
            
            Text(dateFormatter.string(from: calculation.timestamp))
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack {
                Text("Bill: \(formatCurrency(calculation.billAmount))")
                Text("•")
                Text("Tip: \(Int(calculation.tipPercentage * 100))%")
                
                if calculation.photo != nil {
                    Spacer()
                    Image(systemName: "photo")
                        .foregroundColor(.secondary)
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        currencyFormatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }
    
    private var currencyFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter
    }
}

#Preview {
    HistoryRowView(calculation: CalculationHistory.sampleTransactions[0])
        .preferredColorScheme(.light)
}