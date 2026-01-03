//
//  ContentView.swift
//  MoneyFlow
//
//  Created by Wing - on 2026/1/2.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Expense.date, order: .reverse) private var expenses: [Expense]
    @State private var showingAddExpense = false
    
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
                
                VStack(spacing: 0) {
                    // Total expense card
                    TotalExpenseCard(expenses: expenses)
                        .padding()
                    
                    // Expense list
                    if expenses.isEmpty {
                        EmptyStateView()
                    } else {
                        ExpenseListView(expenses: expenses, modelContext: modelContext)
                    }
                }
            }
            .navigationTitle("💰 MoneyFlow")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddExpense = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .purple],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                }
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView(modelContext: modelContext)
            }
        }
    }
}

// MARK: - Total Expense Card
struct TotalExpenseCard: View {
    let expenses: [Expense]
    
    var totalAmount: Double {
        expenses.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Total Expenses")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("HK$ \(totalAmount, specifier: "%.2f")")
                .font(.system(size: 36, weight: .bold, design: .rounded))
                .foregroundStyle(
                    LinearGradient(
                        colors: [.blue, .purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
            
            Text("\(expenses.count) transactions")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
        )
    }
}

// MARK: - Expense List
struct ExpenseListView: View {
    let expenses: [Expense]
    let modelContext: ModelContext
    
    var body: some View {
        List {
            ForEach(expenses) { expense in
                NavigationLink {
                    ExpenseDetailView(expense: expense, modelContext: modelContext)
                } label: {
                    ExpenseRowView(expense: expense)
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .onDelete(perform: deleteExpenses)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    private func deleteExpenses(offsets: IndexSet) {
        withAnimation {
            for index in offsets {
                modelContext.delete(expenses[index])
            }
        }
    }
}

// MARK: - Expense Row
struct ExpenseRowView: View {
    let expense: Expense
    
    var categoryIcon: String {
        switch expense.category {
        case "Food": return "🍜"
        case "Transport": return "🚗"
        case "Entertainment": return "🎮"
        case "Shopping": return "🛒"
        case "Travel": return "✈️"
        case "Medical": return "💊"
        default: return "💰"
        }
    }
    
    var body: some View {
        HStack(spacing: 15) {
            // Category icon
            Text(categoryIcon)
                .font(.largeTitle)
                .frame(width: 60, height: 60)
                .background(
                    Circle()
                        .fill(.ultraThinMaterial)
                )
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(expense.merchant)
                    .font(.headline)
                
                HStack {
                    Text(expense.category)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(.blue.opacity(0.2))
                        )
                    
                    Text(expense.date, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Amount
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(expense.currency) $\(expense.amount, specifier: "%.2f")")
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundColor(.primary)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 5, x: 0, y: 2)
        )
        .padding(.vertical, 4)
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 80))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("No expenses yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Tap the + button to add your first expense")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxHeight: .infinity)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Expense.self, User.self, Group.self], inMemory: true)
}
