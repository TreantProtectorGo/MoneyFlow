//
//  ExpenseRepository.swift
//  MoneyFlow
//
//  Created by Wing - on 2026/1/16.
//

import Foundation
import SwiftData

/// Protocol defining expense data access operations
protocol ExpenseRepositoryProtocol {
    func save(_ expense: Expense) async throws
    func delete(_ expense: Expense) async throws
    func fetchAll() async throws -> [Expense]
    func fetch(for date: Date) async throws -> [Expense]
}

/// Repository for managing expense data operations
/// Follows Repository Pattern and Dependency Inversion Principle
class ExpenseRepository: ExpenseRepositoryProtocol {
    
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    /// Save an expense to persistent storage
    /// - Parameter expense: The expense to save
    func save(_ expense: Expense) async throws {
        modelContext.insert(expense)
        try modelContext.save()
    }
    
    /// Delete an expense from persistent storage
    /// - Parameter expense: The expense to delete
    func delete(_ expense: Expense) async throws {
        modelContext.delete(expense)
        try modelContext.save()
    }
    
    /// Fetch all expenses
    /// - Returns: Array of all expenses sorted by date descending
    func fetchAll() async throws -> [Expense] {
        let descriptor = FetchDescriptor<Expense>(
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try modelContext.fetch(descriptor)
    }
    
    /// Fetch expenses for a specific month
    /// - Parameter date: Date within the month to fetch
    /// - Returns: Array of expenses for that month
    func fetch(for date: Date) async throws -> [Expense] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        
        guard let startOfMonth = calendar.date(from: components),
              let endOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: startOfMonth) else {
            return []
        }
        
        let predicate = #Predicate<Expense> { expense in
            expense.date >= startOfMonth && expense.date <= endOfMonth
        }
        
        let descriptor = FetchDescriptor<Expense>(
            predicate: predicate,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        return try modelContext.fetch(descriptor)
    }
}
