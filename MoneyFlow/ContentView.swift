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
    @State private var selectedDate = Date()
    @State private var showingMonthPicker = false
    
    // Search & Filter States
    @State private var searchText = ""
    @State private var isSearchExpanded = false
    @State private var showingFilters = false
    @State private var selectedCategories: Set<String> = []
    @State private var minAmount = ""
    @State private var maxAmount = ""
    @State private var dateRange: DateRange = .all

    
    var currentMonthYear: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedDate)
    }
    
    var filteredExpenses: [Expense] {
        var result = Calendar.filterExpenses(expenses, for: selectedDate)
        
        // Search filter
        if !searchText.isEmpty {
            result = result.filter { expense in
                expense.merchant.localizedCaseInsensitiveContains(searchText) ||
                expense.category.localizedCaseInsensitiveContains(searchText) ||
                (expense.note ?? "").localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Category filter
        if !selectedCategories.isEmpty {
            result = result.filter { selectedCategories.contains($0.category) }
        }
        
        // Amount filter
        if let min = Double(minAmount), min > 0 {
            result = result.filter { $0.amount >= min }
        }
        if let max = Double(maxAmount), max > 0 {
            result = result.filter { $0.amount <= max }
        }
        
        return result
    }
    
    var hasActiveFilters: Bool {
        !selectedCategories.isEmpty || !minAmount.isEmpty || !maxAmount.isEmpty
    }
    
    func previousMonth() {
        if let newDate = Calendar.previousMonth(from: selectedDate) {
            selectedDate = newDate
        }
    }
    
    func nextMonth() {
        if let newDate = Calendar.nextMonth(from: selectedDate) {
            selectedDate = newDate
        }
    }
    var body: some View {
        NavigationStack {
            ZStack {

                VStack(spacing: 0) {
                    // Month navigation 
                    HStack {
                        Button(action: previousMonth) {
                            Image(systemName: "chevron.left")
                                .font(.title3)
                                .foregroundColor(.primary)
                                .frame(width: 44, height: 44)
                                .glassEffect(.regular.interactive(), in: Circle())
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        }
                        
                        Spacer()
                        
                        Button(action: { showingMonthPicker = true }) {
                            HStack(spacing: 8) {
                                Text(currentMonthYear)
                                    .font(.system(.title3, design: .rounded).weight(.bold))
                                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                                Image(systemName: "chevron.down").font(.caption).bold()
                            }
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .glassEffect(.regular.interactive(), in: Capsule())
                        }
                        .foregroundStyle(.primary)
                        
                        Spacer()
                        
                        Button(action: nextMonth) {
                            Image(systemName: "chevron.right")
                                .font(.title3)
                                .foregroundColor(.primary)
                                .frame(width: 44, height: 44)
                                .glassEffect(.regular.interactive(), in: Circle())
                                .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 8)
                    .padding(.bottom, 8)
                    
                    
                    // Search & Filter Bar
                    HStack(spacing: 12) {
                        SearchBarView(searchText: $searchText, isExpanded: $isSearchExpanded)
                        
                        if !isSearchExpanded {
                            // Filter Button
                            Button(action: {
                                showingFilters = true
                            }) {
                                Image(systemName: hasActiveFilters ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                                    .font(.system(size: 18, weight: .medium))
                                    .foregroundColor(hasActiveFilters ? .blue : .secondary)
                                    .frame(width: 44, height: 44)
                                    .glassEffect(.regular.interactive(), in: Circle())
                                    .background(
                                        Circle()
                                            .fill(Color.white)
                                            .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                    
                    // Total expense card
                    TotalExpenseCard(expenses: filteredExpenses)
                        .padding()
                        .glassEffect(in: .rect(cornerRadius: 16.0))
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                        .padding(.vertical, 12)
                        .padding(.horizontal, 16)
                    
                    // Expense list
                    if filteredExpenses.isEmpty {
                        EmptyStateView()
                    } else {
                        ExpenseListView(expenses: filteredExpenses, modelContext: modelContext)
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
                        .font(.title3)
                        .foregroundColor(.primary)
                        .frame(width: 60, height: 60)
                        .glassEffect(.regular.interactive(), in: Circle())
                        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                }
                .padding(.trailing, 20)
                .padding(.bottom, 20)
            }
            .sheet(isPresented: $showingAddExpense) {
                AddExpenseView(modelContext: modelContext)
            }
            .sheet(isPresented: $showingCamera) {
                CameraView()
            }
            .sheet(isPresented: $showingVoiceInput) {
                VoiceInputView { extractedData in
                    // Create expense from voice data
                    if extractedData.isValid {
                        let expense = Expense(
                            amount: extractedData.amount ?? 0,
                            currency: extractedData.currency ?? "HKD",
                            merchant: extractedData.merchant ?? "Unknown",
                            category: extractedData.category ?? "Other",
                            date: extractedData.date ?? Date()
                        )
                        modelContext.insert(expense)
                        try? modelContext.save()
                    }
                }
            }
            .sheet(isPresented: $showingMonthPicker) {
                MonthPickerView(selectedDate: $selectedDate)
                    .presentationDetents([.height(250)])
            }
        }
            .sheet(isPresented: $showingFilters) {
                FilterSheet(
                    selectedCategories: $selectedCategories,
                    minAmount: $minAmount,
                    maxAmount: $maxAmount,
                    dateRange: $dateRange
                )
                .presentationDetents([.medium, .large])
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
        VStack(spacing: 12) {
            Text("Total Expenses")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text("$\(totalAmount, specifier: "%.2f")")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
            
            Text("\(expenses.count) transaction\(expenses.count == 1 ? "" : "s")")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
    }
}

// MARK: - Expense List
struct ExpenseListView: View {
    let expenses: [Expense]
    let modelContext: ModelContext
    
    var body: some View {
        List {
            ForEach(expenses) { expense in
                NavigationLink(destination: ExpenseDetailView(expense: expense, modelContext: modelContext)) {
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
        CategoryManager.shared.icon(for: expense.category)
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
                        .foregroundColor(.secondary)
                    
                    Text("•")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                    
                    Text(expense.date.formatted(date: .abbreviated, time: .omitted))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Amount - solid color for readability
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(expense.currency)")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Text("$\(expense.amount, specifier: "%.2f")")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal, 2)
        .padding(.vertical, 2)
    }
}

// MARK: - Empty State
struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
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

