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
                        .padding(.horizontal)
                        
                        // Category & Date Card
                        VStack(spacing: 0) {
                            // Category - Horizontal Scroll
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Category")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 16)
                                
                                ScrollView(.horizontal, showsIndicators: false) {
                                    HStack(spacing: 12) {
                                        ForEach(categories, id: \.self) { cat in
                                            CategoryChip(
                                                category: cat,
                                                isSelected: category == cat
                                            ) {
                                                withAnimation(.spring(response: 0.3)) {
                                                    category = cat
                                                }
                                            }
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                            }
                            .padding(.vertical, 12)
                            
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
            note: nil  // We've combined merchant + note into one field
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
    
    var categoryIcon: String {
        CategoryManager.shared.icon(for: category)
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: categoryIcon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : .blue)
                
                Text(category)
                    .font(.caption2)
                    .foregroundColor(isSelected ? .white : .secondary)
            }
            .frame(width: 70)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.blue : Color(.systemGray6))
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AddExpenseView(modelContext: ModelContext(
        try! ModelContainer(for: Expense.self, User.self, Group.self)
    ))
}
