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
        NavigationStack {
            Form {
                Section(header: Text("Custom Tip Percentages (in %)")) {
                    ForEach(tipPresets) { preset in
                        HStack {
                            Text("\(Int(preset.percentage * 100))%")
                                .onTapGesture {
                                    presetToEdit = preset
                                    showingPresetSheet = true
                                }

                            Spacer()

                            // Delete button for each preset.
                            Button {
                                modelContext.delete(preset)
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundColor(.red)
                            }
                        }
                    }

                    // Plus button to add a new preset.
                    Button {
                        presetToEdit = nil
                        showingPresetSheet = true
                    } label: {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add Preset")
                        }
                        .foregroundColor(.blue)
                    }
                }

                Section {
                    Button {
                        // Save is automatic for SwiftData.
                        dismiss()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Save")
                                .font(.headline)
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Preset Settings")
            .sheet(isPresented: $showingPresetSheet) {
                AddEditPresetSheet(presetToEdit: presetToEdit, modelContext: modelContext)
            }
            Spacer() // Ensure the form takes the full height of the screen, especially on iOS 16.
            AdBannerView(adUnitID: "ca-app-pub-3911596373332918/3954995797") // Replace with your ad unit ID
                .frame(height: 50)
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
