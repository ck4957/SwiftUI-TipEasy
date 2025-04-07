import MapKit
import SwiftUI

struct HistoryView: View {
    let history: [CalculationHistory]
    let onDelete: (CalculationHistory) -> Void
    
    @Environment(\.dismiss) private var dismiss
    @State private var selectedCalculation: CalculationHistory?
    @State private var showingDetail = false
    
    var body: some View {
        NavigationStack {
            List {
                ForEach(history) { calculation in
                    HistoryRowView(calculation: calculation)
                        .contentShape(Rectangle())
                        .onTapGesture {
                            selectedCalculation = calculation
                            showingDetail = true
                        }
                        .swipeActions {
                            Button(role: .destructive) {
                                onDelete(calculation)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                        }
                }
            }
            .navigationTitle("Calculation History")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingDetail) {
                if let calculation = selectedCalculation {
                    HistoryDetailView(calculation: calculation)
                }
            }
            .overlay {
                if history.isEmpty {
                    ContentUnavailableView(
                        "No History",
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Save calculations to see them here.")
                    )
                }
            }
        }
    }
}

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
