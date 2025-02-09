import SwiftUI

struct TipPresetSettingsView: View {
    // Stored as a comma-separated string (e.g., "10,12,15,18,20")
    @AppStorage("customPresetPercentages") var presetString: String = "10,12,15,18,20"
    // Local array of preset values to edit individually.
    @State private var presets: [String] = []
    // Used to dismiss the view
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Form {
            Section(header: Text("Custom Preset Tip Percentages (in %)")) {
                ForEach(presets.indices, id: \.self) { index in
                    HStack {
                        TextField("Preset", text: $presets[index])
                            .keyboardType(.decimalPad)
                        // Delete button for each preset field.
                        Button(action: {
                            presets.remove(at: index)
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundColor(.red)
                        }
                    }
                }
                // Plus button to add a new preset.
                Button(action: {
                    presets.append("")
                }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Preset")
                    }
                    .foregroundColor(.blue)
                }
            }
            
            Section {
                Button(action: {
                    // Join preset fields, trimming spaces and ignoring empties.
                    let validPresets = presets.map { $0.trimmingCharacters(in: .whitespaces) }
                        .filter { !$0.isEmpty }
                    presetString = validPresets.joined(separator: ",")
                    // Dismiss view after save.
                    dismiss()
                }) {
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
        .onAppear {
            // Split the stored string into the array.
            presets = presetString.split(separator: ",").map {
                String($0).trimmingCharacters(in: .whitespaces)
            }
        }
    }
}

struct TipPresetSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            TipPresetSettingsView()
                .preferredColorScheme(.light)
        }
    }
}