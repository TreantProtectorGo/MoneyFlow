//
//  CurrencyConfiguration.swift
//  MoneyFlow
//
//  Created by Wing - on 2026/1/16.
//

import Foundation

/// Protocol defining currency configuration requirements
protocol CurrencyConfigurable {
    var code: String { get }
    var symbol: String { get }
    var name: String { get }
}

/// Currency configuration model
struct CurrencyConfiguration: CurrencyConfigurable {
    let code: String
    let symbol: String
    let name: String
    
    // MARK: - Predefined Currencies
    
    static let hkd = CurrencyConfiguration(
        code: "HKD",
        symbol: "HK$",
        name: "Hong Kong Dollar"
    )
    
    static let usd = CurrencyConfiguration(
        code: "USD",
        symbol: "$",
        name: "US Dollar"
    )
    
    static let cny = CurrencyConfiguration(
        code: "CNY",
        symbol: "¥",
        name: "Chinese Yuan"
    )
    
    static let jpy = CurrencyConfiguration(
        code: "JPY",
        symbol: "¥",
        name: "Japanese Yen"
    )
    
    static let eur = CurrencyConfiguration(
        code: "EUR",
        symbol: "€",
        name: "Euro"
    )
    
    static let gbp = CurrencyConfiguration(
        code: "GBP",
        symbol: "£",
        name: "British Pound"
    )
}

/// Centralized currency manager following Single Responsibility Principle
class CurrencyManager {
    
    // Singleton instance
    static let shared = CurrencyManager()
    
    // Private init to enforce singleton
    private init() {}
    
    // All available currencies
    private let currencies: [CurrencyConfiguration] = [
        .hkd,
        .usd,
        .cny,
        .jpy,
        .eur,
        .gbp
    ]
    
    /// Get all currency codes
    var allCurrencyCodes: [String] {
        currencies.map { $0.code }
    }
    
    /// Get configuration for a specific currency code
    /// - Parameter code: The currency code (e.g., "USD")
    /// - Returns: CurrencyConfiguration or HKD if not found
    func configuration(for code: String) -> CurrencyConfiguration {
        currencies.first { $0.code == code } ?? .hkd
    }
    
    /// Get symbol for a specific currency code
    /// - Parameter code: The currency code
    /// - Returns: Currency symbol
    func symbol(for code: String) -> String {
        configuration(for: code).symbol
    }
    
    /// Get name for a specific currency code
    /// - Parameter code: The currency code
    /// - Returns: Currency name
    func name(for code: String) -> String {
        configuration(for: code).name
    }
    
    /// Check if a currency code is valid
    /// - Parameter code: The code to validate
    /// - Returns: Boolean indicating validity
    func isValid(code: String) -> Bool {
        currencies.contains { $0.code == code }
    }
}
