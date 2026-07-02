import SwiftData
import SwiftUI

struct TipPresetSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appPalette) private var palette
    @Environment(PurchaseManager.self) private var purchaseManager
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage(TipPresetCatalog.hiddenDefaultPresetsKey) private var hiddenDefaultPresetStorage = ""
    @Query(sort: \TipPreset.percentage) private var tipPresets: [TipPreset]
    @Query private var transactions: [TipTransaction]

    @State private var showingPresetManager = false
    @State private var showingDeleteDataConfirmation = false
    @State private var dataDeletionError: String?
    @State private var proUpgradeRequest: ProUpgradeRequest?

    private var storedItemCount: Int {
        tipPresets.count + transactions.count + TipPresetCatalog.hiddenDefaultBasisPoints(from: hiddenDefaultPresetStorage).count
    }

    private var activePresetValues: [Double] {
        TipPresetCatalog.activePercentages(
            customPercentages: tipPresets.map(\.percentage),
            hiddenDefaultStorage: hiddenDefaultPresetStorage
        )
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .spacingLarge) {
                guideCard
                proCard
                presetCard
                privacyCard
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
        .tint(palette.accent)
        .navigationTitle("Settings")
        .sheet(isPresented: $showingPresetManager) {
            PresetManagementSheet()
        }
        .sheet(item: $proUpgradeRequest) { request in
            ProUpgradeView(source: request.source)
        }
        .confirmationDialog(
            "Delete local data?",
            isPresented: $showingDeleteDataConfirmation,
            titleVisibility: .visible
        ) {
            Button("Delete Local Data", role: .destructive) {
                deleteLocalData()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This removes saved tip history, receipt photos, custom presets, onboarding status, and pending shortcut state from this device. This cannot be undone.")
        }
        .alert("Could Not Delete Data", isPresented: deletionErrorPresentation) {
            Button("OK") {
                dataDeletionError = nil
            }
        } message: {
            Text(dataDeletionError ?? "Please try again.")
        }
    }

    private var guideCard: some View {
        HStack(spacing: .spacingMedium) {
            Image(systemName: "questionmark.circle")
                .font(.title2)
                .foregroundStyle(palette.accent)
                .frame(width: 42, height: 42)
                .background(palette.selectedTile, in: Circle())

            VStack(alignment: .leading, spacing: 4) {
                Text("Quick Guide")
                    .font(.headline)
                Text("Replay the short first-run walkthrough.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button("Replay") {
                hasCompletedOnboarding = false
            }
            .buttonStyle(.glass)
        }
        .settingsGlassCard(palette: palette)
    }

    private var privacyCard: some View {
        VStack(alignment: .leading, spacing: .spacingMedium) {
            HStack(alignment: .top, spacing: .spacingMedium) {
                Image(systemName: "lock.shield")
                    .font(.title2)
                    .foregroundStyle(palette.accent)
                    .frame(width: 42, height: 42)
                    .background(palette.selectedTile, in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text("Privacy & Data")
                        .font(.headline)
                    Text("Delete saved tips, receipt photos, custom presets, and local app preferences from this device.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            Text("\(transactions.count) saved tip\(transactions.count == 1 ? "" : "s") and \(tipPresets.count) custom preset\(tipPresets.count == 1 ? "" : "s") are stored locally.")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            Button(role: .destructive) {
                showingDeleteDataConfirmation = true
            } label: {
                Label("Delete Local Data", systemImage: "trash")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
            .disabled(storedItemCount == 0 && !hasCompletedOnboarding)
            .accessibilityHint("Deletes saved tip history, receipt photos, custom presets, onboarding status, and pending shortcut state from this device.")
        }
        .settingsGlassCard(palette: palette)
    }

    private var proCard: some View {
        VStack(alignment: .leading, spacing: .spacingMedium) {
            HStack(alignment: .top, spacing: .spacingMedium) {
                Image(systemName: purchaseManager.isProUnlocked ? "crown.fill" : "crown")
                    .font(.title2)
                    .foregroundStyle(purchaseManager.isProUnlocked ? palette.highlight : palette.accent)
                    .frame(width: 42, height: 42)
                    .background(palette.selectedTile, in: Circle())

                VStack(alignment: .leading, spacing: 4) {
                    Text(purchaseManager.isProUnlocked ? "Scan Tip Pro Active" : "Scan Tip Pro")
                        .font(.headline)
                    Text(purchaseManager.isProUnlocked ? "Unlimited history, Smart Check, custom presets, exports, and iCloud sync are unlocked." : "Upgrade once for unlimited history, Smart Check, custom presets, exports, and iCloud sync.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }

            if purchaseManager.isProUnlocked {
                #if DEBUG
                Button {
                    purchaseManager.resetPreviewPro()
                } label: {
                    Label("Reset Preview Unlock", systemImage: "arrow.counterclockwise")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glass)
                #endif
            } else {
                Button {
                    showProUpgrade(source: "settings")
                } label: {
                    Label("View Pro", systemImage: "crown")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.glassProminent)
            }
        }
        .settingsGlassCard(palette: palette)
    }

    private var presetCard: some View {
        VStack(alignment: .leading, spacing: .spacingMedium) {
            VStack(alignment: .leading, spacing: .spacingSmall) {
                Label("Tip Suggestions", systemImage: "slider.horizontal.3")
                    .font(.headline)

                Text("Customize the percentages shown on the calculator. Added presets join the built-in set and stay sorted automatically.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                if !purchaseManager.isProUnlocked {
                    Label("Custom presets are included with Pro.", systemImage: "crown")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(palette.accent)
                }
            }

            Text("\(activePresetValues.count) active preset\(activePresetValues.count == 1 ? "" : "s")")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 72), spacing: 10)], spacing: 10) {
                ForEach(activePresetValues, id: \.self) { percentage in
                    Text("\(Int((percentage * 100).rounded()))%")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 48)
                        .background(palette.tile, in: RoundedRectangle(cornerRadius: 14))
                }
            }

            Button {
                guard purchaseManager.isProUnlocked else {
                    showProUpgrade(source: "manage_presets")
                    return
                }

                showingPresetManager = true
            } label: {
                Label("Manage Presets", systemImage: "slider.horizontal.3")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
        }
        .settingsGlassCard(palette: palette)
    }

    private var deletionErrorPresentation: Binding<Bool> {
        Binding {
            dataDeletionError != nil
        } set: { isPresented in
            if !isPresented {
                dataDeletionError = nil
            }
        }
    }

    private func deleteLocalData() {
        do {
            try modelContext.delete(model: TipTransaction.self)
            try modelContext.delete(model: TipPreset.self)
            try ReceiptPhotoStore.deleteAll()
            try modelContext.save()

            let defaults = UserDefaults.standard
            [
                "hasCompletedOnboarding",
                "pendingOpenScanner",
                "pendingScanTipDestination",
                "pendingScanTipTransactionID",
                TipPresetCatalog.hiddenDefaultPresetsKey
            ].forEach(defaults.removeObject(forKey:))

            hiddenDefaultPresetStorage = ""
            hasCompletedOnboarding = false
            AnalyticsService.track(.localDataDeleted)
        } catch {
            dataDeletionError = error.localizedDescription
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

struct PresetManagementSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appPalette) private var palette
    @AppStorage(TipPresetCatalog.hiddenDefaultPresetsKey) private var hiddenDefaultPresetStorage = ""
    @Query(sort: \TipPreset.percentage) private var tipPresets: [TipPreset]

    @State private var presentedSheet: PresetSheet?

    private var displayItems: [TipPresetDisplayItem] {
        let hiddenDefaults = TipPresetCatalog.hiddenDefaultBasisPoints(from: hiddenDefaultPresetStorage)
        let customBasisPoints = Set(tipPresets.map { TipPresetCatalog.basisPoints(for: $0.percentage) })

        let builtInItems = TipPresetCatalog.defaultPercentages.compactMap { percentage -> TipPresetDisplayItem? in
            let basisPoints = TipPresetCatalog.basisPoints(for: percentage)
            guard !hiddenDefaults.contains(basisPoints), !customBasisPoints.contains(basisPoints) else {
                return nil
            }

            return TipPresetDisplayItem(percentage: percentage, source: .builtIn)
        }

        let customItems = tipPresets.map { preset in
            TipPresetDisplayItem(percentage: preset.percentage, source: .custom(preset))
        }

        return (builtInItems + customItems).sorted {
            TipPresetCatalog.basisPoints(for: $0.percentage) < TipPresetCatalog.basisPoints(for: $1.percentage)
        }
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(displayItems) { item in
                        PresetManagementRow(item: item) {
                            edit(item)
                        } onDelete: {
                            delete(item)
                        }
                    }
                } header: {
                    Text("Active")
                } footer: {
                    Text("Built-in and custom presets appear together on the calculator in ascending order.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(backgroundGradient)
            .navigationTitle("Manage Presets")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        presentedSheet = .add
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Add preset")
                }
            }
            .sheet(item: $presentedSheet) { sheet in
                switch sheet {
                case .add:
                    AddEditPresetSheet(presetToEdit: nil, hiddenDefaultPresetStorage: $hiddenDefaultPresetStorage)
                case .edit(let preset):
                    AddEditPresetSheet(presetToEdit: preset, hiddenDefaultPresetStorage: $hiddenDefaultPresetStorage)
                }
            }
        }
        .tint(palette.accent)
    }

    private var backgroundGradient: some View {
        LinearGradient(
            colors: [
                palette.backgroundTop,
                palette.backgroundBottom
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }

    private func edit(_ item: TipPresetDisplayItem) {
        guard case .custom(let preset) = item.source else { return }
        presentedSheet = .edit(preset)
    }

    private func delete(_ item: TipPresetDisplayItem) {
        switch item.source {
        case .builtIn:
            var hiddenDefaults = TipPresetCatalog.hiddenDefaultBasisPoints(from: hiddenDefaultPresetStorage)
            hiddenDefaults.insert(TipPresetCatalog.basisPoints(for: item.percentage))
            hiddenDefaultPresetStorage = TipPresetCatalog.storageString(from: hiddenDefaults)
        case .custom(let preset):
            modelContext.delete(preset)
        }

        AnalyticsService.track(
            .presetDeleted,
            properties: [
                "tip_percent": String(Int((item.percentage * 100).rounded())),
                "source": item.sourceLabel.lowercased()
            ]
        )
    }
}

private enum PresetSheet: Identifiable {
    case add
    case edit(TipPreset)

    var id: String {
        switch self {
        case .add:
            "add"
        case .edit(let preset):
            "edit-\(preset.id.uuidString)"
        }
    }
}

private struct PresetManagementRow: View {
    @Environment(\.appPalette) private var palette

    let item: TipPresetDisplayItem
    let onEdit: () -> Void
    let onDelete: () -> Void

    private var canEdit: Bool {
        if case .custom = item.source {
            return true
        }
        return false
    }

    var body: some View {
        HStack(spacing: .spacingMedium) {
            Text("\(Int((item.percentage * 100).rounded()))%")
                .font(.title3.weight(.bold))
                .fontDesign(.rounded)
                .frame(width: 76, height: 54)
                .background(palette.selectedTile, in: RoundedRectangle(cornerRadius: 14))

            VStack(alignment: .leading, spacing: 3) {
                Text(item.sourceLabel)
                    .font(.headline)
                Text("Shown on the calculator")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            if canEdit {
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .frame(width: .minimumTouchTarget, height: .minimumTouchTarget)
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Edit \(Int((item.percentage * 100).rounded())) percent preset")
            }

            Button(role: .destructive, action: onDelete) {
                Image(systemName: "trash")
                    .frame(width: .minimumTouchTarget, height: .minimumTouchTarget)
            }
            .buttonStyle(.borderless)
            .accessibilityLabel("Delete \(Int((item.percentage * 100).rounded())) percent preset")
        }
        .padding(.vertical, 4)
    }
}

struct AddEditPresetSheet: View {
    let presetToEdit: TipPreset?

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appPalette) private var palette
    @Binding var hiddenDefaultPresetStorage: String
    @Query(sort: \TipPreset.percentage) private var tipPresets: [TipPreset]
    @State private var percentageText: String

    private var percentageValue: Double? {
        Double(percentageText.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private var canSave: Bool {
        guard let percentageValue else { return false }
        return percentageValue > 0 && percentageValue <= 100
    }

    init(presetToEdit: TipPreset?, hiddenDefaultPresetStorage: Binding<String>) {
        self.presetToEdit = presetToEdit
        _hiddenDefaultPresetStorage = hiddenDefaultPresetStorage
        _percentageText = State(initialValue: presetToEdit.map { String(Int($0.percentage * 100)) } ?? "")
    }

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: .spacingLarge) {
                TextField("Tip percentage", text: $percentageText)
                    .keyboardType(.decimalPad)
                    .font(.title2.weight(.semibold))
                    .textFieldStyle(GlassTextFieldStyle(palette: palette))

                Text("Enter a whole or decimal percentage from 1 to 100.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                Spacer()
            }
            .padding()
            .navigationTitle(presetToEdit == nil ? "Add Preset" : "Edit Preset")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        savePreset()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }

    private func savePreset() {
        guard let percentageValue else { return }
        let fraction = percentageValue / 100
        let basisPoints = TipPresetCatalog.basisPoints(for: fraction)
        let existingCustomPreset = tipPresets.first {
            TipPresetCatalog.basisPoints(for: $0.percentage) == basisPoints && $0.id != presetToEdit?.id
        }

        guard existingCustomPreset == nil else {
            dismiss()
            return
        }

        if let presetToEdit {
            presetToEdit.percentage = fraction
            AnalyticsService.track(
                .presetEdited,
                properties: ["tip_percent": String(Int((fraction * 100).rounded()))]
            )
        } else {
            let defaultBasisPoints = Set(TipPresetCatalog.defaultPercentages.map { TipPresetCatalog.basisPoints(for: $0) })

            if defaultBasisPoints.contains(basisPoints) {
                var hiddenDefaults = TipPresetCatalog.hiddenDefaultBasisPoints(from: hiddenDefaultPresetStorage)
                hiddenDefaults.remove(basisPoints)
                hiddenDefaultPresetStorage = TipPresetCatalog.storageString(from: hiddenDefaults)
            } else {
                modelContext.insert(TipPreset(percentage: fraction))
            }

            AnalyticsService.track(
                .presetCreated,
                properties: ["tip_percent": String(Int((fraction * 100).rounded()))]
            )
        }

        dismiss()
    }
}

private extension View {
    func settingsGlassCard(palette: ThemePalette) -> some View {
        self
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(palette.card, in: RoundedRectangle(cornerRadius: .cornerRadiusLarge))
            .glassEffect(.regular.tint(palette.glassTint), in: .rect(cornerRadius: .cornerRadiusLarge))
    }
}

#Preview {
    NavigationStack {
        TipPresetSettingsView()
    }
    .modelContainer(for: [TipPreset.self, TipTransaction.self], inMemory: true)
    .environment(PurchaseManager())
}
