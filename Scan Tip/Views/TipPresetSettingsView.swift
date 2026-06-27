import SwiftData
import SwiftUI

struct TipPresetSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appPalette) private var palette
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Query(sort: \TipPreset.percentage) private var tipPresets: [TipPreset]
    @Query private var transactions: [TipTransaction]

    @State private var showingPresetSheet = false
    @State private var showingDeleteDataConfirmation = false
    @State private var dataDeletionError: String?
    @State private var presetToEdit: TipPreset?

    private let defaultPresets: [Double] = [0.15, 0.18, 0.20, 0.25]
    private var storedItemCount: Int {
        tipPresets.count + transactions.count
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .spacingLarge) {
                guideCard
                introCard
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
        .sheet(isPresented: $showingPresetSheet) {
            AddEditPresetSheet(presetToEdit: presetToEdit, modelContext: modelContext)
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

    private var introCard: some View {
        VStack(alignment: .leading, spacing: .spacingSmall) {
            Label("Tip Suggestions", systemImage: "slider.horizontal.3")
                .font(.headline)
            Text("Customize the percentages shown on the calculator. If no custom presets exist, Scan Tip uses 15%, 18%, 20%, and 25%.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .settingsGlassCard(palette: palette)
    }

    private var presetCard: some View {
        VStack(alignment: .leading, spacing: .spacingMedium) {
            HStack {
                Text("Presets")
                    .font(.headline)
                Spacer()
                Button {
                    presetToEdit = nil
                    showingPresetSheet = true
                } label: {
                    Image(systemName: "plus")
                        .frame(width: .minimumTouchTarget, height: .minimumTouchTarget)
                }
                .buttonStyle(.glassProminent)
                .accessibilityLabel("Add preset")
            }

            if tipPresets.isEmpty {
                defaultPresetPreview
            } else {
                ForEach(tipPresets) { preset in
                    presetRow(preset)
                }
            }
        }
        .settingsGlassCard(palette: palette)
    }

    private var defaultPresetPreview: some View {
        VStack(alignment: .leading, spacing: .spacingMedium) {
            Text("Default set active")
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(.secondary)

            HStack {
                ForEach(defaultPresets, id: \.self) { percentage in
                    Text("\(Int(percentage * 100))%")
                        .font(.headline.weight(.semibold))
                        .frame(maxWidth: .infinity, minHeight: 52)
                        .background(palette.tile, in: RoundedRectangle(cornerRadius: 14))
                }
            }
        }
    }

    private func presetRow(_ preset: TipPreset) -> some View {
        HStack(spacing: .spacingMedium) {
            Text("\(Int(preset.percentage * 100))%")
                .font(.title3.weight(.bold))
                .frame(width: 76, height: 56)
                .background(palette.selectedTile, in: RoundedRectangle(cornerRadius: 16))

            VStack(alignment: .leading, spacing: 3) {
                Text("Quick option")
                    .font(.headline)
                Text("Shown on the calculator")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            Button {
                presetToEdit = preset
                showingPresetSheet = true
            } label: {
                Image(systemName: "pencil")
                    .frame(width: .minimumTouchTarget, height: .minimumTouchTarget)
            }
            .buttonStyle(.glass)
            .accessibilityLabel("Edit \(Int(preset.percentage * 100)) percent preset")

            Button(role: .destructive) {
                AnalyticsService.track(
                    .presetDeleted,
                    properties: ["tip_percent": String(Int((preset.percentage * 100).rounded()))]
                )
                withAnimation {
                    modelContext.delete(preset)
                }
            } label: {
                Image(systemName: "trash")
                    .frame(width: .minimumTouchTarget, height: .minimumTouchTarget)
            }
            .buttonStyle(.glass)
            .accessibilityLabel("Delete \(Int(preset.percentage * 100)) percent preset")
        }
        .padding()
        .background(palette.card, in: RoundedRectangle(cornerRadius: 18))
        .glassEffect(.regular.tint(palette.glassTint), in: .rect(cornerRadius: 18))
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
                "pendingScanTipTransactionID"
            ].forEach(defaults.removeObject(forKey:))

            hasCompletedOnboarding = false
            AnalyticsService.track(.localDataDeleted)
        } catch {
            dataDeletionError = error.localizedDescription
        }
    }
}

struct AddEditPresetSheet: View {
    let presetToEdit: TipPreset?
    var modelContext: ModelContext

    @Environment(\.dismiss) private var dismiss
    @Environment(\.appPalette) private var palette
    @State private var percentageText: String

    private var percentageValue: Double? {
        Double(percentageText.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    private var canSave: Bool {
        guard let percentageValue else { return false }
        return percentageValue > 0 && percentageValue <= 100
    }

    init(presetToEdit: TipPreset?, modelContext: ModelContext) {
        self.presetToEdit = presetToEdit
        self.modelContext = modelContext
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

        if let presetToEdit {
            presetToEdit.percentage = fraction
            AnalyticsService.track(
                .presetEdited,
                properties: ["tip_percent": String(Int((fraction * 100).rounded()))]
            )
        } else {
            modelContext.insert(TipPreset(percentage: fraction))
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
}
