//
//  SavedCalculationView.swift
//  SwiftUI-TipEasy
//
//  Created by Chirag Kular on 4/7/25.
//
import MapKit
import SwiftData
import SwiftUI

struct SavedCalculationView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var calculation: CalculationHistory
    
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var showingLocationPicker = false
    @State private var selectedCategory: ExpenseCategory
    
    init(calculation: CalculationHistory) {
        self.calculation = calculation
        _selectedCategory = State(initialValue: calculation.category)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                CategorySection
                
                LocationSection
                
                if let photo = calculation.photo {
                    Section("Receipt Photo") {
                        Image(uiImage: UIImage(data: photo) ?? UIImage())
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 200)
                        
                        Button("Replace Photo") {
                            showingCamera = true
                        }
                    }
                } else {
                    Button("Add Photo") {
                        showingCamera = true
                    }
                }
            }
            .navigationTitle("Saved Calculation")
            .navigationBarTitleDisplayMode(.inline)
//            .toolbar {
//                ToolbarItemGroup(placement: .navigationBarLeading) {
//                    Button("Done") {
//                        try? modelContext.save()
//                        dismiss()
//                    }
//                }
//            }
        }
        .sheet(isPresented: $showingLocationPicker) {
            LocationPickerView(location: $calculation.location)
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(image: $calculation.photo, sourceType: .camera)
        }
    }
    
    private var CategorySection: some View {
        Section("Category") {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(ExpenseCategory.allCases, id: \.self) { category in
                        Button(action: {
                            selectedCategory = category
                            calculation.category = category
                        }) {
                            HStack {
                                Image(systemName: category.icon)
                                Text(category.rawValue)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(selectedCategory == category ? Color.blue : Color.gray.opacity(0.2))
                            .foregroundColor(selectedCategory == category ? .white : .primary)
                            .cornerRadius(20)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
        }
    }
    
    private var DetailsSection: some View {
        Section("Details") {
            HStack {
                Text("Bill Amount")
                Spacer()
                TextField("Bill", value: $calculation.billAmount, format: .currency(code: "USD"))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            }
            
            HStack {
                Text("Tip")
                Spacer()
                TextField("Tip", value: $calculation.tipAmount, format: .currency(code: "USD"))
                    .keyboardType(.decimalPad)
                    .multilineTextAlignment(.trailing)
            }
            
            HStack {
                Text("Total")
                Spacer()
                Text(calculation.totalAmount, format: .currency(code: "USD"))
            }
        }
    }

    private var LocationSection: some View {
        Section("Location") {
            if let location = calculation.location {
                Map(position: .constant(.region(MKCoordinateRegion(
                    center: location,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)))))
                {
                    Marker("", coordinate: location)
                }
                .frame(height: 200)
                .cornerRadius(12)

                Button(action: { showingLocationPicker = true }) {
                    Label("Update Location", systemImage: "location")
                }
            } else {
                Button(action: { showingLocationPicker = true }) {
                    Label("Add Location", systemImage: "location.add")
                }
            }
        }
    }
}

#Preview {
    SavedCalculationView(calculation: CalculationHistory.sampleTransactions.first!)
}
