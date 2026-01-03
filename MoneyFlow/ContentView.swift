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
                // iOS 26 gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.97, blue: 1.0),
                        Color(red: 0.98, green: 0.95, blue: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Total expense card
                        TotalExpenseCard(expenses: expenses)
                        
                        // Expense list
                        if expenses.isEmpty {
                            EmptyStateView()
                        } else {
                            LazyVStack(spacing: 12) {
                                ForEach(expenses) { expense in
                                    NavigationLink {
                                        ExpenseDetailView(expense: expense, modelContext: modelContext)
                                    } label: {
                                        ExpenseRowView(expense: expense)
                                    }
                                    .buttonStyle(.plain)
                                }
                                .onDelete(perform: deleteExpenses)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
                .scrollIndicators(.hidden)
            }
            .navigationTitle("MoneyFlow")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {
                        showingAddExpense = true
                    }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.blue)
                    }
                }
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView(modelContext: modelContext)
            }
        }
        .tint(.blue)
    }
    
    private func deleteExpenses(offsets: IndexSet) {
        withAnimation(.smooth) {
            for index in offsets {
                modelContext.delete(expenses[index])
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
        VStack(alignment: .leading, spacing: 12) {
            Label("Total Expenses", systemImage: "chart.line.uptrend.xyaxis")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            
            Text("HK$ \(totalAmount, specifier: "%.2f")")
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .foregroundStyle(.primary)
                .contentTransition(.numericText())
            
            HStack(spacing: 4) {
                Image(systemName: "arrow.up.circle.fill")
                    .foregroundStyle(.green)
                    .imageScale(.small)
                Text("\(expenses.count) transactions")
                    .font(.footnote.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(24)
        .background {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.06), radius: 20, x: 0, y: 8)
                .shadow(color: .black.opacity(0.04), radius: 1, x: 0, y: 1)
        }
    }
}

// MARK: - Expense Row
struct ExpenseRowView: View {
    let expense: Expense
    
    var categoryIcon: String {
        switch expense.category {
        case "Food": return "fork.knife"
        case "Transport": return "car.fill"
        case "Entertainment": return "theatermasks.fill"
        case "Shopping": return "cart.fill"
        case "Travel": return "airplane"
        case "Medical": return "cross.case.fill"
        default: return "dollarsign.circle.fill"
        }
    }
    
    var categoryColor: Color {
        switch expense.category {
        case "Food": return .orange
        case "Transport": return .blue
        case "Entertainment": return .purple
        case "Shopping": return .pink
        case "Travel": return .cyan
        case "Medical": return .red
        default: return .gray
        }
    }
    
    var body: some View {
        HStack(spacing: 16) {
            // Category icon
            ZStack {
                Circle()
                    .fill(categoryColor.opacity(0.15))
                    .frame(width: 56, height: 56)
                
                Image(systemName: categoryIcon)
                    .font(.title3)
                    .symbolRenderingMode(.hierarchical)
                    .foregroundStyle(categoryColor)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 6) {
                Text(expense.merchant)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                
                HStack(spacing: 8) {
                    Text(expense.category)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    
                    Circle()
                        .fill(.tertiary)
                        .frame(width: 3, height: 3)
                    
                    Text(expense.date, style: .date)
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
            }
            
            Spacer(minLength: 0)
            
            // Amount
            VStack(alignment: .trailing, spacing: 4) {
                Text("$\(expense.amount, specifier: "%.2f")")
                    .font(.body.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.primary)
                
                Text(expense.currency)
                    .font(.caption2.weight(.medium))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.background)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
                .shadow(color: .black.opacity(0.02), radius: 1, x: 0, y: 1)
        }
    }
}

// MARK: - Empty State View
struct EmptyStateView: View {
    var body: some View {
        ContentUnavailableView {
            Label("No Expenses", systemImage: "wallet.pass")
        } description: {
            Text("Track your spending by adding your first expense")
        } actions: {
            // Empty - button in toolbar
        }
        .symbolVariant(.fill)
        .padding(.vertical, 60)
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Expense.self, User.self, Group.self], inMemory: true)
}
