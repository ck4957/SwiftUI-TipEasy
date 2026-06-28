import SwiftUI

enum ProFeatureCopy {
    static let freeHistoryLimit = 3

    static let unlockedFeatures = [
        "Unlimited saved history",
        "Receipt scanning",
        "Smart Check insights",
        "Custom tip presets",
        "History charts and summaries"
    ]
}

struct ProUpgradeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.appPalette) private var palette
    @Environment(PurchaseManager.self) private var purchaseManager

    let source: String
    @State private var isPurchasing = false
    @State private var isRestoring = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: .spacingLarge) {
                    headerCard
                    featuresCard
                    purchaseCard
                }
                .padding()
            }
            .background(backgroundGradient)
            .navigationTitle("Scan Tip Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .tint(palette.accent)
        .onAppear {
            AnalyticsService.track(.proPaywallViewed, properties: ["source": source])
        }
        .alert("Purchase Issue", isPresented: purchaseErrorPresentation) {
            Button("OK") {
                purchaseManager.clearPurchaseError()
            }
        } message: {
            Text(purchaseManager.purchaseError ?? "Please try again.")
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: .spacingMedium) {
            Image(systemName: "crown.fill")
                .font(.largeTitle)
                .foregroundStyle(palette.highlight)
                .frame(width: 64, height: 64)
                .background(palette.selectedTile, in: Circle())
                .glassEffect(.regular.tint(palette.highlight.opacity(0.14)), in: .circle)

            VStack(alignment: .leading, spacing: 8) {
                Text("Unlock the full tip toolkit.")
                    .font(.largeTitle.weight(.bold))
                    .fontDesign(.rounded)
                    .fixedSize(horizontal: false, vertical: true)

                    Text("Keep the calculator free. Upgrade once for scanning, deeper history, custom presets, and Smart Check.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .proGlassCard(palette: palette)
    }

    private var featuresCard: some View {
        VStack(alignment: .leading, spacing: .spacingMedium) {
            Label("Included with Pro", systemImage: "checkmark.seal")
                .font(.headline)

            ForEach(ProFeatureCopy.unlockedFeatures, id: \.self) { feature in
                Label(feature, systemImage: "checkmark.circle.fill")
                    .font(.subheadline.weight(.medium))
                    .foregroundStyle(.primary)
                    .labelStyle(.titleAndIcon)
            }
        }
        .proGlassCard(palette: palette)
    }

    private var purchaseCard: some View {
        VStack(alignment: .leading, spacing: .spacingMedium) {
            VStack(alignment: .leading, spacing: 4) {
                Text("One-time Pro unlock")
                    .font(.headline)
                Text(purchaseManager.proPriceText)
                    .font(.title2.weight(.bold))
                    .fontDesign(.rounded)
                    .foregroundStyle(palette.accent)
            }

            Button {
                Task {
                    isPurchasing = true
                    await purchaseManager.buyPro()
                    isPurchasing = false

                    if purchaseManager.isProUnlocked {
                        dismiss()
                    }
                }
            } label: {
                Label(isPurchasing ? "Purchasing" : "Unlock Pro", systemImage: "crown")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glassProminent)
            .disabled(isPurchasing || isRestoring || purchaseManager.isLoadingProducts)

            Button {
                Task {
                    isRestoring = true
                    await purchaseManager.restorePurchases()
                    isRestoring = false

                    if purchaseManager.isProUnlocked {
                        dismiss()
                    }
                }
            } label: {
                Label(isRestoring ? "Restoring" : "Restore Purchase", systemImage: "arrow.clockwise")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
            .disabled(isPurchasing || isRestoring)

            #if DEBUG
            Button {
                purchaseManager.unlockPreviewPro()
                dismiss()
            } label: {
                Label("Unlock Preview Pro", systemImage: "hammer")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
            #endif
        }
        .proGlassCard(palette: palette)
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                palette.backgroundTop,
                palette.backgroundMid,
                palette.backgroundBottom
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
        .ignoresSafeArea()
    }

    private var purchaseErrorPresentation: Binding<Bool> {
        Binding {
            purchaseManager.purchaseError != nil
        } set: { isPresented in
            if !isPresented {
                purchaseManager.clearPurchaseError()
            }
        }
    }
}

private extension View {
    func proGlassCard(palette: ThemePalette) -> some View {
        self
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(palette.card, in: RoundedRectangle(cornerRadius: .cornerRadiusLarge))
            .glassEffect(.regular.tint(palette.glassTint), in: .rect(cornerRadius: .cornerRadiusLarge))
    }
}

#Preview {
    ProUpgradeView(source: "preview")
        .environment(\.appTheme, .standard)
        .environment(PurchaseManager())
}
