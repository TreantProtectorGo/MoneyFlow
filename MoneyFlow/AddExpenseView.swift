//
//  AddExpenseView.swift
//  MoneyFlow
//
//  Created by Wing - on 2026/1/3.
//

import SwiftUI
import SwiftData

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    let modelContext: ModelContext
    
    @State private var amount: String = ""
    @State private var category: String = "Food"
    @State private var currency: String = "HKD"
    @State private var date: Date = Date()
    @State private var description: String = ""
    
    // Location
    @State private var locationData: LocationData?
    @State private var isLoadingLocation: Bool = false
    
    @FocusState private var isAmountFocused: Bool
    
    var categories: [String] { CategoryManager.shared.allCategoryNames }
    var currencies: [String] { CurrencyManager.shared.allCurrencyCodes }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Amount - Large prominent input (AUTO-FOCUSED)
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                Picker("Currency", selection: $currency) {
                                    ForEach(currencies, id: \.self) { curr in
                                        Text(curr).tag(curr)
                                    }
                                }
                                .pickerStyle(.menu)
                                
                                TextField("0.00", text: $amount)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 36, weight: .bold, design: .rounded))
                                    .multilineTextAlignment(.trailing)
                                    .foregroundColor(.primary)
                                    .focused($isAmountFocused)
                            }
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                            )
                        }
                        .glassEffect(.regular, in: .rect(cornerRadius: 24))
                        .padding(.horizontal)
                        
                        // Category & Date Card
                        VStack(spacing: 0) {
                            // Category

                            VStack(alignment: .leading, spacing: 10) {
                                Text("Category")
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                
                                LazyVGrid(
                                    columns: [
                                        GridItem(.flexible(), spacing: 10),
                                        GridItem(.flexible(), spacing: 10),
                                        GridItem(.flexible(), spacing: 10)
                                    ],
                                    spacing: 10
                                ) {
                                    ForEach(categories, id: \.self) { cat in
                                        CategoryChip(
                                            category: cat,
                                            isSelected: category == cat
                                        ) {
                                            let generator = UIImpactFeedbackGenerator(style: .light)
                                            generator.impactOccurred()
                                            
                                            category = cat
                                        }
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                            
                            Divider()
                                .padding(.leading, 16)
                            
                            // Date - List Item Style
                            HStack {
                                Text("Date")
                                    .foregroundColor(.primary)
                                
                                Spacer()
                                
                                DatePicker("", selection: $date, displayedComponents: [.date])
                                    .labelsHidden()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                        )
                        .glassEffect(.regular, in: .rect(cornerRadius: 24))
                        .padding(.horizontal)
                        
                        // Description - OPTIONAL (Combined merchant + note)
                        VStack(spacing: 0) {
                            HStack(alignment: .top) {
                                TextField("Description (Optional)", text: $description, axis: .vertical)
                                    .foregroundColor(.primary)
                                    .lineLimit(2...4)
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                        }
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                        )
                        .glassEffect(.regular, in: .rect(cornerRadius: 24))
                        .padding(.horizontal)
                        
                        // Location Card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Location")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                
                                Spacer()
                                
                                if isLoadingLocation {
                                    ProgressView()
                                        .scaleEffect(0.8)
                                } else {
                                    Button(action: {
                                        Task {
                                            isLoadingLocation = true
                                            locationData = await LocationService.shared.getCurrentLocation()
                                            if let suggestedCurrency = LocationService.shared.suggestCurrency(for: locationData?.country) {
                                                currency = suggestedCurrency
                                            }
                                            isLoadingLocation = false
                                        }
                                    }) {
                                        Image(systemName: locationData != nil ? "arrow.clockwise" : "location.circle")
                                            .font(.system(size: 16, weight: .medium))
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            
                            if let location = locationData {
                                Text(location.displayString)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .lineLimit(2)
                            } else {
                                Text("Tap to add location")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .padding(16)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                        )
                        .glassEffect(.regular, in: .rect(cornerRadius: 24))
                        .padding(.horizontal)
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                // Auto-focus amount field - saves 1 tap!
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isAmountFocused = true
                }
                
                // Auto-request location
                Task {
                    isLoadingLocation = true
                    locationData = await LocationService.shared.getCurrentLocation()
                    if let suggestedCurrency = LocationService.shared.suggestCurrency(for: locationData?.country) {
                        currency = suggestedCurrency
                    }
                    isLoadingLocation = false
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveExpense()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid)
                    .foregroundColor(isFormValid ? .blue : .gray.opacity(0.5))
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        // Only amount is required now!
        guard let amountValue = Double(amount), amountValue > 0 else {
            return false
        }
        return true
    }
    
    private func saveExpense() {
        guard let amountValue = Double(amount) else { return }
        
        // Smart default: Use description if provided, otherwise use category name
        let merchantName = description.trimmingCharacters(in: .whitespaces).isEmpty 
            ? category 
            : description.trimmingCharacters(in: .whitespaces)
        
        let newExpense = Expense(
            amount: amountValue,
            currency: currency,
            merchant: merchantName,
            category: category,
            date: date,
            note: nil,
            latitude: locationData?.latitude,
            longitude: locationData?.longitude,
            locationAddress: locationData?.displayString
        )
        
        modelContext.insert(newExpense)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving expense: \(error)")
        }
    }
}

// MARK: - Category Chip (Compact horizontal design)
struct CategoryChip: View {
    let category: String
    let isSelected: Bool
    let action: () -> Void
    
    var icon: String {
        switch category {
        case "Food": return "fork.knife"
        case "Transport": return "car.fill"
        case "Entertainment": return "gamecontroller.fill"
        case "Shopping": return "cart.fill"
        case "Travel": return "airplane"
        case "Medical": return "cross.case.fill"
        case "Other": return "dollarsign.circle.fill"
        default: return "tag.fill"
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 22, weight: .medium)) 
                
                Text(category)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1) 
                    .minimumScaleFactor(0.7) 
            }
            .frame(maxWidth: .infinity)
            .frame(height: 80)
            .foregroundColor(isSelected ? .white : .primary)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? Color.blue : Color(.systemGray6)) 
            )
            .scaleEffect(isSelected ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AddExpenseView(modelContext: ModelContext(
        try! ModelContainer(for: Expense.self, User.self, Group.self)
    ))
}
