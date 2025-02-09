import SwiftUI

struct TipCalculatorView: View {
    @State private var billAmount: String = ""
    @State private var customTipAmount: String = ""
    @State private var customTipPercentageStr: String = ""
    @State private var selectedTipPercentage: Double = 0.15
    @State private var tipPercentage: Double = 0.15
    
    // Preset percentages divided into two rows
    let rowOnePercentages: [Double] = [0.10, 0.12, 0.15, 0.18]
    let rowTwoPercentages: [Double] = [0.20, 0.22, 0.25]
    
    // Convert bill string to Double
    var bill: Double {
        Double(billAmount) ?? 0
    }
    
    // If user enters a custom tip amount, use it.
    // Otherwise use the tipPercentage selected via slider or preset buttons.
    var tipAmount: Double {
        if let entered = Double(customTipAmount), entered > 0 {
            return entered
        }
        return bill * tipPercentage
    }
    
    // If a custom tip amount is entered and bill is greater than 0, compute tip percentage from it.
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
            
            Slider(value: $selectedTipPercentage, in: 0...0.50, step: 0.01)
                .accentColor(.blue)
                .onChange(of: selectedTipPercentage) { _, newValue in
                    withAnimation {
                        tipPercentage = newValue
                        // Clear custom inputs when using preset/slider
                        customTipAmount = ""
                        customTipPercentageStr = ""
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
            TextField("Enter tip amount", text: $customTipAmount)
                .keyboardType(.decimalPad)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .onChange(of: customTipAmount) { newValue in
                    withAnimation {
                        if let enteredTip = Double(newValue), bill > 0 {
                            let computedPercentage = (enteredTip / bill) * 100
                            let computedPercentageStr = String(format: "%.2f", computedPercentage)
                            if customTipPercentageStr != computedPercentageStr {
                                customTipPercentageStr = computedPercentageStr
                            }
                            tipPercentage = enteredTip / bill
                            selectedTipPercentage = tipPercentage
                        } else {
                            customTipPercentageStr = ""
                        }
                    }
                }
            
            // Custom tip percentage field
            TextField("Enter tip percentage", text: $customTipPercentageStr)
                .keyboardType(.decimalPad)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .onChange(of: customTipPercentageStr) { newValue in
                    withAnimation {
                        if let enteredPercent = Double(newValue), bill > 0 {
                            let computedTip = bill * (enteredPercent / 100)
                            let computedTipStr = String(format: "%.2f", computedTip)
                            if customTipAmount != computedTipStr {
                                customTipAmount = computedTipStr
                            }
                            tipPercentage = enteredPercent / 100
                            selectedTipPercentage = tipPercentage
                        } else {
                            customTipAmount = ""
                        }
                    }
                }
            
            // Summary section displaying bill, tip, computed tip percentage, and total amount
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
