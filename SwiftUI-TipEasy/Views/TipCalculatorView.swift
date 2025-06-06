import Combine
import SwiftData
import SwiftUI

enum TipInputMode {
    case percentage, dollar
}

struct TipCalculatorView: View {
    // MARK: - Properties
    
    @State private var billAmount: String = ""
    
    // Remove separate tip amount and percentage fields.
    // Use one custom tip field:
    @State private var customTipValue: String = ""
    @State private var tipInputMode: TipInputMode = .percentage
    
    @State private var selectedTipPercentage: Double = 0.15
    @State private var tipPercentage: Double = 0.15
    @State private var shouldClearCustomFields: Bool = true
    @State private var isEditingCustomTip: Bool = false
    @State private var tipWorkItem: DispatchWorkItem?
    
    // Instead of using AppStorage, we query the TipPreset model.
    @Query(sort: \TipPreset.percentage) private var tipPresets: [TipPreset]
    
    // Default presets (if no models exist).
    private let defaultPresets: [Double] = [0.10, 0.12, 0.15, 0.18, 0.20, 0.22, 0.25]
    private let debounceInterval: TimeInterval = 0.8
    
    // MARK: - Computed Properties

    private var bill: Double {
        Double(billAmount) ?? 0
    }
    
    // When in percentage mode, customTipValue is treated as percentage (e.g., 15 means 15%)
    // When in dollar mode, customTipValue is treated as tip dollars.
    private var computedTipPercentage: Double {
        if bill > 0, let entered = Double(customTipValue), !customTipValue.isEmpty {
            switch tipInputMode {
            case .percentage:
                return entered / 100
            case .dollar:
                return entered / bill
            }
        }
        return tipPercentage
    }
    
    private var computedTipAmount: Double {
        switch tipInputMode {
        case .percentage:
            return bill * computedTipPercentage
        case .dollar:
            if let entered = Double(customTipValue) {
                return entered
            }
            return bill * tipPercentage
        }
    }
    
    private var totalAmount: Double {
        bill + computedTipAmount
    }
    
    // Calculate preset percentages based on TipPreset models.
    // If no presets exist in the model container, use defaultPresets.
    private var presetPercentageValues: [Double] {
        if tipPresets.isEmpty {
            return defaultPresets
        } else {
            return tipPresets.map { $0.percentage }
        }
    }
    
    // Create rows from the presetPercentageValues.
    private var presetButtonRows: some View {
        let presets = presetPercentageValues
        let count = presets.count
        let splitIndex = (count + 1) / 2
        let firstRow = count < 4 ? Array(presets) : Array(presets.prefix(splitIndex))
        let secondRow = count < 4 ? [] : Array(presets.suffix(from: splitIndex))
        return VStack(spacing: 10) {
            HStack(spacing: 10) {
                ForEach(firstRow, id: \.self) { percentage in
                    createPresetButton(for: percentage)
                }
            }
            if !secondRow.isEmpty {
                HStack(spacing: 10) {
                    ForEach(secondRow, id: \.self) { percentage in
                        createPresetButton(for: percentage)
                    }
                }
            }
        }
    }
    
    // MARK: - View Components
    
