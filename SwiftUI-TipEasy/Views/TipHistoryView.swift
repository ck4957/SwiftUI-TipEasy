import SwiftData
import SwiftUI

struct TipHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appPalette) private var palette
    @Query(sort: \TipTransaction.date, order: .reverse) private var transactions: [TipTransaction]
    @State private var searchText = ""

    private let currencyCode = Locale.current.currency?.identifier ?? "USD"

    private var visibleTransactions: [TipTransaction] {
        HistorySearchService.filter(transactions, query: searchText)
    }

    private var totalSpent: Double {
        visibleTransactions.reduce(0) { $0 + $1.totalAmount }
    }

    private var totalTips: Double {
        visibleTransactions.reduce(0) { $0 + $1.tipAmount }
    }

    private var ytdTips: Double {
        visibleTransactions
            .filter { Calendar.current.isDate($0.date, equalTo: .now, toGranularity: .year) }
            .reduce(0) { $0 + $1.tipAmount }
    }

    private var monthlyGroups: [(month: Date, items: [TipTransaction])] {
        let grouped = Dictionary(grouping: visibleTransactions) { transaction in
            Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: transaction.date)) ?? transaction.date
        }
        return grouped
            .map { (month: $0.key, items: $0.value.sorted { $0.date > $1.date }) }
            .sorted { $0.month > $1.month }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .spacingLarge) {
                summaryCards
                if let summary = TipIntelligenceService.summary(for: visibleTransactions, currencyCode: currencyCode) {
                    MonthlySummaryCard(summary: summary)
                }

                if visibleTransactions.isEmpty {
                    ContentUnavailableView(
                        searchText.isEmpty ? "No Saved Tips" : "No Matches",
                        systemImage: searchText.isEmpty ? "tray" : "magnifyingglass",
                        description: Text(searchText.isEmpty ? "Saved calculations will appear here by month." : "Try a query like this month, over 20%, or a restaurant name.")
                    )
                    .frame(maxWidth: .infinity)
                    .padding(.top, 60)
                } else {
                    historyList
                }
            }
            .padding()
        }
        .background(
            LinearGradient(
                colors: [
                    palette.backgroundTop,
                    palette.backgroundBottom
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
        .navigationTitle("History")
        .searchable(text: $searchText, prompt: "Try: this month, over 20%, coffee")
    }

    private var summaryCards: some View {
        VStack(alignment: .leading, spacing: .spacingMedium) {
            Label("Local Totals", systemImage: "chart.bar.xaxis")
                .font(.headline)

            HStack(spacing: .spacingMedium) {
                HistoryMetric(title: "Spent", value: totalSpent, currencyCode: currencyCode)
                HistoryMetric(title: "Tips", value: totalTips, currencyCode: currencyCode)
                HistoryMetric(title: "YTD", value: ytdTips, currencyCode: currencyCode)
            }
        }
        .historyGlassCard(palette: palette)
    }

    private var historyList: some View {
        VStack(alignment: .leading, spacing: .spacingLarge) {
            ForEach(monthlyGroups, id: \.month) { group in
                VStack(alignment: .leading, spacing: .spacingMedium) {
                    Text(group.month, format: .dateTime.month(.wide).year())
                        .font(.title3.weight(.semibold))

                    VStack(spacing: 10) {
                        ForEach(group.items) { transaction in
                            TipHistoryRow(transaction: transaction, currencyCode: currencyCode) {
                                withAnimation {
                                    modelContext.delete(transaction)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

private struct MonthlySummaryCard: View {
    @Environment(\.appPalette) private var palette
    let summary: HistorySummary

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingMedium) {
            Label(summary.title, systemImage: "sparkles")
                .font(.headline)

            Text(summary.message)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 10)], spacing: 10) {
                ForEach(summary.highlights, id: \.self) { highlight in
                    Text(highlight)
                        .font(.caption.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .padding(.horizontal, 12)
                        .background(palette.tile, in: RoundedRectangle(cornerRadius: 14))
                }
            }
        }
        .historyGlassCard(palette: palette)
    }
}

private struct HistoryMetric: View {
    @Environment(\.appPalette) private var palette

    let title: String
    let value: Double
    let currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value, format: .currency(code: currencyCode))
                .font(.headline.weight(.bold))
                .fontDesign(.rounded)
                .lineLimit(1)
                .minimumScaleFactor(0.65)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.tile, in: RoundedRectangle(cornerRadius: 16))
    }
}

private struct TipHistoryRow: View {
    @Environment(\.appPalette) private var palette

    let transaction: TipTransaction
    let currencyCode: String
    let onDelete: () -> Void

    private var title: String {
        transaction.restaurantName.isEmpty ? "Saved bill" : transaction.restaurantName
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "fork.knife.circle.fill")
                .font(.title2)
                .foregroundStyle(palette.accent)
                .symbolRenderingMode(.hierarchical)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                Text(transaction.date, format: .dateTime.weekday(.abbreviated).day().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(transaction.totalAmount, format: .currency(code: currencyCode))
                    .font(.headline.weight(.semibold))
                Text("\(Int(transaction.tipPercentage * 100))% tip")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(palette.card, in: RoundedRectangle(cornerRadius: 18))
        .glassEffect(.regular.tint(palette.glassTint).interactive(), in: .rect(cornerRadius: 18))
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

private extension View {
    func historyGlassCard(palette: ThemePalette) -> some View {
        self
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(palette.card, in: RoundedRectangle(cornerRadius: .cornerRadiusLarge))
            .glassEffect(.regular.tint(palette.glassTint), in: .rect(cornerRadius: .cornerRadiusLarge))
    }
}

#Preview {
    NavigationStack {
        TipHistoryView()
    }
    .modelContainer(for: [TipPreset.self, TipTransaction.self], inMemory: true)
}
