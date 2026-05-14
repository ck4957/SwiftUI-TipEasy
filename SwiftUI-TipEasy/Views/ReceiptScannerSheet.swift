import SwiftUI
import VisionKit

struct ReceiptScannerSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appPalette) private var palette
    @State private var recognizedText = ""
    @State private var scanResult = ReceiptScanResult.empty
    @State private var isAnalyzing = false

    let onDetectedResult: (ReceiptScanResult) -> Void
    private let currencyCode = Locale.current.currency?.identifier ?? "USD"
    private let commonTips = [0.15, 0.18, 0.20, 0.25]

    private var detectedTotal: Double? {
        scanResult.total
    }

    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottom) {
                if DataScannerViewController.isSupported, DataScannerViewController.isAvailable {
                    ReceiptDataScannerView(recognizedText: $recognizedText)
                        .ignoresSafeArea()
                } else {
                    ContentUnavailableView(
                        "Receipt Scanner Unavailable",
                        systemImage: "camera.viewfinder",
                        description: Text("Use a device with camera text recognition, or enter the bill manually.")
                    )
                }

                scannerOverlay
            }
            .navigationTitle("Scan Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .task(id: recognizedText) {
                await analyzeRecognizedText()
            }
        }
    }

    private var scannerOverlay: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Detected total")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline) {
                Text(detectedTotal ?? 0, format: .currency(code: currencyCode))
                    .font(.largeTitle.weight(.bold))
                    .fontDesign(.rounded)
                    .contentTransition(.numericText())
                Spacer()
                Button {
                    if detectedTotal != nil {
                        onDetectedResult(scanResult)
                    }
                } label: {
                    Label("Use", systemImage: "checkmark")
                }
                .buttonStyle(.glassProminent)
                .disabled(detectedTotal == nil)
            }

            if !scanResult.merchantName.isEmpty {
                Label(scanResult.merchantName, systemImage: "fork.knife")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            if let detectedTotal {
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 92), spacing: 8)], spacing: 8) {
                    ForEach(commonTips, id: \.self) { tip in
                        ScannerTipTile(
                            percentage: tip,
                            bill: detectedTotal,
                            currencyCode: currencyCode
                        )
                    }
                }
            }

            Text(isAnalyzing ? "Reading receipt details..." : scanResult.usedAppleIntelligence ? "Apple Intelligence refined the receipt details on device." : "Point the camera at the receipt total. Tip Easy also looks for service charges and merchant names.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.card, in: RoundedRectangle(cornerRadius: 22))
        .glassEffect(.regular.tint(palette.glassTint), in: .rect(cornerRadius: 22))
        .padding()
    }

    private func analyzeRecognizedText() async {
        guard !recognizedText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }

        isAnalyzing = true
        let result = await ReceiptIntelligenceService.analyzeReceiptText(recognizedText)
        await MainActor.run {
            scanResult = result
            isAnalyzing = false
        }
    }
}

private struct ScannerTipTile: View {
    @Environment(\.appPalette) private var palette

    let percentage: Double
    let bill: Double
    let currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("\(Int(percentage * 100))%")
                .font(.caption.weight(.bold))
                .foregroundStyle(.secondary)
            Text(bill * percentage, format: .currency(code: currencyCode))
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.72)
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(palette.tile, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct ReceiptDataScannerView: UIViewControllerRepresentable {
    @Binding var recognizedText: String

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let scanner = DataScannerViewController(
            recognizedDataTypes: [.text()],
            qualityLevel: .balanced,
            recognizesMultipleItems: true,
            isHighFrameRateTrackingEnabled: false,
            isPinchToZoomEnabled: true,
            isGuidanceEnabled: true,
            isHighlightingEnabled: true
        )
        scanner.delegate = context.coordinator
        return scanner
    }

    func updateUIViewController(_ scanner: DataScannerViewController, context: Context) {
        guard !scanner.isScanning else { return }
        try? scanner.startScanning()
    }

    static func dismantleUIViewController(_ scanner: DataScannerViewController, coordinator: Coordinator) {
        scanner.stopScanning()
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(recognizedText: $recognizedText)
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        @Binding private var recognizedText: String

        init(recognizedText: Binding<String>) {
            _recognizedText = recognizedText
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didAdd addedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            updateDetectedTotal(from: allItems)
        }

        func dataScanner(_ dataScanner: DataScannerViewController, didUpdate updatedItems: [RecognizedItem], allItems: [RecognizedItem]) {
            updateDetectedTotal(from: allItems)
        }

        private func updateDetectedTotal(from items: [RecognizedItem]) {
            let text = items.compactMap { item -> String? in
                if case let .text(recognizedText) = item {
                    return recognizedText.transcript
                }
                return nil
            }
            .joined(separator: "\n")

            Task { @MainActor in
                recognizedText = text
            }
        }
    }
}
