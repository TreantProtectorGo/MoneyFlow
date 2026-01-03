import Foundation
import SwiftData

// MARK: - Expense Model
@Model
final class Expense {
    var id: UUID
    var amount: Double
    var currency: String
    var merchant: String
    var category: String
    var date: Date
    var note: String?
    @Attribute(.externalStorage) var receiptImageData: Data?
    
    var paidBy: User?
    var belongsToGroup: Group?
    
    init(amount: Double, currency: String = "HKD", merchant: String, category: String, date: Date = Date(), note: String? = nil, receiptImageData: Data? = nil) {
        self.id = UUID()
        self.amount = amount
        self.currency = currency
        self.merchant = merchant
        self.category = category
        self.date = date
        self.note = note
        self.receiptImageData = receiptImageData
    }
}

// MARK: - User Model
@Model
final class User {
    var id: UUID
    var name: String
    
    @Relationship(deleteRule: .cascade, inverse: \Expense.paidBy)
    var expenses: [Expense]?
    
    init(name: String) {
        self.id = UUID()
        self.name = name
    }
}

// MARK: - Group Model
@Model
final class Group {
    var id: UUID
    var title: String
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \Expense.belongsToGroup)
    var expenses: [Expense]?
    
    init(title: String) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
    }
}
