import Combine
import SwiftUI

struct TipCalculatorView: View {
    // MARK: - Properties

    @State private var billAmount: String = ""
    @State private var customTipAmount: String = ""
    @State private var customTipPercentageStr: String = ""
    @State private var selectedTipPercentage: Double = 0.15
    @State private var tipPercentage: Double = 0.15
    @State private var shouldClearCustomFields: Bool = true
    @State private var isEditingTipAmount: Bool = false
    @State private var isEditingTipPercentage: Bool = false
    @State private var tipAmountWorkItem: DispatchWorkItem?
    @State private var tipPercentageWorkItem: DispatchWorkItem?
    
    // MARK: - Constants

    private let rowOnePercentages: [Double] = [0.10, 0.12, 0.15, 0.18]
    private let rowTwoPercentages: [Double] = [0.20, 0.22, 0.25]
    private let debounceInterval: TimeInterval = 0.8
    
    // MARK: - Computed Properties

    private var bill: Double {
        Double(billAmount) ?? 0
    }
    
    private var tipAmount: Double {
        if let entered = Double(customTipAmount), entered > 0 {
            return entered
        }
        return bill * tipPercentage
    }
    
    private var computedTipPercentage: Double {
        if bill > 0, let entered = Double(customTipAmount), entered > 0 {
            return entered / bill
        }
        return tipPercentage
    }
    
    private var totalAmount: Double {
        bill + tipAmount
    }
    
    // MARK: - View Components

    private var billInputField: some View {
        TextField("Enter bill amount", text: $billAmount)
            .keyboardType(.decimalPad)
            .textFieldStyle(RoundedTextFieldStyle())
            .padding(.horizontal)
    }
    
    private var tipPercentageSlider: some View {
        VStack {
            Slider(value: $selectedTipPercentage, in: 0 ... 0.50, step: 0.01)
                .accentColor(.white)
                .onChange(of: selectedTipPercentage) { _, newValue in
                    updateTipFromSlider(newValue)
                }
            Text("Tip Percentage: \(Int(selectedTipPercentage * 100))%")
                .foregroundColor(.white)
                .bold()
        }
        .padding(.horizontal)
    }
    
    private var presetButtonRows: some View {
        VStack(spacing: 10) {
            HStack(spacing: 10) { ForEach(rowOnePercentages, id: \.self) { percentage in
                createPresetButton(for: percentage)
            }}
            HStack(spacing: 10) { ForEach(rowTwoPercentages, id: \.self) { percentage in
                createPresetButton(for: percentage)
            }}
        }
        .padding(.horizontal)
    }
    
    private var customInputFields: some View {
        return VStack(spacing: 15) {
            TextField("Enter tip amount", text: $customTipAmount, onEditingChanged: handleTipAmountEditing)
                .textFieldStyle(RoundedTextFieldStyle())
                .onChange(of: customTipAmount) { oldValue, newValue in
                    debouncedTipAmountUpdate(oldValue: oldValue, newValue: newValue)
                }
        
            TextField("Enter tip percentage", text: $customTipPercentageStr, onEditingChanged: handleTipPercentageEditing)
                .textFieldStyle(RoundedTextFieldStyle())
                .onChange(of: customTipPercentageStr) {
                    oldValue, newValue in
                    debouncedTipPercentageUpdate(oldValue: oldValue, newValue: newValue)
                }
        }
        .padding(.horizontal)
    }
    
