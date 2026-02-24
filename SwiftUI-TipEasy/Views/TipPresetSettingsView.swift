import SwiftData
import SwiftUI

struct TipPresetSettingsView: View {
    // Query the TipPreset models from the container.
    @Query(sort: \TipPreset.percentage) private var tipPresets: [TipPreset]
    // Environment modelContext for insert, update, delete.
    @Environment(\.modelContext) private var modelContext
    // Used to dismiss the view.
    @Environment(\.dismiss) var dismiss

    // Sheet state for adding/editing a preset.
    @State private var showingPresetSheet: Bool = false
    @State private var presetToEdit: TipPreset? = nil

    var body: some View {
        Form {
            Section {
                ForEach(tipPresets) { preset in
                    HStack {
                        Image(systemName: "percent")
                            .foregroundStyle(.secondary)
                            .font(.title3)

                        Text("\(Int(preset.percentage * 100))%")
                            .font(.body)
                            .fontWeight(.medium)

                        Spacer()

                        Button {
                            presetToEdit = preset
                            showingPresetSheet = true
                        } label: {
                            Text("Edit")
                                .font(.body)
                        }
                        .buttonStyle(.bordered)
                        .tint(.accentColor)

                        Button(role: .destructive) {
                            withAnimation {
                                modelContext.delete(preset)
                            }
                        } label: {
                            Image(systemName: "trash")
                                .font(.body)
                        }
                        .buttonStyle(.bordered)
                        .accessibilityLabel("Delete preset")
                    }
                    .padding(.vertical, 4)
                }

                Button {
                    presetToEdit = nil
                    showingPresetSheet = true
                } label: {
                    Label("Add New Preset", systemImage: "plus.circle.fill")
                        .font(.body)
                }
            } header: {
                Text("Tip Percentages")
            } footer: {
                Text("Tap Edit to modify a preset or Add to create a new one. These percentages will appear as quick options in the calculator.")
            }
        }
        .navigationTitle("Preset Settings")
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showingPresetSheet) {
            AddEditPresetSheet(presetToEdit: presetToEdit, modelContext: modelContext)
        }
    }
}

// Sheet view for adding/editing tip preset.
struct AddEditPresetSheet: View {
    let presetToEdit: TipPreset?
    var modelContext: ModelContext
    @Environment(\.dismiss) var dismiss
    @State private var percentageText: String

    init(presetToEdit: TipPreset?, modelContext: ModelContext) {
        self.presetToEdit = presetToEdit
        self.modelContext = modelContext
        // If editing an existing preset, prefill the text field.
        _percentageText = State(initialValue: presetToEdit.map { String(Int($0.percentage * 100)) } ?? "")
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Tip Preset (in %)")) {
                    TextField("Enter tip percentage", text: $percentageText)
                        .keyboardType(.decimalPad)
                }
            }
            .navigationTitle(presetToEdit == nil ? "Add Preset" : "Edit Preset")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        if let value = Double(percentageText) {
                            let fraction = value / 100.0
                            if let preset = presetToEdit {
                                preset.percentage = fraction
                            } else {
                                let newPreset = TipPreset(percentage: fraction)
                                modelContext.insert(newPreset)
                            }
                        }
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    TipPresetSettingsView()
}
