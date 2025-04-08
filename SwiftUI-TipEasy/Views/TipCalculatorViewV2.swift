// // import Charts
// import Combine
// import MapKit
// import PhotosUI
// import SwiftData
// import SwiftUI

// enum TipInputMode {
//     case percentage, dollar
// }

// struct TipCalculatorView: View {
//     // MARK: - Properties

//     @Query(sort: \TipPreset.percentage) private var tipPresets: [TipPreset]
//     @Query(sort: \CalculationHistory.timestamp, order: .reverse) private var history: [CalculationHistory]
//     @Environment(\.modelContext) private var modelContext

//   // Add AppStorage to track onboarding state
//     @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding: Bool = false
//     @State private var isOnboardingPresented: Bool = false
//     // Focus state for keyboard management
//     @FocusState private var focusedField: Field?

//     // Input state
//     @State private var billAmount: String = ""
//     @State private var customTipValue: String = ""
//     @State private var tipInputMode: TipInputMode = .percentage
//     @State private var selectedTipPercentage: Double = 0.15
//     @State private var tipPercentage: Double = 0.15
//     @State private var selectedCategory: ExpenseCategory = .restaurant

//     // UI state
//     @State private var shouldClearCustomFields: Bool = true
//     @State private var isEditingCustomTip: Bool = false
//     @State private var showingImagePicker = false
//     @State private var showingCamera = false
//     @State private var showingSavedCalculation = false
//     @State private var showingHistory: Bool = false
//     @State private var showingDeleteAlert = false
//     @State private var showingLocationPicker = false

//     // Data
//     @State private var savedCalculation: CalculationHistory?
//     @State private var calculationToDelete: CalculationHistory?
//     @State private var capturedPhoto: Data?
//     @State private var locationManager = LocationManager()
//     @State private var location: CLLocationCoordinate2D?

//     // Constants
//     private let defaultPresets: [Double] = [0.10, 0.15, 0.18, 0.20, 0.25]
//     private let debounceInterval: TimeInterval = 0.5
//     private var tipWorkItem: DispatchWorkItem?

//     // MARK: - Computed Values

//     private var bill: Double { Double(billAmount) ?? 0 }

//     private var totalAmount: Double {
//         bill + computedTipAmount
//     }

//     private var computedTipAmount: Double {
//         switch tipInputMode {
//         case .percentage:
//             return bill * computedTipPercentage
//         case .dollar:
//             if let entered = Double(customTipValue) {
//                 return entered
//             }
//             return bill * tipPercentage
//         }
//     }

//     // When in percentage mode, customTipValue is treated as percentage (e.g., 15 means 15%)
//     // When in dollar mode, customTipValue is treated as tip dollars.
//     private var computedTipPercentage: Double {
//         if bill > 0, let entered = Double(customTipValue), !customTipValue.isEmpty {
//             switch tipInputMode {
//             case .percentage:
//                 return entered / 100
//             case .dollar:
//                 return entered / bill
//             }
//         }
//         return tipPercentage
//     }

//     // Calculate preset percentages based on TipPreset models.
//     // If no presets exist in the model container, use defaultPresets.
//     private var presetPercentageValues: [Double] {
//         if tipPresets.isEmpty {
//             return defaultPresets
//         } else {
//             return tipPresets.map { $0.percentage }
//         }
//     }

//     enum Field: Hashable {
//         case billAmount
//         case customTip
//     }

//     // MARK: - Body

//     var body: some View {
//         NavigationStack {
//             ScrollView {
//                 VStack(spacing: 20) {
//                     headerView
//                     billAndTipSection
//                     tipPercentageSlider
//                     presetButtonsScrollView
//                     summaryCard
//                     CategorySection
//                     // categorySelectorView
//                     imageAndSaveView
//                     saveButton
//                 }
//                 .padding()
//             }
//             .navigationTitle("Tip Easy")
//             .navigationBarTitleDisplayMode(.inline)
//             .toolbar {
//                 ToolbarItem(placement: .topBarTrailing) {
//                     Button {
//                         showingHistory = true
//                     } label: {
//                         Image(systemName: "clock.arrow.circlepath")
//                     }
//                 }

