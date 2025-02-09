import Combine
import SwiftUI

struct TipCalculatorView: View {
    @State private var billAmount: String = ""
    @State private var customTipAmount: String = ""
    @State private var customTipPercentageStr: String = ""
    @State private var selectedTipPercentage: Double = 0.15
    @State private var tipPercentage: Double = 0.15

    // Editing flags to avoid mutual update loops
    @State private var isEditingTipAmount: Bool = false
    @State private var isEditingTipPercentage: Bool = false
    
    // Work items to debounce custom field updates.
    @State private var tipAmountWorkItem: DispatchWorkItem?
    @State private var tipPercentageWorkItem: DispatchWorkItem?
    
    // Preset percentages divided into two rows
    let rowOnePercentages: [Double] = [0.10, 0.12, 0.15, 0.18]
    let rowTwoPercentages: [Double] = [0.20, 0.22, 0.25]
    
    // Convert bill string to Double
    var bill: Double {
        Double(billAmount) ?? 0
    }
    
    // Use custom tip amount if entered; otherwise calculate.
    var tipAmount: Double {
        if let entered = Double(customTipAmount), entered > 0 {
            return entered
        }
        return bill * tipPercentage
    }
    
    // Computes tip percentage from custom tip amount if valid.
    var computedTipPercentage: Double {
        if bill > 0, let entered = Double(customTipAmount), entered > 0 {
            return entered / bill
        }
        return tipPercentage
    }
    
    var totalAmount: Double {
        bill + tipAmount
    }
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(alignment: .leading) {
                Text("Tip Easy")
                    .font(.largeTitle)
                    .bold()
            }
            
            TextField("Enter bill amount", text: $billAmount)
                .keyboardType(.decimalPad)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            
            Slider(value: $selectedTipPercentage, in: 0 ... 0.50, step: 0.01)
                .accentColor(.blue)
                .onChange(of: selectedTipPercentage) { _, newValue in
                    withAnimation {
                        tipPercentage = newValue
                        // Clear custom inputs when using slider
                        customTipAmount = ""
                        customTipPercentageStr = ""
                        tipAmountWorkItem?.cancel()
                        tipPercentageWorkItem?.cancel()
                    }
                }
            
            Text("Tip Percentage: \(Int(selectedTipPercentage * 100))%")
            
            // First row of preset tip buttons
            HStack {
                ForEach(rowOnePercentages, id: \.self) { percentage in
                    Button(action: {
                        withAnimation {
                            tipPercentage = percentage
                            selectedTipPercentage = percentage
                            customTipAmount = ""
                            customTipPercentageStr = ""
                            tipAmountWorkItem?.cancel()
                            tipPercentageWorkItem?.cancel()
                        }
                    }) {
                        Text("\(Int(percentage * 100))%")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background((abs(percentage - tipPercentage) < 0.001)
                                ? Color.blue.opacity(0.7)
                                : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            
            // Second row of preset tip buttons
            HStack {
                ForEach(rowTwoPercentages, id: \.self) { percentage in
                    Button(action: {
                        withAnimation {
                            tipPercentage = percentage
                            selectedTipPercentage = percentage
                            customTipAmount = ""
                            customTipPercentageStr = ""
                            tipAmountWorkItem?.cancel()
                            tipPercentageWorkItem?.cancel()
                        }
                    }) {
                        Text("\(Int(percentage * 100))%")
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background((abs(percentage - tipPercentage) < 0.001)
                                ? Color.blue.opacity(0.7)
                                : Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                }
            }
            
            // Custom tip amount field
            TextField("Enter tip amount", text: $customTipAmount, onEditingChanged: { editing in
                isEditingTipAmount = editing
                if !editing {
                    // When editing ends, update immediately.
                    updateTipAmount(newValue: customTipAmount)
                }
            })
            .keyboardType(.decimalPad)
            .submitLabel(.done)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .onChange(of: customTipAmount) { _, newValue in
                // Cancel previous work item.
                tipAmountWorkItem?.cancel()
                let workItem = DispatchWorkItem {
                    updateTipAmount(newValue: newValue)
                }
                tipAmountWorkItem = workItem
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: workItem)
            }
            
            // Custom tip percentage field
            TextField("Enter tip percentage", text: $customTipPercentageStr, onEditingChanged: { editing in
                isEditingTipPercentage = editing
                if !editing {
                    updateTipPercentage(newValue: customTipPercentageStr)
                }
            })
            .keyboardType(.decimalPad)
            .submitLabel(.done)
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .onChange(of: customTipPercentageStr) { _, newValue in
                tipPercentageWorkItem?.cancel()
                let workItem = DispatchWorkItem {
                    updateTipPercentage(newValue: newValue)
                }
                tipPercentageWorkItem = workItem
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.8, execute: workItem)
            }
            
            // Summary section
            VStack(alignment: .leading, spacing: 10) {
                Text("Bill Amount: $\(bill, specifier: "%.2f")")
                Text("Tip Amount: $\(tipAmount, specifier: "%.2f")")
                Text("Tip Percentage: \(Int(computedTipPercentage * 100))%")
                Text("Total Amount: $\(totalAmount, specifier: "%.2f")")
            }
            .font(.title2)
            .bold()
            .padding()
            .background(Color(.systemGray5))
            .cornerRadius(8)
            .animation(.default, value: totalAmount)
        }
        .padding()
    }
    
    // MARK: - Update Functions
    
    private func updateTipAmount(newValue: String) {
        withAnimation {
            if let enteredTip = Double(newValue), bill > 0 {
                let computedPercentage = (enteredTip / bill) * 100
                let computedPercentageStr = String(format: "%.2f", computedPercentage)
                if !isEditingTipPercentage && customTipPercentageStr != computedPercentageStr {
                    customTipPercentageStr = computedPercentageStr
                }
                tipPercentage = enteredTip / bill
                selectedTipPercentage = tipPercentage
            }
        }
        print("Custom Tip Amount updated to \(newValue)")
    }
    
    private func updateTipPercentage(newValue: String) {
        withAnimation {
            if let enteredPercent = Double(newValue), bill > 0 {
                let computedTip = bill * (enteredPercent / 100)
                let computedTipStr = String(format: "%.2f", computedTip)
                if !isEditingTipAmount && customTipAmount != computedTipStr {
                    customTipAmount = computedTipStr
                }
                tipPercentage = enteredPercent / 100
                selectedTipPercentage = tipPercentage
            }
        }
        print("Custom Tip Percentage updated to \(newValue)")
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
