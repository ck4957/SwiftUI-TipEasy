import SwiftUI
import MapKit
struct HistoryDetailView: View {
    let calculation: CalculationHistory
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Photo if available
                    if let photoData = calculation.photo, let uiImage = UIImage(data: photoData) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(12)
                            .frame(maxHeight: 250)
                    }
                    
                    // Summary card
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Label(calculation.category.rawValue, systemImage: calculation.category.icon)
                                .font(.headline)
                            Spacer()
                            Text(formatDate(calculation.timestamp))
                                .font(.caption)
                        }
                        
                        Divider()
                        
                        detailRow(title: "Bill Amount:", value: calculation.billAmount)
                        detailRow(title: "Tip (\(Int(calculation.tipPercentage * 100))%):", value: calculation.tipAmount)
                        
                        Divider()
                        
                        detailRow(title: "Total Amount:", value: calculation.totalAmount, isTotal: true)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(12)
                    
                    // Map if location available
                    if let location = calculation.location {
                        VStack(alignment: .leading) {
                            Text("Location")
                                .font(.headline)
                                .padding(.bottom, 4)
                            
                            Map(initialPosition: .region(MKCoordinateRegion(
                                center: location,
                                span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                            ))) {
                                Marker("", coordinate: location)
                            }
                            .frame(height: 200)
                            .cornerRadius(12)
                        }
                    }
                }
                .padding()
            }
            .navigationTitle("Calculation Details")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func detailRow(title: String, value: Double, isTotal: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(isTotal ? .headline : .body)
            Spacer()
            Text(formatCurrency(value))
                .font(isTotal ? .headline : .body)
                .fontWeight(isTotal ? .bold : .regular)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatCurrency(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "USD"
        return formatter.string(from: NSNumber(value: value)) ?? "$0.00"
    }
}

#Preview {
    HistoryDetailView(calculation: CalculationHistory.sampleTransactions[0])
        .preferredColorScheme(.light)
}