//                 ToolbarItemGroup(placement: .keyboard) {
//                     Spacer()
//                     Button("Done") {
//                         focusedField = nil
//                     }
//                 }
//             }
//             .safeAreaInset(edge: .bottom) {
//                 AdBannerView(adUnitID: "ca-app-pub-3911596373332918/3954995797")
//                     .frame(height: 50)
//             }
//             .contentShape(Rectangle())
//             .onTapGesture {
//                 focusedField = nil // Dismiss keyboard on tap
//             }
//         }
//         .sheet(isPresented: $showingCamera) {
//             ImagePicker(image: $capturedPhoto, sourceType: .camera)
//         }
//         .sheet(isPresented: $showingLocationPicker) {
//             LocationPickerView(location: $location)
//         }
//         .sheet(isPresented: $showingSavedCalculation) {
//             if let calculation = savedCalculation {
//                 SavedCalculationView(calculation: calculation)
//             }
//         }
//         .sheet(isPresented: $showingHistory) {
//             HistoryView(history: history) { calculation in
//                 calculationToDelete = calculation
//                 showingDeleteAlert = true
//             }
//         }
// // Add onboarding sheet
//         .sheet(isPresented: $isOnboardingPresented) {
//             AppOnboardingView(isOnboardingPresented: $isOnboardingPresented)
//         }
//         .alert("Delete Calculation", isPresented: $showingDeleteAlert) {
//             Button("Cancel", role: .cancel) {}
//             Button("Delete", role: .destructive) {
//                 if let calculation = calculationToDelete {
//                     modelContext.delete(calculation)
//                     calculationToDelete = nil
//                 }
//             }
//         }
// .onAppear {

//     // Check if we should show onboarding
//     if !hasSeenOnboarding {
//         isOnboardingPresented = true
//         hasSeenOnboarding = true
//     }
// }
//     }

//     // MARK: - View Components

//     private var headerView: some View {
//         Text("Calculate your tip")
//             .font(.headline)
//             .foregroundColor(.secondary)
//     }

//     private var billAndTipSection: some View {
//         VStack(spacing: 12) {
//             HStack {
//                 Text("Bill Amount")
//                     .font(.subheadline)
//                     .foregroundColor(.secondary)
//                 Spacer()
//             }

//             HStack {
//                 Text("$")
//                     .foregroundColor(.secondary)
//                 TextField("0.00", text: $billAmount)
//                     .keyboardType(.decimalPad)
//                     .focused($focusedField, equals: .billAmount)
//                     .font(.system(size: 34, weight: .medium))
//             }
//             .padding()
//             .background(Color(.systemBackground))
//             .cornerRadius(10)
//             .shadow(color: Color.black.opacity(0.05), radius: 5)
//         }
//     }

//     private var tipPercentageSlider: some View {
//         VStack(spacing: 8) {
//             HStack {
//                 Text("Tip Percentage")
//                     .font(.subheadline)
//                     .foregroundColor(.secondary)
//                 Spacer()
//                 Text("\(Int(selectedTipPercentage * 100))%")
//                     .font(.headline)
//             }

//             Slider(value: $selectedTipPercentage, in: 0 ... 0.40, step: 0.01)
//                 .tint(.blue)
//                 .onChange(of: selectedTipPercentage) { _, newValue in
//                     updateTipFromSlider(newValue)
//                 }
//         }
//         .padding()
//         .background(Color(.systemBackground))
//         .cornerRadius(10)
//         .shadow(color: Color.black.opacity(0.05), radius: 5)
//     }

//     private var presetButtonsScrollView: some View {
//         VStack(spacing: 8) {
//             HStack {
//                 Text("Quick Presets")
//                     .font(.subheadline)
//                     .foregroundColor(.secondary)
//                 Spacer()
//             }

//             ScrollView(.horizontal, showsIndicators: false) {
//                 HStack(spacing: 10) {
//                     ForEach(presetPercentageValues, id: \.self) { percentage in
//                         Button(action: { updateTipFromPreset(percentage) }) {
//                             Text("\(Int(percentage * 100))%")
//                                 .fontWeight(.medium)
//                         }
//                         .buttonStyle(.bordered)
//                         .tint(abs(percentage - tipPercentage) < 0.01 ? .blue : .secondary)
//                     }
//                 }
//                 .padding(.horizontal, 2)
//             }
//         }
//         .padding()
//         .background(Color(.systemBackground))
//         .cornerRadius(10)
//         .shadow(color: Color.black.opacity(0.05), radius: 5)
//     }

