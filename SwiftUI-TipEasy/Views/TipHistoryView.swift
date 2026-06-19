import Charts
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

    private var monthlyChartData: [MonthlyTipChartPoint] {
        monthlyGroups
            .map { group in
                MonthlyTipChartPoint(
                    month: group.month,
                    totalSpent: group.items.reduce(0) { $0 + $1.totalAmount },
                    totalTips: group.items.reduce(0) { $0 + $1.tipAmount }
                )
            }
            .sorted { $0.month < $1.month }
    }

    private var tipDistributionData: [TipDistributionPoint] {
        let buckets = TipDistributionBucket.allCases.map { bucket in
            TipDistributionPoint(
                bucket: bucket,
                count: visibleTransactions.filter { bucket.contains($0.tipPercentage) }.count
            )
        }

        return buckets.filter { $0.count > 0 }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .spacingLarge) {
                summaryCards
                if !visibleTransactions.isEmpty {
                    chartsSection
                }
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

    private var chartsSection: some View {
        VStack(spacing: .spacingLarge) {
            MonthlyTrendChartCard(data: monthlyChartData, currencyCode: currencyCode)
            TipDistributionChartCard(data: tipDistributionData)
        }
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

private struct MonthlyTrendChartCard: View {
    @Environment(\.appPalette) private var palette

    let data: [MonthlyTipChartPoint]
    let currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingMedium) {
            Label("Monthly Flow", systemImage: "chart.xyaxis.line")
                .font(.headline)

            Chart(data) { point in
                BarMark(
                    x: .value("Month", point.month, unit: .month),
                    y: .value("Spent", point.totalSpent)
                )
                .foregroundStyle(palette.accent.gradient)
                .accessibilityLabel(monthLabel(for: point.month))
                .accessibilityValue(point.totalSpent.formatted(.currency(code: currencyCode)))

                LineMark(
                    x: .value("Month", point.month, unit: .month),
                    y: .value("Tips", point.totalTips)
                )
                .foregroundStyle(palette.highlight)
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .symbol {
                    Circle()
                        .fill(palette.highlight)
                        .frame(width: 8, height: 8)
                }
                .accessibilityLabel("Tips")
                .accessibilityValue(point.totalTips.formatted(.currency(code: currencyCode)))
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine()
                    AxisTick()
                    AxisValueLabel(format: .dateTime.month(.abbreviated))
                }
            }
            .chartYAxis {
                AxisMarks(values: .automatic(desiredCount: 3))
            }
            .chartLegend(.hidden)
            .frame(height: 210)

            HStack(spacing: .spacingMedium) {
                ChartLegendItem(color: palette.accent, title: "Spent")
                ChartLegendItem(color: palette.highlight, title: "Tips")
                Spacer()
            }
        }
        .historyGlassCard(palette: palette)
    }

    private func monthLabel(for date: Date) -> String {
        date.formatted(.dateTime.month(.wide).year())
    }
}

private struct TipDistributionChartCard: View {
    @Environment(\.appPalette) private var palette

    let data: [TipDistributionPoint]

    var body: some View {
        VStack(alignment: .leading, spacing: .spacingMedium) {
            Label("Tip Mix", systemImage: "percent")
                .font(.headline)

            Chart(data) { point in
                BarMark(
                    x: .value("Tips", point.count),
                    y: .value("Range", point.bucket.title)
                )
                .foregroundStyle(palette.secondaryAccent.gradient)
                .clipShape(RoundedRectangle(cornerRadius: 5))
                .annotation(position: .trailing) {
                    Text(point.count, format: .number)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                }
                .accessibilityLabel(point.bucket.accessibilityTitle)
                .accessibilityValue("\(point.count) saved tips")
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 3))
            }
            .chartYAxis {
                AxisMarks { _ in
                    AxisValueLabel()
                }
            }
            .frame(height: max(140, CGFloat(data.count) * 42))
        }
        .historyGlassCard(palette: palette)
    }
}

private struct ChartLegendItem: View {
    let color: Color
    let title: String

    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
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

private struct MonthlyTipChartPoint: Identifiable {
    let month: Date
    let totalSpent: Double
    let totalTips: Double

    var id: Date { month }
}

private struct TipDistributionPoint: Identifiable {
    let bucket: TipDistributionBucket
    let count: Int

    var id: TipDistributionBucket { bucket }
}

private enum TipDistributionBucket: CaseIterable {
    case under15
    case fifteen
    case sixteenToEighteen
    case nineteenToTwenty
    case twentyOneToTwentyFive
    case over25

    var title: String {
        switch self {
        case .under15:
            "<15%"
        case .fifteen:
            "15%"
        case .sixteenToEighteen:
            "16-18%"
        case .nineteenToTwenty:
            "19-20%"
        case .twentyOneToTwentyFive:
            "21-25%"
        case .over25:
            ">25%"
        }
    }

    var accessibilityTitle: String {
        switch self {
        case .under15:
            "Under 15 percent"
        case .fifteen:
            "15 percent"
        case .sixteenToEighteen:
            "16 to 18 percent"
        case .nineteenToTwenty:
            "19 to 20 percent"
        case .twentyOneToTwentyFive:
            "21 to 25 percent"
        case .over25:
            "Over 25 percent"
        }
    }

    func contains(_ percentage: Double) -> Bool {
        let wholePercent = Int((percentage * 100).rounded())

        switch self {
        case .under15:
            return wholePercent < 15
        case .fifteen:
            return wholePercent == 15
        case .sixteenToEighteen:
            return (16...18).contains(wholePercent)
        case .nineteenToTwenty:
            return (19...20).contains(wholePercent)
        case .twentyOneToTwentyFive:
            return (21...25).contains(wholePercent)
        case .over25:
            return wholePercent > 25
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
