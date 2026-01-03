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
    @State private var merchant: String = ""
    @State private var category: String = ""
    @State private var currency: String = ""
    @State private var date: Date = Date()
    @State private var note: String = ""
    
    let categories = ["Food", "Transport", "Entertainment", "Shopping", "Travel", "Medical", "Other"]
    let currencies = ["HKD", "USD", "CNY", "JPY", "EUR", "GBP"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Amount input section
                        VStack(spacing: 8) {
                            Text("Amount")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: 12) {
                                // Currency picker
                                Picker("Currency", selection: $currency) {
                                    ForEach(currencies, id: \.self) { curr in
                                        Text(curr).tag(curr)
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(.ultraThinMaterial)
                                )
                                
                                TextField("0.00", text: $amount)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .multilineTextAlignment(.trailing)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(.ultraThinMaterial)
                                    )
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.white.opacity(0.5))
                        )
                        
                        // Merchant name
                        VStack(spacing: 8) {
                            Text("Merchant")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            TextField("e.g., Starbucks", text: $merchant)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(.ultraThinMaterial)
                                )
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.white.opacity(0.5))
                        )
                        
                        // Category selection
                        VStack(spacing: 8) {
                            Text("Category")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(categories, id: \.self) { cat in
                                    CategoryButton(
                                        category: cat,
                                        isSelected: category == cat
                                    ) {
                                        withAnimation(.spring(response: 0.3)) {
                                            category = cat
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.white.opacity(0.5))
                        )
                        
                        // Date picker
                        VStack(spacing: 8) {
                            Text("Date")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            DatePicker("", selection: $date, displayedComponents: [.date])
                                .datePickerStyle(.graphical)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(.ultraThinMaterial)
                                )
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.white.opacity(0.5))
                        )
                        
                        // Note
                        VStack(spacing: 8) {
                            Text("Note (Optional)")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            TextField("Enter note...", text: $note, axis: .vertical)
                                .lineLimit(3...6)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(.ultraThinMaterial)
                                )
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.white.opacity(0.5))
                        )
                    }
                    .padding()
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
                }
            }
            .onAppear {
                // Load existing data
                amount = String(expense.amount)
                merchant = expense.merchant
                category = expense.category
                currency = expense.currency
                date = expense.date
                note = expense.note ?? ""
            }
        }
    }
    
    private var isFormValid: Bool {
        guard let amountValue = Double(amount), amountValue > 0 else {
            return false
        }
        return !merchant.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private func saveExpense() {
        guard let amountValue = Double(amount) else { return }
        
        expense.amount = amountValue
        expense.currency = currency
        expense.merchant = merchant
        expense.category = category
        expense.date = date
        expense.note = note.isEmpty ? nil : note
        
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