//     private var summaryCard: some View {
//         VStack(spacing: 16) {
//             HStack {
//                 Text("Summary")
//                     .font(.headline)
//                 Spacer()
//             }

//             HStack {
//                 Text("Bill")
//                     .foregroundColor(.secondary)
//                 Spacer()
//                 Text(currencyFormatter.string(from: NSNumber(value: bill)) ?? "$0.00")
//             }

//             HStack {
//                 Text("Tip (\(Int(computedTipPercentage * 100))%)")
//                     .foregroundColor(.secondary)
//                 Spacer()
//                 Text(currencyFormatter.string(from: NSNumber(value: computedTipAmount)) ?? "$0.00")
//             }

//             Divider()

//             HStack {
//                 Text("Total")
//                     .fontWeight(.semibold)
//                 Spacer()
//                 Text(currencyFormatter.string(from: NSNumber(value: totalAmount)) ?? "$0.00")
//                     .font(.title3)
//                     .fontWeight(.semibold)
//             }
//         }
//         .padding()
//         .background(Color(.systemBackground))
//         .cornerRadius(10)
//         .shadow(color: Color.black.opacity(0.05), radius: 5)
//     }

//     private var saveButton: some View {
//         Button(action: saveCalculation) {
//             HStack {
//                 Spacer()
//                 Label("Save Calculation", systemImage: "square.and.arrow.down")
//                 Spacer()
//             }
//             .padding()
//             .background(bill > 0 ? Color.blue : Color.gray)
//             .foregroundColor(.white)
//             .cornerRadius(10)
//         }
//         .disabled(bill <= 0)
//         .padding(.vertical, 10)
//     }

//     // Create rows from the presetPercentageValues.
//     private var presetButtonRows: some View {
//         let presets = presetPercentageValues
//         let count = presets.count
//         let splitIndex = (count + 1) / 2
//         let firstRow = count < 4 ? Array(presets) : Array(presets.prefix(splitIndex))
//         let secondRow = count < 4 ? [] : Array(presets.suffix(from: splitIndex))
//         return VStack(spacing: 10) {
//             HStack(spacing: 10) {
//                 ForEach(firstRow, id: \.self) { percentage in
//                     createPresetButton(for: percentage)
//                 }
//             }
//             if !secondRow.isEmpty {
//                 HStack(spacing: 10) {
//                     ForEach(secondRow, id: \.self) { percentage in
//                         createPresetButton(for: percentage)
//                     }
//                 }
//             }
//         }
//     }

//     private var billInputField: some View {
//         HStack {
//             Label("", systemImage: "dollarsign")
//             TextField("Enter bill amount", text: $billAmount)
//                 .keyboardType(.decimalPad)
//                 .textFieldStyle(RoundedTextFieldStyle())
//         }
//     }

//     private var tipPercentageSliderV1: some View {
//         VStack {
//             Slider(value: $selectedTipPercentage, in: 0 ... 0.50, step: 0.01)
//                 .accentColor(.blue)
//                 .onChange(of: selectedTipPercentage) { _, newValue in
//                     updateTipFromSlider(newValue)
//                 }
//             Text("Tip Percentage: \(Int(selectedTipPercentage * 100))%")
//         }
//     }

//     // A single custom tip input field with a toggle to switch between percentage and dollar mode.
//     private var customTipInputField: some View {
//         VStack(alignment: .leading, spacing: 8) {
//             HStack {
//                 TextField(
//                     tipInputMode == .percentage ? "Enter tip percentage" : "Enter tip amount",
//                     text: $customTipValue, onEditingChanged: handleCustomTipEditing
//                 )
//                 .keyboardType(.decimalPad)
//                 .textFieldStyle(RoundedTextFieldStyle())

//                 Button(action: {
//                     tipInputMode = .percentage
//                 }) {
//                     Label("", systemImage: "percent")
//                         .padding()
//                         // .frame(maxWidth: .infinity)
//                         .background(
//                             tipInputMode == .percentage ? Color.blue : Color.gray.opacity(0.3)
//                         )
//                         .foregroundColor(.white)
//                         .cornerRadius(8)
//                 }
//                 Button(action: {
//                     tipInputMode = .dollar
//                 }) {
//                     Label("", systemImage: "dollarsign")
//                         .padding()
//                         // .frame(maxWidth: .infinity)
//                         .background(tipInputMode == .dollar ? Color.blue : Color.gray.opacity(0.3))
//                         .foregroundColor(.white)
//                         .cornerRadius(8)
//                 }
//             }
//         }
//     }

