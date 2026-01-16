//
//  ExchangeRateService.swift
//  MoneyFlow
//
//  Created by Wing - on 2026/1/16.
//

import Foundation
import Combine

/// Model for the Exchange Rate API response
struct ExchangeRateResponse: Codable {
    let timestamp: TimeInterval
    let base: String
    let rates: [String: Double]
}

/// Service to fetch and manage exchange rates
class ExchangeRateService: ObservableObject {
    
    static let shared = ExchangeRateService()
    
    @Published var rates: [String: Double] = [:]
    @Published var lastUpdated: Date?
    @Published var error: String?
    
    private let endpoint = "https://api.exchangerate.fun/latest"
    private let targetBase = "HKD"
    
    private init() {}
    
    /// Fetch latest exchange rates and rebase to HKD
    func fetchRates() async {
        guard let url = URL(string: endpoint) else {
            setErrorMessage("Invalid URL")
            return
        }
        
        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            let response = try JSONDecoder().decode(ExchangeRateResponse.self, from: data)
            
            // The API returns rates with USD base (e.g., 1 USD = 7.8 HKD, 1 USD = 150 JPY)
            // We want HKD base (e.g., 1 HKD = ? JPY)
            // Formula: Rate(JPY/HKD) = Rate(JPY/USD) / Rate(HKD/USD)
            
            guard let hkdRate = response.rates["HKD"] else {
                setErrorMessage("HKD rate not found in response")
                return
            }
            
            var newRates: [String: Double] = [:]
            
            // Add HKD itself
            newRates["HKD"] = 1.0
            
            // Rebase all other currencies
            for (currency, usdRate) in response.rates {
                if currency != "HKD" {
                    let rateAgainstHKD = usdRate / hkdRate
                    newRates[currency] = rateAgainstHKD
                }
            }
            
            await MainActor.run {
                self.rates = newRates
                self.lastUpdated = Date(timeIntervalSince1970: response.timestamp)
                self.error = nil
                print("✅ Exchange rates updated (Base: HKD). Total currencies: \(newRates.count)")
            }
            
        } catch {
            setErrorMessage("Failed to fetch rates: \(error.localizedDescription)")
            print("❌ Exchange rate fetch error: \(error)")
        }
    }
    
    /// Convert amount from one currency to another using cached rates
    /// - Parameters:
    ///   - amount: Amount to convert
    ///   - fromCurrency: Source currency code (e.g. "USD")
    ///   - toCurrency: Target currency code (e.g. "HKD")
    /// - Returns: Converted amount, or nil if rates unavailable
    func convert(_ amount: Double, from fromCurrency: String, to toCurrency: String) -> Double? {
        // If same currency, return amount
        if fromCurrency == toCurrency {
            return amount
        }
        
        // Ensure we have rates
        guard !rates.isEmpty else {
            return nil
        }
        
        // Get rates relative to HKD (our base)
        guard let fromRate = rates[fromCurrency],
              let toRate = rates[toCurrency] else {
            return nil
        }
        
        // Convert: Amount * (TargetRate / SourceRate)
        // Example: 100 USD -> JPY (Base HKD)
        // HKD/USD = 0.128 (1 HKD = 0.128 USD) -> Stored as USD/HKD? Wait.
        // My stored rates are: 1 HKD = X Currency.
        // So Rate(USD) stored is 0.128 (approx 1/7.8).
        // Rate(JPY) stored is 19.2 (approx 150/7.8).
        
        // To convert 100 USD to JPY:
        // Convert USD to Base (HKD): 100 / Rate(USD) = 100 / 0.128 = 780 HKD
        // Convert Base (HKD) to JPY: 780 * Rate(JPY) = 780 * 19.2 = 15000 JPY
        
        // Formula: amount * (toRate / fromRate)
        return amount * (toRate / fromRate)
    }
    
    private func setErrorMessage(_ message: String) {
        Task { @MainActor in
            self.error = message
        }
    }
}
