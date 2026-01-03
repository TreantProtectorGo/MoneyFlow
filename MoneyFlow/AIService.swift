//
//  AIService.swift
//  MoneyFlow
//
//  Created by Wing - on 2026/1/3.
//

import Foundation

struct ExtractedExpenseData {
    let merchant: String?
    let amount: Double?
    let currency: String?
    let date: Date?
    let category: String?
    
    var isValid: Bool {
        merchant != nil || amount != nil
    }
}

class AIService {
    
    private let apiKey: String?
    private let endpoint = "https://api.openai.com/v1/chat/completions"
    
    init(apiKey: String? = nil) {
        // Use provided API key, otherwise fallback to env variable
        self.apiKey = apiKey ?? ProcessInfo.processInfo.environment["OPENAI_API_KEY"]
    }
    
    enum AIError: LocalizedError {
        case noAPIKey
        case invalidResponse
        case networkError(String)
        case parsingError
        
        var errorDescription: String? {
            switch self {
            case .noAPIKey:
                return "OpenAI API key not configured"
            case .invalidResponse:
                return "Invalid API response format"
            case .networkError(let reason):
                return "Network error: \(reason)"
            case .parsingError:
                return "Failed to parse data"
            }
        }
    }
    
    /// Extract structured data from OCR text
    func extractExpenseData(from ocrText: [String]) async throws -> ExtractedExpenseData {
        // Fallback to local rules if no API key available
        guard let apiKey = apiKey, !apiKey.isEmpty else {
            return extractWithLocalRules(from: ocrText)
        }
        
        let combinedText = ocrText.joined(separator: "\n")
        
        let systemPrompt = """
        You are an assistant specialized in extracting information from receipts. Please extract:
        1. merchant: Merchant name
        2. amount: Amount (number only)
        3. currency: Currency code (HKD, USD, CNY, JPY, EUR, GBP)
        4. date: Date (ISO 8601 format)
        5. category: Expense category (choose from: Food, Transport, Entertainment, Shopping, Travel, Medical, Other)
        
        Respond in JSON format. Set to null if information is uncertain.
        """
        
        let requestBody: [String: Any] = [
            "model": "gpt-4o-mini",
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": combinedText]
            ],
            "response_format": ["type": "json_object"],
            "temperature": 0.3
        ]
        
        guard let url = URL(string: endpoint) else {
            throw AIError.networkError("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        request.timeoutInterval = 30
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AIError.networkError("HTTP status code error")
        }
        
        return try parseAIResponse(data)
    }
    
    /// Parse AI API response
    private func parseAIResponse(_ data: Data) throws -> ExtractedExpenseData {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              let content = message["content"] as? String,
              let contentData = content.data(using: .utf8),
              let extractedData = try JSONSerialization.jsonObject(with: contentData) as? [String: Any] else {
            throw AIError.invalidResponse
        }
        
        let merchant = extractedData["merchant"] as? String
        let amount = extractedData["amount"] as? Double
        let currency = extractedData["currency"] as? String
        let category = extractedData["category"] as? String
        
        var date: Date?
        if let dateString = extractedData["date"] as? String {
            let formatter = ISO8601DateFormatter()
            date = formatter.date(from: dateString)
        }
        
        return ExtractedExpenseData(
            merchant: merchant,
            amount: amount,
            currency: currency,
            date: date,
            category: category
        )
    }
    
    /// Extract using local rules (no API required)
    private func extractWithLocalRules(from ocrText: [String]) -> ExtractedExpenseData {
        var merchant: String?
        var amount: Double?
        var currency: String = "HKD"
        var detectedDate: Date?
        
        let combinedText = ocrText.joined(separator: " ")
        
        // Extract amount - supports multiple formats
        let amountPatterns = [
            #"\$\s*([0-9,]+\.?[0-9]*)"#,  // $123.45 or $ 123.45
            #"([0-9,]+\.[0-9]{2})\s*HKD"#, // 123.45 HKD
            #"Total[:\s]+\$?\s*([0-9,]+\.?[0-9]*)"#, // Total: $123.45
            #"總額[：:\s]+\$?\s*([0-9,]+\.?[0-9]*)"#  // Chinese total
        ]
        
        for pattern in amountPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: combinedText, range: NSRange(combinedText.startIndex..., in: combinedText)),
               let range = Range(match.range(at: 1), in: combinedText) {
                let amountString = String(combinedText[range]).replacingOccurrences(of: ",", with: "")
                amount = Double(amountString)
                break
            }
        }
        
        // Extract currency
        let currencyKeywords = ["HKD", "USD", "CNY", "JPY", "EUR", "GBP"]
        for keyword in currencyKeywords {
            if combinedText.contains(keyword) {
                currency = keyword
                break
            }
        }
        
        // Extract merchant name (usually in first line)
        if let firstLine = ocrText.first, !firstLine.isEmpty {
            merchant = firstLine
        }
        
        // Extract date
        let datePattern = #"(\d{4})[/-](\d{1,2})[/-](\d{1,2})"#
        if let regex = try? NSRegularExpression(pattern: datePattern),
           let match = regex.firstMatch(in: combinedText, range: NSRange(combinedText.startIndex..., in: combinedText)),
           let range = Range(match.range, in: combinedText) {
            let dateString = String(combinedText[range])
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            detectedDate = formatter.date(from: dateString)
        }
        
        return ExtractedExpenseData(
            merchant: merchant,
            amount: amount,
            currency: currency,
            date: detectedDate,
            category: nil
        )
    }
}
