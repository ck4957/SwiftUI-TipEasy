import Charts
import MapKit
import SwiftData
import SwiftUI
import UIKit

struct TipHistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appPalette) private var palette
    @Environment(PurchaseManager.self) private var purchaseManager
    @Query(sort: \TipTransaction.date, order: .reverse) private var transactions: [TipTransaction]
    @State private var searchText = ""
    @State private var selectedReceiptPhoto: ReceiptPhotoPreview?
    @State private var selectedTransaction: TipTransaction?
    @State private var proUpgradeRequest: ProUpgradeRequest?

    private let currencyCode = Locale.current.currency?.identifier ?? "USD"

    private var visibleTransactions: [TipTransaction] {
        let source = purchaseManager.isProUnlocked ? transactions : Array(transactions.prefix(ProFeatureCopy.freeHistoryLimit))
        return HistorySearchService.filter(source, query: searchText)
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
                if !purchaseManager.isProUnlocked {
                    proHistoryCard
                }
                if purchaseManager.isProUnlocked && !visibleTransactions.isEmpty {
                    chartsSection
                }
                if purchaseManager.isProUnlocked,
                   let summary = TipIntelligenceService.summary(for: visibleTransactions, currencyCode: currencyCode) {
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
        .sheet(item: $selectedReceiptPhoto) { preview in
            ReceiptPhotoPreviewSheet(preview: preview)
        }
        .sheet(item: $selectedTransaction) { transaction in
            TipHistoryDetailSheet(transaction: transaction, currencyCode: currencyCode) {
                if let image = ReceiptPhotoStore.image(named: transaction.receiptPhotoFilename) {
                    selectedReceiptPhoto = ReceiptPhotoPreview(
                        title: transaction.restaurantName.isEmpty ? "Receipt Photo" : transaction.restaurantName,
                        image: image
                    )
                }
            }
        }
        .sheet(item: $proUpgradeRequest) { request in
            ProUpgradeView(source: request.source)
        }
    }

    private var summaryCards: some View {
        VStack(alignment: .leading, spacing: .spacingMedium) {
            Label(purchaseManager.isProUnlocked ? "Local Totals" : "Recent Totals", systemImage: "chart.bar.xaxis")
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

    private var proHistoryCard: some View {
        VStack(alignment: .leading, spacing: .spacingMedium) {
            HStack(alignment: .top, spacing: .spacingMedium) {
                Image(systemName: "chart.xyaxis.line")
                    .font(.title2)
                    .foregroundStyle(palette.highlight)
                    .frame(width: 42, height: 42)
                    .background(palette.selectedTile, in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("Unlock full history")
                        .font(.headline)
                    Text("Free keeps your latest \(ProFeatureCopy.freeHistoryLimit) saved tips. Pro adds unlimited history, charts, summaries, and search.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Button {
                showProUpgrade(source: "history")
            } label: {
                Label("View Pro", systemImage: "crown")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
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
                                selectedTransaction = transaction
                            } onShowReceipt: {
                                if let image = ReceiptPhotoStore.image(named: transaction.receiptPhotoFilename) {
                                    selectedReceiptPhoto = ReceiptPhotoPreview(
                                        title: transaction.restaurantName.isEmpty ? "Receipt Photo" : transaction.restaurantName,
                                        image: image
                                    )
                                }
                            } onDelete: {
                                ReceiptPhotoStore.delete(filename: transaction.receiptPhotoFilename)
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

    private func showProUpgrade(source: String) {
        AnalyticsService.track(.proGateTapped, properties: ["source": source])
        proUpgradeRequest = ProUpgradeRequest(source: source)
    }
}

private struct ProUpgradeRequest: Identifiable {
    let source: String
    var id: String { source }
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
    let onShowDetails: () -> Void
    let onShowReceipt: () -> Void
    let onDelete: () -> Void

    private var title: String {
        transaction.restaurantName.isEmpty ? "Saved bill" : transaction.restaurantName
    }

    private var receiptImage: UIImage? {
        ReceiptPhotoStore.image(named: transaction.receiptPhotoFilename)
    }

    var body: some View {
        HStack(spacing: 12) {
            if let receiptImage {
                Button(action: onShowReceipt) {
                    Image(uiImage: receiptImage)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 46, height: 46)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(palette.stroke, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("View original receipt photo")
            } else {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.title2)
                    .foregroundStyle(palette.accent)
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.headline)
                    .lineLimit(1)
                Text(transaction.date, format: .dateTime.weekday(.abbreviated).day().hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if transaction.hasLocation {
                    Label(transaction.locationDisplayName, systemImage: "mappin.and.ellipse")
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
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
        .contentShape(RoundedRectangle(cornerRadius: 18))
        .onTapGesture(perform: onShowDetails)
        .contextMenu {
            Button {
                onShowDetails()
            } label: {
                Label("View Details", systemImage: "info.circle")
            }

            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

private struct TipHistoryDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appPalette) private var palette

    let transaction: TipTransaction
    let currencyCode: String
    let onShowReceipt: () -> Void

    private var title: String {
        transaction.restaurantName.isEmpty ? "Saved bill" : transaction.restaurantName
    }

    private var receiptImage: UIImage? {
        ReceiptPhotoStore.image(named: transaction.receiptPhotoFilename)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: .spacingLarge) {
                    receiptHeader
                    detailGrid
                    locationPreview
                }
                .padding()
            }
            .background(
                LinearGradient(
                    colors: [palette.backgroundTop, palette.backgroundBottom],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()
            )
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private var receiptHeader: some View {
        VStack(alignment: .leading, spacing: .spacingMedium) {
            if let receiptImage {
                Button(action: onShowReceipt) {
                    Image(uiImage: receiptImage)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 210)
                        .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusLarge))
                        .overlay {
                            RoundedRectangle(cornerRadius: .cornerRadiusLarge)
                                .strokeBorder(palette.stroke, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .accessibilityLabel("View original receipt photo")
            } else {
                Image(systemName: "fork.knife.circle.fill")
                    .font(.system(size: 52))
                    .foregroundStyle(palette.accent)
                    .symbolRenderingMode(.hierarchical)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title2.weight(.bold))
                Text(transaction.date, format: .dateTime.weekday(.wide).month().day().year().hour().minute())
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .historyGlassCard(palette: palette)
    }

    private var detailGrid: some View {
        LazyVGrid(columns: [GridItem(.adaptive(minimum: 132), spacing: 10)], spacing: 10) {
            TipDetailTile(title: "Tip Amount", value: transaction.tipAmount.formatted(.currency(code: currencyCode)))
            TipDetailTile(title: "Tip", value: transaction.tipPercentage.formatted(.percent.precision(.fractionLength(0))))
            TipDetailTile(title: "Total Bill", value: transaction.totalAmount.formatted(.currency(code: currencyCode)))
            TipDetailTile(title: "Initial Total", value: transaction.billAmount.formatted(.currency(code: currencyCode)))
            TipDetailTile(title: "Place", value: title)
            TipDetailTile(title: "Location", value: transaction.hasLocation ? transaction.locationDisplayName : "Not saved")
        }
        .historyGlassCard(palette: palette)
    }

    @ViewBuilder
    private var locationPreview: some View {
        if let coordinate = transaction.locationCoordinate {
            VStack(alignment: .leading, spacing: .spacingMedium) {
                Label(transaction.locationDisplayName, systemImage: "mappin.and.ellipse")
                    .font(.headline)

                Button {
                    openInAppleMaps(coordinate)
                } label: {
                    ZStack(alignment: .bottom) {
                        Map(initialPosition: .region(transaction.mapRegion)) {
                            Marker(transaction.locationDisplayName, coordinate: coordinate)
                        }
                        .mapControlVisibility(.hidden)
                        .allowsHitTesting(false)

                        HStack(spacing: 8) {
                            Image(systemName: "map")
                                .imageScale(.medium)
                            Text("Open in Apple Maps")
                                .font(.subheadline.weight(.semibold))
                            Spacer(minLength: 8)
                            Image(systemName: "arrow.up.forward.app")
                                .imageScale(.medium)
                        }
                        .foregroundStyle(.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity)
                        .background(.regularMaterial)
                    }
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: .cornerRadiusLarge))
                    .overlay {
                        RoundedRectangle(cornerRadius: .cornerRadiusLarge)
                            .strokeBorder(palette.stroke, lineWidth: 1)
                    }
                    .contentShape(RoundedRectangle(cornerRadius: .cornerRadiusLarge))
                }
                .buttonStyle(.plain)
                .contentShape(RoundedRectangle(cornerRadius: .cornerRadiusLarge))
                .accessibilityLabel("Open saved tip location in Apple Maps")
                .accessibilityHint("Opens Apple Maps to this saved location.")
            }
            .historyGlassCard(palette: palette)
        }
    }

    private func openInAppleMaps(_ coordinate: CLLocationCoordinate2D) {
        let location = CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)
        let mapItem = MKMapItem(location: location, address: nil)
        mapItem.name = transaction.locationDisplayName
        mapItem.openInMaps(launchOptions: [
            MKLaunchOptionsMapCenterKey: NSValue(mkCoordinate: coordinate),
            MKLaunchOptionsMapSpanKey: NSValue(mkCoordinateSpan: transaction.mapRegion.span)
        ])
    }
}

private struct TipDetailTile: View {
    @Environment(\.appPalette) private var palette

    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.headline.weight(.semibold))
                .lineLimit(2)
                .minimumScaleFactor(0.72)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 72, alignment: .leading)
        .background(palette.tile, in: RoundedRectangle(cornerRadius: 14))
    }
}

private struct ReceiptPhotoPreview: Identifiable {
    let id = UUID()
    let title: String
    let image: UIImage
}

private struct ReceiptPhotoPreviewSheet: View {
    @Environment(\.dismiss) private var dismiss
    let preview: ReceiptPhotoPreview

    var body: some View {
        NavigationStack {
            GeometryReader { proxy in
                Image(uiImage: preview.image)
                    .resizable()
                    .scaledToFit()
                    .frame(width: proxy.size.width, height: proxy.size.height)
            }
            .background(Color.black.opacity(0.92))
            .navigationTitle(preview.title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
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

private extension TipTransaction {
    var hasLocation: Bool {
        locationLatitude != nil && locationLongitude != nil
    }

    var locationCoordinate: CLLocationCoordinate2D? {
        guard let locationLatitude, let locationLongitude else { return nil }
        return CLLocationCoordinate2D(latitude: locationLatitude, longitude: locationLongitude)
    }

    var locationDisplayName: String {
        if let locationName, !locationName.isEmpty {
            return locationName
        }

        let components = [locationLocality, locationAdministrativeArea]
            .compactMap { $0?.isEmpty == false ? $0 : nil }
        return components.isEmpty ? "Saved location" : components.joined(separator: ", ")
    }

    var mapRegion: MKCoordinateRegion {
        MKCoordinateRegion(
            center: locationCoordinate ?? CLLocationCoordinate2D(latitude: 0, longitude: 0),
            span: MKCoordinateSpan(latitudeDelta: 0.008, longitudeDelta: 0.008)
        )
    }
}

#Preview {
    NavigationStack {
        TipHistoryView()
    }
    .modelContainer(for: [TipPreset.self, TipTransaction.self], inMemory: true)
    .environment(PurchaseManager())
}
