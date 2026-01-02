import Foundation
import SwiftData

// 1. Consumption record model
@Model
final class Expense {
    var id: UUID
    var amount: Double
    var currency: String // e.g., "HKD", "JPY"
    var merchant: String
    var category: String // e.g., "Food", "Transport"
    var date: Date
    var note: String?
    @Attribute(.externalStorage) var receiptImageData: Data? // 儲存收據照片
    
    // Related: A single transaction belongs to both a user and a group.
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

// 2. User Model
@Model
final class User {
    var id: UUID
    var name: String
    
    // Related: A user has multiple purchases.
    @Relationship(deleteRule: .cascade, inverse: \Expense.paidBy)
    var expenses: [Expense]?
    
    init(name: String) {
        self.id = UUID()
        self.name = name
    }
}

// 3. Group model (for travel/AA billing)
@Model
final class Group {
    var id: UUID
    var title: String // e.g., "Tokyo Trip"
    var createdAt: Date
    
    // Related: Multiple purchases within a single group
    @Relationship(deleteRule: .cascade, inverse: \Expense.belongsToGroup)
    var expenses: [Expense]?
    
    init(title: String) {
        self.id = UUID()
        self.title = title
        self.createdAt = Date()
    }
}
