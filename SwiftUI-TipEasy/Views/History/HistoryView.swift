import Charts
import SwiftUI

struct HistoryView: View {
    let history: [CalculationHistory]
    let onDelete: (CalculationHistory) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var selectedCalculation: CalculationHistory?
    @State private var showingDetail = false
    @State private var selectedPeriod: SpendingChartPeriod = .monthly
    var body: some View {
        NavigationStack {
            VStack {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Spending Overview")
                        .font(.headline)
                        .padding(.leading, 8)

                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(SpendingChartPeriod.allCases) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal, 8)

                    Chart(selectedSummary) {
                        LineMark(
                            x: .value(selectedPeriodLabel, $0.period),
                            y: .value("Total", $0.total)
                        )
                        .interpolationMethod(.catmullRom)
                        AreaMark(
                            x: .value(selectedPeriodLabel, $0.period),
                            y: .value("Total", $0.total)
                        )
                        .foregroundStyle(.blue.opacity(0.18))
                        PointMark(
                            x: .value(selectedPeriodLabel, $0.period),
                            y: .value("Total", $0.total)
                        )
                    }
                    .frame(height: 160)
                    .padding(.horizontal, 8)
                }
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
            }
            .navigationTitle("Tip History")
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

    private var selectedSummary: [SpendingSummary] {
        switch selectedPeriod {
        case .monthly: return monthlySummary
        case .quarterly: return quarterlySummary
        case .yearly: return yearlySummary
        }
    }

    private var selectedPeriodLabel: String {
        switch selectedPeriod {
        case .monthly: return "Month"
        case .quarterly: return "Quarter"
        case .yearly: return "Year"
        }
    }
}

#Preview {
    HistoryView(history: CalculationHistory.sampleTransactions, onDelete: { _ in })
        .preferredColorScheme(.light)
}

extension HistoryView {
    private var monthlySummary: [SpendingSummary] {
        let grouped = Dictionary(grouping: history) { calculation in
            let comps = Calendar.current.dateComponents([.year, .month], from: calculation.timestamp)
            return "\(comps.year!)-\(String(format: "%02d", comps.month!))"
        }
        return grouped.map { key, values in
            SpendingSummary(period: key, total: values.reduce(0) { $0 + $1.totalAmount })
        }
        .sorted { $0.period < $1.period }
    }

    private var quarterlySummary: [SpendingSummary] {
        let grouped = Dictionary(grouping: history) { calculation in
            let comps = Calendar.current.dateComponents([.year, .month], from: calculation.timestamp)
            let quarter = ((comps.month! - 1) / 3) + 1
            return "\(comps.year!)-Q\(quarter)"
        }
        return grouped.map { key, values in
            SpendingSummary(period: key, total: values.reduce(0) { $0 + $1.totalAmount })
        }
        .sorted { $0.period < $1.period }
    }

    private var yearlySummary: [SpendingSummary] {
        let grouped = Dictionary(grouping: history) { calculation in
            let comps = Calendar.current.dateComponents([.year], from: calculation.timestamp)
            return "\(comps.year!)"
        }
        return grouped.map { key, values in
            SpendingSummary(period: key, total: values.reduce(0) { $0 + $1.totalAmount })
        }
        .sorted { $0.period < $1.period }
    }
}
