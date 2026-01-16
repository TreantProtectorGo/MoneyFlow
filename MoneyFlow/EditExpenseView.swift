//
//  EditExpenseView.swift
//  MoneyFlow
//
//  Created by Wing - on 2026/1/3.
//

import SwiftUI
import SwiftData

struct EditExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    let expense: Expense
    let modelContext: ModelContext
    
    @State private var amount: String = ""
    @State private var category: String = ""
    @State private var currency: String = ""
    @State private var date: Date = Date()
    @State private var description: String = ""
    
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
                        // Amount
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
                            
                            // Date
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
                        
                        // Description - OPTIONAL
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
                    }
                    .padding(.top, 8)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Edit Expense")
            .navigationBarTitleDisplayMode(.inline)
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
            .onAppear {
                // Load existing data
                amount = String(expense.amount)
                category = expense.category
                currency = expense.currency
                date = expense.date
                
                // Load description: if merchant == category, it was auto-generated
                description = expense.merchant == expense.category ? "" : expense.merchant
            }
        }
    }
    
    private var isFormValid: Bool {
        // Only amount required
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
        
        expense.amount = amountValue
        expense.currency = currency
        expense.merchant = merchantName
        expense.category = category
        expense.date = date
        expense.note = nil
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error updating expense: \(error)")
        }
    }
}

#Preview {
    EditExpenseView(
        expense: Expense(
            amount: 150.0,
            currency: "HKD",
            merchant: "Starbucks",
            category: "Food"
        ),
        modelContext: ModelContext(
            try! ModelContainer(for: Expense.self, User.self, Group.self)
        )
    )
}
