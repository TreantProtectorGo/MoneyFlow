//
//  MoneyFlowTests.swift
//  MoneyFlowTests
//
//  Created by Wing - on 2026/1/2.
//

import XCTest
import SwiftData
@testable import MoneyFlow

final class MoneyFlowTests: XCTestCase {
    
    // Test 1: Expense Initialization with Defaults
    func testExpenseInitializationdefaults() throws {
        let expense = Expense(
            amount: 100.0,
            merchant: "Test Merchant",
            category: "Food"
        )
        
        XCTAssertEqual(expense.amount, 100.0)
        XCTAssertEqual(expense.merchant, "Test Merchant")
        XCTAssertEqual(expense.category, "Food")
        XCTAssertEqual(expense.currency, "HKD")
        XCTAssertNotNil(expense.id)
        XCTAssertNil(expense.amountInBaseCurrency)
    }
    
    // Test 2: Base Currency Calculation (HKD to HKD)
    func testBaseCurrencyCalculationHKD() throws {
        let expense = Expense(
            amount: 500.0,
            currency: "HKD",
            merchant: "Local Shop",
            category: "Shopping"
        )
        
        // This should set amountInBaseCurrency = amount since it's HKD
        expense.updateBaseCurrencyAmount()
        
        XCTAssertEqual(expense.amountInBaseCurrency, 500.0)
    }
    
    // Test 3: Currency Manager Validation
    func testCurrencyManagerValidation() throws {
        let manager = CurrencyManager.shared
        
        XCTAssertTrue(manager.isValid(code: "HKD"))
        XCTAssertTrue(manager.isValid(code: "USD"))
        XCTAssertTrue(manager.isValid(code: "JPY"))
        
        XCTAssertFalse(manager.isValid(code: "INVALID_CODE"))
        XCTAssertFalse(manager.isValid(code: ""))
    }
    
    // Test 4: Exchange Rate Conversion Logic (Manual Injection)
    func testExchangeRateConversionLogic() async throws {
        let service = ExchangeRateService.shared
        
        // Manually inject rates for testing to avoid network dependency
        // Assuming 1 HKD = 0.128 USD (approx) -> stored as "USD": 0.128
        // Assuming 1 HKD = 19.2 JPY (approx) -> stored as "JPY": 19.2
        
        // Since `rates` property is @Published, we might need to access the underlying dictionary if exposed, 
        // or effectively we rely on the service being ObservableObject.
        // However, looking at the code, `rates` is public var.
        
        let testRates: [String: Double] = [
            "HKD": 1.0,
            "USD": 0.128,  // 1 HKD = 0.128 USD
            "JPY": 19.2    // 1 HKD = 19.2 JPY
        ]
        
        // Create an actor-isolated way to set this or just set it if it's main actor isolated?
        // Service is ObservableObject but properties not marked MainActor isolated explicitly in property definition?
        // Wait, the class itself isn't MainActor but `fetchRates` uses MainActor.run.
        // Let's try setting it directly.
        await MainActor.run {
            service.rates = testRates
        }
        
        // Case A: Convert USD to HKD
        // 100 USD -> HKD
        // Formula: Amount * (TargetRate / SourceRate) = 100 * (1.0 / 0.128) = 781.25
        let result1 = service.convert(100, from: "USD", to: "HKD")
        XCTAssertNotNil(result1)
        XCTAssertEqual(result1!, 781.25, accuracy: 0.01)
        
        // Case B: Convert HKD to JPY
        // 100 HKD -> JPY
        // Formula: 100 * (19.2 / 1.0) = 1920
        let result2 = service.convert(100, from: "HKD", to: "JPY")
        XCTAssertNotNil(result2)
        XCTAssertEqual(result2!, 1920.0, accuracy: 0.1)
    }

}
