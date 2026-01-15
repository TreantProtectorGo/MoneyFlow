//
//  MonthFilterHelper.swift
//  MoneyFlow
//
//  Created by Wing - on 2026/1/15.
//

import Foundation

extension Calendar {
    static func filterExpenses(_ expenses: [Expense], for date: Date) -> [Expense] {
        let calendar = Calendar.current
        return expenses.filter { expense in
            calendar.isDate(expense.date, equalTo: date, toGranularity: .month)
        }
    }
    
    static func previousMonth(from date: Date) -> Date? {
        return Calendar.current.date(byAdding: .month, value: -1, to: date)
    }
    
    static func nextMonth(from date: Date) -> Date? {
        let calendar = Calendar.current
        let now = Date()
        if let newDate = calendar.date(byAdding: .month, value: 1, to: date),
           calendar.compare(newDate, to: now, toGranularity: .month) != .orderedDescending {
            return newDate
        }
        return nil
    }
}