//     private var summaryView: some View {
//         VStack(spacing: 10) {
//             Text("Bill: $\(bill, specifier: "%.2f")")
//             Text(
//                 "Tip: $\(computedTipAmount, specifier: "%.2f") (\(Int(computedTipPercentage * 100))%)"
//             )
//             Divider()
//             HStack(alignment: .center) {
//                 Text("Total: $\(totalAmount, specifier: "%.2f")")
//             }
//         }
//         .font(.title3)
//         .fontWeight(.medium)
//         .padding()
//         .animation(.default, value: totalAmount)
//     }

//     private var categorySelectorView: some View {
//         Picker("Category", selection: $selectedCategory) {
//             ForEach(ExpenseCategory.allCases, id: \.self) { category in
//                 Label(category.rawValue, systemImage: category.icon)
//             }
//         }
//         .pickerStyle(.menu)
//         .padding(.vertical, 5)
//     }

//     private var CategorySection: some View {
//         VStack(spacing: 8) {
//             HStack {
//                 Text("Category")
//                     .font(.subheadline)
//                     .foregroundColor(.secondary)
//                 Spacer()
//             }
//             ScrollView(.horizontal, showsIndicators: false) {
//                 HStack(spacing: 8) {
//                     ForEach(ExpenseCategory.allCases, id: \.self) { category in
//                         Button(action: {
//                             selectedCategory = category
//                             // calculation.category = category
//                         }) {
//                             HStack {
//                                 Image(systemName: category.icon)
//                                 Text(category.rawValue)
//                             }
//                             .padding(.horizontal, 12)
//                             .padding(.vertical, 8)
//                             .background(selectedCategory == category ? Color.blue : Color.gray.opacity(0.2))
//                             .foregroundColor(selectedCategory == category ? .white : .primary)
//                             .cornerRadius(20)
//                         }
//                     }
//                 }
//                 .padding(.vertical, 4)
//             }
//         }
//     }

//     private var imageAndSaveView: some View {
//         HStack {
//             Button(action: { showingCamera = true }) {
//                 Label("Add Photo", systemImage: "camera")
//             }

//             Button(action: saveCalculation) {
//                 Label("Save", systemImage: "square.and.arrow.down")
//             }

//             //            NavigationLink {
//             //                HistoryView(history: history)
//             //            } label: {
//             //                Label("History", systemImage: "clock")
//             //            }
//         }
//         .padding()
//     }

//     private var LocationSection: some View {
//         Section("Location") {
//             if let location = location {
//                 Map(position: .constant(.region(MKCoordinateRegion(
//                     center: location,
//                     span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
//                 )))) {
//                     Marker("", coordinate: location)
//                 }
//                 .frame(height: 200)
//                 .cornerRadius(12)

//                 Button(action: { showingLocationPicker = true }) {
//                     Label("Update Location", systemImage: "location")
//                 }
//             } else {
//                 Button(action: { showingLocationPicker = true }) {
//                     Label("Add Location", systemImage: "location.add")
//                 }
//             }
//         }
//     }

//     // MARK: - Helper Methods

//     private var currencyFormatter: NumberFormatter {
//         let formatter = NumberFormatter()
//         formatter.numberStyle = .currency
//         formatter.minimumFractionDigits = 2
//         formatter.maximumFractionDigits = 2
//         return formatter
//     }

//     private func updateTipFromSlider(_ newValue: Double) {
//         withAnimation {
//             tipPercentage = newValue
//             selectedTipPercentage = newValue
//             if shouldClearCustomFields { clearCustomTipField() }
//         }
//     }

//     private func saveCalculation() {
//         let calculation = CalculationHistory(
//             billAmount: bill,
//             tipPercentage: computedTipPercentage,
//             tipAmount: computedTipAmount,
//             totalAmount: totalAmount,
//             timestamp: Date(),
//             location: locationManager.lastLocation?.coordinate,
//             photo: capturedPhoto,
//             category: selectedCategory
//         )