    private var summaryView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Bill Amount: $\(bill, specifier: "%.2f")")
            Text("Tip Amount: $\(tipAmount, specifier: "%.2f")")
            Text("Tip Percentage: \(Int(computedTipPercentage * 100))%")
            Text("Total Amount: $\(totalAmount, specifier: "%.2f")")
        }
        .font(.title2)
        .bold()
        .padding()
        .background(Color.white.opacity(0.85))
        .cornerRadius(8)
        .animation(.default, value: totalAmount)
        .padding(.horizontal)
    }
    
    // MARK: - Body

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(gradient: Gradient(colors: [Color.purple, Color.blue]),
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing)
                .edgesIgnoringSafeArea(.all)
            
            ScrollView {
                VStack(spacing: 20) {
                    Text("Tip Easy")
                        .font(.largeTitle)
                        .bold()
                        .foregroundColor(.white)
                    
                    billInputField
                    tipPercentageSlider
                    presetButtonRows
                    customInputFields
                    summaryView
                }
                .padding(.vertical, 20)
            }
        }
    }
    
    // MARK: - Helper Methods

    private func createPresetButton(for percentage: Double) -> some View {
        Button(action: { updateTipFromPreset(percentage) }) {
            Text("\(Int(percentage * 100))%")
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding()
                .background(
                    LinearGradient(gradient: Gradient(colors: [Color.orange, Color.red]),
                                   startPoint: .leading,
                                   endPoint: .trailing)
                )
                .foregroundColor(.white)
                .cornerRadius(10)
        }
    }
    
    private func updateTipFromSlider(_ newValue: Double) {
        withAnimation {
            tipPercentage = newValue
            if shouldClearCustomFields {
                clearCustomFields()
            }
            cancelWorkItems()
        }
    }
    
    private func updateTipFromPreset(_ percentage: Double) {
        withAnimation {
            tipPercentage = percentage
            selectedTipPercentage = percentage
            if shouldClearCustomFields {
                clearCustomFields()
            }
            cancelWorkItems()
        }
    }
    
    private func clearCustomFields() {
        customTipAmount = ""
        customTipPercentageStr = ""
    }
    
    private func cancelWorkItems() {
        tipAmountWorkItem?.cancel()
        tipPercentageWorkItem?.cancel()
    }
    
    private func debouncedTipAmountUpdate(oldValue: String, newValue: String) {
        tipAmountWorkItem?.cancel()
        let workItem = DispatchWorkItem {
            updateTipAmount(oldValue: oldValue, newValue: newValue)
        }
        tipAmountWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + debounceInterval, execute: workItem)
    }
    
    private func debouncedTipPercentageUpdate(oldValue: String, newValue: String) {
        tipPercentageWorkItem?.cancel()
        let workItem = DispatchWorkItem {
            updateTipPercentage(oldValue: oldValue, newValue: newValue)
        }
        tipPercentageWorkItem = workItem
        DispatchQueue.main.asyncAfter(deadline: .now() + debounceInterval, execute: workItem)
    }
    
    private func handleTipAmountEditing(_ editing: Bool) {
        isEditingTipAmount = editing
        if !editing {
            // When editing ends, update immediately
            if let oldValue = Double(customTipAmount) {
                updateTipAmount(oldValue: String(oldValue), newValue: customTipAmount)
            }
        }
    }

    private func handleTipPercentageEditing(_ editing: Bool) {
        isEditingTipPercentage = editing
        if !editing {
            // When editing ends, update immediately
            if let oldValue = Double(customTipPercentageStr) {
                updateTipPercentage(oldValue: String(oldValue), newValue: customTipPercentageStr)
            }
        }
    }

    private func updateTipAmount(oldValue: String, newValue: String) {
        // Do not update if the field is empty or unchanged
        guard !newValue.trimmingCharacters(in: .whitespaces).isEmpty,
              oldValue != newValue else { return }
        
        withAnimation {
            if let enteredTip = Double(newValue), bill > 0 {
                let computedPercentage = (enteredTip / bill) * 100
                let computedPercentageStr = String(format: "%.2f", computedPercentage)
                if !isEditingTipPercentage && customTipPercentageStr != computedPercentageStr {
                    customTipPercentageStr = computedPercentageStr
                }
                tipPercentage = enteredTip / bill
                selectedTipPercentage = tipPercentage
                shouldClearCustomFields = false
            }
        }
    }

    private func updateTipPercentage(oldValue: String, newValue: String) {
        // Do not update if the field is empty or unchanged
        guard !newValue.trimmingCharacters(in: .whitespaces).isEmpty,
              oldValue != newValue else { return }
        
        withAnimation {
            if let enteredPercent = Double(newValue), bill > 0 {
                let computedTip = bill * (enteredPercent / 100)
                let computedTipStr = String(format: "%.2f", computedTip)
                if !isEditingTipAmount && customTipAmount != computedTipStr {
                    customTipAmount = computedTipStr
                }
                tipPercentage = enteredPercent / 100
                selectedTipPercentage = tipPercentage
                shouldClearCustomFields = false
            }
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
            .background(Color.white.opacity(0.85))
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
