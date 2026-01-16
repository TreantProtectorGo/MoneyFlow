//
//  CategoryConfiguration.swift
//  MoneyFlow
//
//  Created by Wing - on 2026/1/16.
//

import SwiftUI

/// Protocol defining category configuration requirements
protocol CategoryConfigurable {
    var name: String { get }
    var icon: String { get }
    var color: Color { get }
}

/// Category configuration model
struct CategoryConfiguration: CategoryConfigurable {
    let name: String
    let icon: String
    let color: Color
    
    // MARK: - Predefined Categories with Material 3 Colors
    
    static let food = CategoryConfiguration(
        name: "Food",
        icon: "fork.knife",
        color: Color(red: 0.25, green: 0.71, blue: 0.29) // Material Green #43B73F
    )
    
    static let transport = CategoryConfiguration(
        name: "Transport",
        icon: "car.fill",
        color: Color(red: 0.13, green: 0.59, blue: 0.95) // Material Blue #2196F3
    )
    
    static let entertainment = CategoryConfiguration(
        name: "Entertainment",
        icon: "gamecontroller.fill",
        color: Color(red: 0.61, green: 0.15, blue: 0.69) // Material Purple #9C27B0
    )
    
    static let shopping = CategoryConfiguration(
        name: "Shopping",
        icon: "cart.fill",
        color: Color(red: 1.0, green: 0.34, blue: 0.13) // Material Deep Orange #FF5722
    )
    
    static let travel = CategoryConfiguration(
        name: "Travel",
        icon: "airplane",
        color: Color(red: 0.0, green: 0.74, blue: 0.83) // Material Cyan #00BCD4
    )
    
    static let medical = CategoryConfiguration(
        name: "Medical",
        icon: "cross.case.fill",
        color: Color(red: 0.96, green: 0.26, blue: 0.21) // Material Red #F44336
    )
    
    static let other = CategoryConfiguration(
        name: "Other",
        icon: "dollarsign.circle.fill",
        color: Color(red: 0.38, green: 0.49, blue: 0.55) // Material Blue Grey #607D8B
    )
}

/// Centralized category manager following Single Responsibility Principle
class CategoryManager {
    
    // Singleton instance
    static let shared = CategoryManager()
    
    // Private init to enforce singleton
    private init() {}
    
    // All available categories
    private let categories: [CategoryConfiguration] = [
        .food,
        .transport,
        .entertainment,
        .shopping,
        .travel,
        .medical,
        .other
    ]
    
    /// Get all category names
    var allCategoryNames: [String] {
        categories.map { $0.name }
    }
    
    /// Get configuration for a specific category name
    /// - Parameter categoryName: The name of the category
    /// - Returns: CategoryConfiguration or default 'Other' if not found
    func configuration(for categoryName: String) -> CategoryConfiguration {
        categories.first { $0.name == categoryName } ?? .other
    }
    
    /// Get icon for a specific category name
    /// - Parameter categoryName: The name of the category
    /// - Returns: SF Symbol name
    func icon(for categoryName: String) -> String {
        configuration(for: categoryName).icon
    }
    
    /// Get color for a specific category name
    /// - Parameter categoryName: The name of the category
    /// - Returns: SwiftUI Color
    func color(for categoryName: String) -> Color {
        configuration(for: categoryName).color
    }
    
    /// Check if a category name is valid
    /// - Parameter categoryName: The name to validate
    /// - Returns: Boolean indicating validity
    func isValid(categoryName: String) -> Bool {
        categories.contains { $0.name == categoryName }
    }
}
