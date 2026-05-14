import SwiftData
import SwiftUI

struct TipPresetSettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.appPalette) private var palette
    @AppStorage("selectedAppTheme") private var selectedThemeRawValue = AppTheme.harvest.rawValue
    @AppStorage("appAppearance") private var appAppearanceRawValue = AppAppearance.system.rawValue
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @Query(sort: \TipPreset.percentage) private var tipPresets: [TipPreset]

    @State private var showingPresetSheet = false
    @State private var presetToEdit: TipPreset?

    private let defaultPresets: [Double] = [0.15, 0.18, 0.20, 0.25]

    private var selectedTheme: AppTheme {
        AppTheme(rawValue: selectedThemeRawValue) ?? .harvest
    }

    private var selectedThemeBinding: Binding<AppTheme> {
        Binding {
            selectedTheme
        } set: { newValue in
            selectedThemeRawValue = newValue.rawValue
        }
    }

    private var appAppearanceBinding: Binding<AppAppearance> {
        Binding {
            AppAppearance(rawValue: appAppearanceRawValue) ?? .system
        } set: { newValue in
            appAppearanceRawValue = newValue.rawValue
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: .spacingLarge) {
                appearanceCard
                themeCard
                guideCard
                introCard
                presetCard
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
    }

    private var appearanceCard: some View {
        VStack(alignment: .leading, spacing: .spacingMedium) {
            Label("Appearance", systemImage: "circle.lefthalf.filled")
                .font(.headline)

            Picker("Appearance", selection: appAppearanceBinding) {
                ForEach(AppAppearance.allCases) { appearance in
                    Label(appearance.title, systemImage: appearance.iconName)
                        .tag(appearance)
                }
            }
            .pickerStyle(.segmented)
        }
        .settingsGlassCard(palette: palette)
    }

    private var themeCard: some View {
        VStack(alignment: .leading, spacing: .spacingMedium) {
            Label("Color Theme", systemImage: "paintpalette")
                .font(.headline)

            VStack(spacing: 10) {
                ForEach(AppTheme.allCases) { theme in
                    Button {
                        selectedThemeBinding.wrappedValue = theme
                    } label: {
                        ThemeChoiceRow(theme: theme, isSelected: selectedTheme == theme)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .settingsGlassCard(palette: palette)
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

    private var introCard: some View {
        VStack(alignment: .leading, spacing: .spacingSmall) {
            Label("Tip Suggestions", systemImage: "slider.horizontal.3")
                .font(.headline)
            Text("Customize the percentages shown on the calculator. If no custom presets exist, Tip Easy uses 15%, 18%, 20%, and 25%.")
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
}

private struct ThemeChoiceRow: View {
    let theme: AppTheme
    let isSelected: Bool

    private var palette: ThemePalette {
        theme.palette
    }

    var body: some View {
        HStack(spacing: .spacingMedium) {
            Image(systemName: theme.iconName)
                .font(.title3)
                .foregroundStyle(palette.accent)
                .frame(width: 40, height: 40)
                .background(palette.selectedTile, in: Circle())

            VStack(alignment: .leading, spacing: 3) {
                Text(theme.title)
                    .font(.headline)
                Text(theme.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            HStack(spacing: 5) {
                Circle().fill(palette.accent)
                Circle().fill(palette.secondaryAccent)
                Circle().fill(palette.highlight)
            }
            .frame(width: 54, height: 18)

            Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isSelected ? palette.accent : .secondary)
        }
        .padding()
        .background(isSelected ? palette.selectedTile : palette.tile, in: RoundedRectangle(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(isSelected ? palette.accent.opacity(0.46) : palette.highlight.opacity(0.18), lineWidth: 1)
        }
        .glassEffect(.regular.tint(isSelected ? palette.accent.opacity(0.10) : palette.glassTint).interactive(), in: .rect(cornerRadius: 18))
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
        } else {
            modelContext.insert(TipPreset(percentage: fraction))
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