//         modelContext.insert(calculation)
//         try? modelContext.save()

//         // Show confirmation
//         savedCalculation = calculation
//         showingSavedCalculation = true

//         // Clear photo for next calculation
//         capturedPhoto = nil
//     }

//     private func createPresetButton(for percentage: Double) -> some View {
//         Button(action: {
//             shouldClearCustomFields = true
//             updateTipFromPreset(percentage)
//         }) {
//             Text("\(Int(percentage * 100))%")
//                 .padding()
//                 // .frame(maxWidth: 20)
//                 .background(
//                     (abs(percentage - tipPercentage) < 0.001)
//                         ? Color.blue.opacity(0.7)
//                         : Color.blue
//                 )
//                 .foregroundColor(.white)
//                 .cornerRadius(8)
//         }
//     }

//     private func updateTipFromSliderV1(_ newValue: Double) {
//         withAnimation {
//             tipPercentage = newValue
//             selectedTipPercentage = newValue
//             if shouldClearCustomFields { clearCustomTipField() }
//             cancelTipWorkItem()
//         }
//     }

//     private func updateTipFromPreset(_ percentage: Double) {
//         withAnimation {
//             tipPercentage = percentage
//             selectedTipPercentage = percentage
//             if shouldClearCustomFields { clearCustomTipField() }
//             cancelTipWorkItem()
//         }
//     }

//     private func clearCustomTipField() {
//         customTipValue = ""
//     }

//     private func cancelTipWorkItem() {
//         tipWorkItem?.cancel()
//     }

// //    private func debouncedCustomTipUpdate(oldValue: String, newValue: String) {
// //        cancelTipWorkItem()
// //        let workItem = DispatchWorkItem {
// //            updateCustomTip()
// //        }
// //        tipWorkItem = workItem
// //        DispatchQueue.main.asyncAfter(deadline: .now() + debounceInterval, execute: workItem)
// //    }

//     private func handleCustomTipEditing(_ editing: Bool) {
//         isEditingCustomTip = editing
//         if !editing {
//             updateCustomTip()
//         }
//     }

//     private func updateCustomTip() {
//         guard !customTipValue.trimmingCharacters(in: .whitespaces).isEmpty, bill > 0 else { return }
//         withAnimation {
//             if tipInputMode == .percentage {
//                 let entered = Double(customTipValue) ?? 0
//                 tipPercentage = entered / 100
//             } else {
//                 let entered = Double(customTipValue) ?? 0
//                 tipPercentage = entered / bill
//             }
//             selectedTipPercentage = tipPercentage
//             shouldClearCustomFields = false
//         }
//     }

// //    private func saveCalculationV1() {
// //        let calculation = CalculationHistory(
// //            billAmount: bill,
// //            tipPercentage: tipPercentage,
// //            tipAmount: computedTipAmount,
// //            totalAmount: totalAmount,
// //            timestamp: Date(),
// //            location: locationManager.lastLocation?.coordinate,
// //            photo: capturedPhoto,
// //            category: selectedCategory
// //        )
// //        modelContext.insert(calculation)
// //        try? modelContext.save()
// //
// //        savedCalculation = calculation
// //        showingSavedCalculation = true
// //    }

//     private func loadTransferable(from item: PhotosPickerItem) {
//         item.loadTransferable(type: Data.self) { result in
//             switch result {
//             case .success(let data):
//                 DispatchQueue.main.async {
//                     self.capturedPhoto = data
//                 }
//             case .failure(let error):
//                 print("Error loading image: \(error)")
//             }
//         }
//     }
// }

// // MARK: - Custom Styles

// struct RoundedTextFieldStyle: TextFieldStyle {
//     func _body(configuration: TextField<Self._Label>) -> some View {
//         configuration
//             .keyboardType(.decimalPad)
//             .submitLabel(.done)
//             .padding()
//             .background(Color(.systemGray6))
//             .cornerRadius(8)
//     }
// }

// struct TipCalculatorView_Previews: PreviewProvider {
//     static var previews: some View {
//         Group {
//             TipCalculatorView()
//                 .preferredColorScheme(.light)
//             TipCalculatorView()
//                 .preferredColorScheme(.dark)
//         }
//     }
// }
