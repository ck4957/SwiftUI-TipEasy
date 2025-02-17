import Foundation

class TipCalculatorModel: ObservableObject {
    @Published var billAmount: String = ""
    @Published var selectedTipPercentage: Double = 0.0
    @Published var customTipPercentage: String = ""

    var totalAmount: Double {
        let bill = Double(billAmount) ?? 0
        let tip = bill * selectedTipPercentage
        return bill + tip
    }

    func setTipPercentage(_ percentage: Double) {
        selectedTipPercentage = percentage / 100
    }

    func calculateCustomTip() -> Double {
        let customTip = Double(customTipPercentage) ?? 0
        return totalAmount + (totalAmount * (customTip / 100))
    }
}
