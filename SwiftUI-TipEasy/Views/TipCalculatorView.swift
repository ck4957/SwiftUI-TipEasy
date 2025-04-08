import Charts
import Combine
import PhotosUI
import SwiftData
import SwiftUI

enum TipInputMode {
    case percentage, dollar
}

struct TipCalculatorView: View {
    // Instead of using AppStorage, we query the TipPreset model.
    @Query(sort: \TipPreset.percentage) private var tipPresets: [TipPreset]
    @Query(sort: \CalculationHistory.timestamp, order: .reverse) private var history: [CalculationHistory]

    @Environment(\.modelContext) private var modelContext

    // Add AppStorage to track onboarding state
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
    @State private var isOnboardingPresented: Bool = false

    // MARK: - Properties

    @State private var billAmount: String = ""
    @State private var customTipValue: String = ""
    @State private var tipInputMode: TipInputMode = .percentage

    @State private var selectedTipPercentage: Double = 0.15
    @State private var tipPercentage: Double = 0.15
    @State private var shouldClearCustomFields: Bool = true
    @State private var isEditingCustomTip: Bool = false
    @State private var tipWorkItem: DispatchWorkItem?

    @State private var showingImagePicker = false
    @State private var showingCamera = false

    @State private var showingSavedCalculation = false
    @State private var savedCalculation: CalculationHistory?

    @State private var selectedCategory: ExpenseCategory = .restaurant
    @State private var showingDeleteAlert = false
    @State private var calculationToDelete: CalculationHistory?

    // Default presets (if no models exist).
    private let defaultPresets: [Double] = [0.10, 0.12, 0.15, 0.18, 0.20, 0.22, 0.25]
    private let debounceInterval: TimeInterval = 0.8

    @State private var showingHistory: Bool = false
    @State private var capturedPhoto: Data?
    @State private var locationManager = LocationManager()

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 15) {
                Text("Tip Easy")
                    .font(.largeTitle)
                    .bold()
                billInputField
                tipPercentageSlider
                presetButtonRows
                customTipInputField
                summaryView
                categorySelectorView
                imageAndSaveView

                // Add save button
                Button(action: saveCalculation) {
                    Label("Save Calculation", systemImage: "square.and.arrow.down")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(bill <= 0)

                Spacer()

                // Add history button
                Button {
                    showingHistory = true
                } label: {
                    Label("View History", systemImage: "clock.arrow.circlepath")
                }
                .padding(.bottom, 8)

                AdBannerView(adUnitID: "ca-app-pub-3911596373332918/3954995797")
                    .frame(height: 50)
            }
            .padding()
        }.sheet(isPresented: $showingCamera) {
            ImagePicker(image: $capturedPhoto, sourceType: .camera)
        }.sheet(isPresented: $showingSavedCalculation, onDismiss: {
            savedCalculation = nil
            capturedPhoto = nil
        }) {
            if let calculation = savedCalculation {
                SavedCalculationView(calculation: calculation)
            }
        }
        .sheet(isPresented: $showingHistory) {
            HistoryView(history: history) { calculation in
                calculationToDelete = calculation
                showingDeleteAlert = true
            }
        }
        // ...existing sheets...
        .sheet(isPresented: $showingImagePicker) {
            PhotosPicker(selection: Binding(
                get: { [] },
                set: { items in
                    if let item = items.first {
                        loadTransferable(from: item)
                    }
                }
            ), matching: .images, photoLibrary: .shared()) {
                Text("Select a photo")
            }
        }
        .alert("Delete Calculation", isPresented: $showingDeleteAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let calculation = calculationToDelete {
                    modelContext.delete(calculation)
                    calculationToDelete = nil
                }
            }
        } message: {
            Text("Are you sure you want to delete this calculation?")
        }
        // Add onboarding sheet
        .sheet(isPresented: $isOnboardingPresented) {
            AppOnboardingView(isOnboardingPresented: $isOnboardingPresented)
        }
        .onAppear {
            locationManager.requestLocation()

            // Check if we should show onboarding
            if !hasSeenOnboarding {
                isOnboardingPresented = true
                hasSeenOnboarding = true
            }
        }
    }

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

    // MARK: - View Components

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
                TextField(
                    tipInputMode == .percentage ? "Enter tip percentage" : "Enter tip amount",
                    text: $customTipValue, onEditingChanged: handleCustomTipEditing
                )
                .keyboardType(.decimalPad)
                .textFieldStyle(RoundedTextFieldStyle())

                Button(action: {
                    tipInputMode = .percentage
                }) {
                    Label("", systemImage: "percent")
                        .padding()
                        // .frame(maxWidth: .infinity)
                        .background(
                            tipInputMode == .percentage ? Color.blue : Color.gray.opacity(0.3)
                        )
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
            Text(
                "Tip: $\(computedTipAmount, specifier: "%.2f") (\(Int(computedTipPercentage * 100))%)"
            )
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

    private var categorySelectorView: some View {
        Picker("Category", selection: $selectedCategory) {
            ForEach(ExpenseCategory.allCases, id: \.self) { category in
                Label(category.rawValue, systemImage: category.icon)
            }
        }
        .pickerStyle(.menu)
        .padding(.vertical, 5)
    }

    private var imageAndSaveView: some View {
        HStack {
            Button(action: { showingCamera = true }) {
                Label("Add Photo", systemImage: "camera")
            }

            Button(action: saveCalculation) {
                Label("Save", systemImage: "square.and.arrow.down")
            }

//            NavigationLink {
//                HistoryView(history: history)
//            } label: {
//                Label("History", systemImage: "clock")
//            }
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
                .background(
                    (abs(percentage - tipPercentage) < 0.001)
                        ? Color.blue.opacity(0.7)
                        : Color.blue
                )
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

    private func saveCalculation() {
        let calculation = CalculationHistory(
            billAmount: bill,
            tipPercentage: tipPercentage,
            tipAmount: computedTipAmount,
            totalAmount: totalAmount,
            timestamp: Date(),
            location: locationManager.lastLocation?.coordinate,
            photo: capturedPhoto,
            category: selectedCategory
        )
        modelContext.insert(calculation)
        try? modelContext.save()

        savedCalculation = calculation
        showingSavedCalculation = true
    }

    private func loadTransferable(from item: PhotosPickerItem) {
        item.loadTransferable(type: Data.self) { result in
            switch result {
            case .success(let data):
                DispatchQueue.main.async {
                    self.capturedPhoto = data
                }
            case .failure(let error):
                print("Error loading image: \(error)")
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