    private var billInputField: some View {
        HStack {
            Label("", systemImage: "dollarsign")
            TextField("Enter bill amount", text: $billAmount)
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedTextFieldStyle())
        }
    }
    
    private var tipPercentageSlider: some View {
        VStack {
            Slider(value: $selectedTipPercentage, in: 0 ... 0.50, step: 0.01)
                .accentColor(.blue)
                .onChange(of: selectedTipPercentage) { _, newValue in
                    updateTipFromSlider(newValue)
                }
            Text("Tip Percentage: \(Int(selectedTipPercentage * 100))%")
        }
    }
    
    // A single custom tip input field with a toggle to switch between percentage and dollar mode.
    private var customTipInputField: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField(tipInputMode == .percentage ?
                    "Enter tip percentage" : "Enter tip amount", text: $customTipValue, onEditingChanged: handleCustomTipEditing)
                    .keyboardType(.decimalPad)
                    .textFieldStyle(RoundedTextFieldStyle())
            
                Button(action: {
                    tipInputMode = .percentage
                }) {
                    Label("", systemImage: "percent")
                        .padding()
                        // .frame(maxWidth: .infinity)
                        .background(tipInputMode == .percentage ? Color.blue : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                Button(action: {
                    tipInputMode = .dollar
                }) {
                    Label("", systemImage: "dollarsign")
                        .padding()
                        // .frame(maxWidth: .infinity)
                        .background(tipInputMode == .dollar ? Color.blue : Color.gray.opacity(0.3))
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
            }
        }
    }
    
    private var summaryView: some View {
        VStack(spacing: 10) {
            Text("Bill: $\(bill, specifier: "%.2f")")
            Text("Tip: $\(computedTipAmount, specifier: "%.2f") (\(Int(computedTipPercentage * 100))%)")
            Divider()
            HStack(alignment: .center) {
                Text("Total: $\(totalAmount, specifier: "%.2f")")
            }
        }
        .font(.title3)
        .fontWeight(.medium)
        .padding()
        .animation(.default, value: totalAmount)
    }
    
    // MARK: - Body
    
    var body: some View {
        VStack(spacing: 15) {
            Text("Tip Easy")
                .font(.largeTitle)
                .bold()
            billInputField
            tipPercentageSlider
            presetButtonRows
            customTipInputField
            summaryView
            Spacer()
            AdBannerView(adUnitID: "ca-app-pub-3911596373332918/3954995797")
                .frame(height: 50)
        }
        .padding()
    }
    
    // MARK: - Helper Methods
    
    private func createPresetButton(for percentage: Double) -> some View {
        Button(action: {
            shouldClearCustomFields = true
            updateTipFromPreset(percentage)
        }) {
            Text("\(Int(percentage * 100))%")
                .padding()
                // .frame(maxWidth: 20)
                .background((abs(percentage - tipPercentage) < 0.001)
                    ? Color.blue.opacity(0.7)
                    : Color.blue)
                .foregroundColor(.white)
                .cornerRadius(8)
        }
    }
    
    private func updateTipFromSlider(_ newValue: Double) {
        withAnimation {
            tipPercentage = newValue
            selectedTipPercentage = newValue
            if shouldClearCustomFields { clearCustomTipField() }
            cancelTipWorkItem()
        }
    }
    
    private func updateTipFromPreset(_ percentage: Double) {
        withAnimation {
            tipPercentage = percentage
            selectedTipPercentage = percentage
            if shouldClearCustomFields { clearCustomTipField() }
            cancelTipWorkItem()
        }
    }
    
    private func clearCustomTipField() {
        customTipValue = ""
    }
    
    private func cancelTipWorkItem() {
        tipWorkItem?.cancel()
    }
    
    private func debouncedCustomTipUpdate(oldValue: String, newValue: String) {
        cancelTipWorkItem()
        let workItem = DispatchWorkItem {
            updateCustomTip()
        }
        tipWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + debounceInterval, execute: workItem)
    }
    
    private func handleCustomTipEditing(_ editing: Bool) {
        isEditingCustomTip = editing
        if !editing {
            updateCustomTip()
        }
    }
    
    private func updateCustomTip() {
        guard !customTipValue.trimmingCharacters(in: .whitespaces).isEmpty, bill > 0 else { return }
        withAnimation {
            if tipInputMode == .percentage {
                let entered = Double(customTipValue) ?? 0
                tipPercentage = entered / 100
            } else {
                let entered = Double(customTipValue) ?? 0
                tipPercentage = entered / bill
            }
            selectedTipPercentage = tipPercentage
            shouldClearCustomFields = false
        }
    }
}

// MARK: - Custom Styles

struct RoundedTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .keyboardType(.decimalPad)
            .submitLabel(.done)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
    }
}

struct TipCalculatorView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            TipCalculatorView()
                .preferredColorScheme(.light)
            TipCalculatorView()
                .preferredColorScheme(.dark)
        }
    }
}
