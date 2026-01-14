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
    @State private var showingCamera = false
    @State private var showingVoiceInput = false
    
    
    var currentMonthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: Date())
    }
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
                    // Month navigation
                    HStack {
                        Button(action: {
                            // TODO: Navigate to previous month
                        }) {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                                .foregroundColor(.primary)
                        }
                        
                        Spacer()
                        
                        Text(currentMonthYear)
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                        Spacer()
                        
                        Button(action: {
                            // TODO: Navigate to next month
                        }) {
                            Image(systemName: "chevron.right")
                                .font(.title3)
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 12)
                    
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
            .navigationBarTitleDisplayMode(.inline)
            .overlay(alignment: .bottomTrailing) {
                // Main Add Button
                Menu {
                    Button(action: {
                        showingAddExpense = true
                    }) {
                        Label("Manual Entry", systemImage: "pencil")
                    }
                    
                    Button(action: {
                        showingCamera = true
                    }) {
                        Label("Scan Receipt", systemImage: "camera")
                    }
                    
                    Button(action: {
                        showingVoiceInput = true
                    }) {
                        Label("Voice Input", systemImage: "mic")
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                        .frame(width: 60, height: 60)
                        .background(
                            LinearGradient(
                                colors: [.blue, .purple],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .clipShape(Circle())
                        .shadow(color: .blue.opacity(0.4), radius: 15, x: 0, y: 5)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView(modelContext: modelContext)
            }
.sheet(isPresented: $showingCamera) {
    CameraView { _ in }
}
.sheet(isPresented: $showingVoiceInput) {
    VoiceInputView { _ in }
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
        VStack(alignment: .leading, spacing: 6) {
            Text("Total Expenses")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("HK$ \(totalAmount, specifier: "%.2f")")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("\(expenses.count) transactions")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
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
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteExpense(expense)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }
    
    private func deleteExpense(_ expense: Expense) {
        withAnimation {
            modelContext.delete(expense)
            try? modelContext.save()
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
        case "Entertainment": return "gamecontroller.fill"
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
        HStack(spacing: 12) {
            // Category icon - unified color scheme
            Image(systemName: categoryIcon)
                .font(.title3)
                .foregroundColor(.white)
                .frame(width: 50, height: 50)
                .background(
                    Circle()
                        .fill(.blue)
                )
            
            // Info
            VStack(alignment: .leading, spacing: 2) {
                Text(expense.merchant)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                HStack(spacing: 8) {
                    Text(expense.category)
                        .font(.caption2)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(.blue.opacity(0.15))
                        )
                        .foregroundColor(.blue)
                    
                    Text(expense.date, style: .date)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Amount - solid color
            Text("\(expense.currency) $\(expense.amount, specifier: "%.2f")")
                .font(.system(.callout, design: .rounded, weight: .semibold))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.05), radius: 3, x: 0, y: 1)
        )
        .padding(.vertical, 2)
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
