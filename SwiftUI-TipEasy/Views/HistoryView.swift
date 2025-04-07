//
//  HistoryView.swift
//  SwiftUI-TipEasy
//
//  Created by Chirag Kular on 4/5/25.
//
import Charts
import Foundation
import SwiftData
import SwiftUI

struct HistoryView: View {
    @Query private var history: [CalculationHistory]
    @State private var selectedTimeframe: Timeframe = .all
    
    enum Timeframe {
        case all, year, ytd, month
    }
    
    private var groupedHistory: [(String, [CalculationHistory])] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        
        let filtered = history.filter { calculation in
            switch selectedTimeframe {
            case .all: return true
            case .year:
                return Calendar.current.isDate(calculation.timestamp, equalTo: Date(), toGranularity: .year)
            case .ytd:
                return calculation.timestamp <= Date() &&
                    Calendar.current.isDate(calculation.timestamp, equalTo: Date(), toGranularity: .year)
            case .month:
                return Calendar.current.isDate(calculation.timestamp, equalTo: Date(), toGranularity: .month)
            }
        }
        
        let grouped = Dictionary(grouping: filtered) { formatter.string(from: $0.timestamp) }
        return grouped.sorted { $0.key > $1.key }
    }
    
    var body: some View {
        VStack {
            Picker("Timeframe", selection: $selectedTimeframe) {
                Text("All").tag(Timeframe.all)
                Text("This Year").tag(Timeframe.year)
                Text("YTD").tag(Timeframe.ytd)
                Text("This Month").tag(Timeframe.month)
            }
            .pickerStyle(.segmented)
            .padding()
            
            List {
                ForEach(groupedHistory, id: \.0) { month, transactions in
                    Section(header: MonthSectionHeader(month: month, transactions: transactions)) {
                        ForEach(transactions, id: \.timestamp) { transaction in
                            TransactionRow(transaction: transaction)
                        }
                    }
                }
            }
            
            if !history.isEmpty {
                Chart {
                    ForEach(groupedHistory, id: \.0) { month, transactions in
                        BarMark(
                            x: .value("Month", month),
                            y: .value("Total", transactions.reduce(0) { $0 + $1.totalAmount })
                        )
                    }
                }
                .frame(height: 200)
                .padding()
            }
        }
    }
}

struct MonthSectionHeader: View {
    let month: String
    let transactions: [CalculationHistory]
    
    var total: Double {
        transactions.reduce(0) { $0 + $1.totalAmount }
    }
    
    var body: some View {
        HStack {
            Text(month)
            Spacer()
            Text("Total: $\(total, specifier: "%.2f")")
                .font(.subheadline)
        }
    }
}

struct TransactionRow: View {
    let transaction: CalculationHistory
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("$\(transaction.billAmount, specifier: "%.2f")")
                    .font(.headline)
                Spacer()
                Text(transaction.timestamp, style: .date)
                    .font(.subheadline)
            }
            
            HStack {
                Text("Tip: $\(transaction.tipAmount, specifier: "%.2f")")
                Text("(\(Int(transaction.tipPercentage * 100))%)")
                Spacer()
                if let location = transaction.location {
                    Text(location)
                        .font(.caption)
                }
            }
            
            if let photoData = transaction.photo,
               let uiImage = UIImage(data: photoData)
            {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .frame(height: 100)
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: CalculationHistory.self, configurations: config)

    // Insert sample data
    let context = container.mainContext
    CalculationHistory.sampleTransactions.forEach { context.insert($0) }

    return HistoryView()
        .modelContainer(container)
}
