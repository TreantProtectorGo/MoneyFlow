//
//  AIService.swift
//  MoneyFlow
//
//  Created by Wing - on 2026/1/3.
//
//  AI Service using OpenRouter API (free gpt-oss-20b model)
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
    private let endpoint = "https://openrouter.ai/api/v1/chat/completions"
    private let model = "qwen/qwen-2.5-vl-7b-instruct:free"
    
    init(apiKey: String? = nil) {
        // Use provided API key, otherwise fallback to env variable
        self.apiKey = apiKey ?? ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"]
    }
    
    enum AIError: LocalizedError {
        case noAPIKey
        case invalidResponse
        case networkError(String)
        case parsingError
        
        var errorDescription: String? {
            switch self {
            case .noAPIKey:
                return "OpenRouter API key not configured"
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
        
        let prompt = """
        You are an assistant specialized in extracting information from receipts. Please extract:
        1. merchant: Merchant name
        2. amount: The TOTAL amount of the transaction. Look for "Total", "Grand Total", "Sum", "總額", "總計", "應付", "Amount". It is usually the largest amount at the bottom. Do NOT extract individual item prices.
        3. currency: Currency code (HKD, USD, CNY, JPY, EUR, GBP)
        4. date: Date (ISO 8601 format)
        5. category: Expense category (choose from: Food, Transport, Entertainment, Shopping, Travel, Medical, Other)
        
        Respond in JSON format. Set to null if information is uncertain.
        
        Receipt text:
        \(combinedText)
        """
        
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "user", "content": prompt]
            ],
            "response_format": [
                "type": "json_schema",
                "json_schema": [
                    "name": "expense_data",
                    "strict": true,
                    "schema": [
                        "type": "object",
                        "properties": [
                            "merchant": ["type": ["string", "null"], "description": "Merchant name"],
                            "amount": ["type": ["number", "null"], "description": "Amount (number only)"],
                            "currency": ["type": ["string", "null"], "description": "Currency code (e.g. HKD, USD)"],
                            "date": ["type": ["string", "null"], "description": "Date in ISO 8601 format"],
                            "category": ["type": ["string", "null"], "description": "Expense category"]
                        ],
                        "required": ["merchant", "amount", "currency", "date", "category"],
                        "additionalProperties": false
                    ]
                ]
            ],
            "temperature": 0.3
        ]
        
        guard let url = URL(string: endpoint) else {
            throw AIError.networkError("Invalid URL")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("MoneyFlow/1.0", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("MoneyFlow Expense Tracker", forHTTPHeaderField: "X-Title")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        request.timeoutInterval = 30
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw AIError.networkError("Invalid response")
        }
        
        guard (200...299).contains(httpResponse.statusCode) else {
            // Try to parse error message from response
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("API Error (\(httpResponse.statusCode)): \(errorBody)")
            throw AIError.networkError("HTTP \(httpResponse.statusCode): \(errorBody.prefix(100))")
        }
        
        return try parseAIResponse(data)
    }
    
    /// Parse AI API response
    private func parseAIResponse(_ data: Data) throws -> ExtractedExpenseData {
        // Debug: Print raw response
        if let responseString = String(data: data, encoding: .utf8) {
            print("🤖 AI Raw Response: \(responseString)")
        }
        
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let firstChoice = choices.first,
              let message = firstChoice["message"] as? [String: Any],
              var content = message["content"] as? String else {
            throw AIError.invalidResponse
        }
        
        // Clean markdown code blocks if present (e.g. ```json ... ```)
        if content.contains("```") {
            content = content.replacingOccurrences(of: "```json", with: "")
            content = content.replacingOccurrences(of: "```", with: "")
        }
        content = content.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard let contentData = content.data(using: .utf8),
              let extractedData = try JSONSerialization.jsonObject(with: contentData) as? [String: Any] else {
            print("❌ Failed to parse content JSON: \(content)")
            throw AIError.invalidResponse
        }
        
        let merchant = extractedData["merchant"] as? String
        
        // Handle amount as Double or String
        var amount: Double?
        if let amountDouble = extractedData["amount"] as? Double {
            amount = amountDouble
        } else if let amountString = extractedData["amount"] as? String {
            // Remove any currency symbols or commas if present, though schema says number only
            let cleanString = amountString.replacingOccurrences(of: ",", with: "")
                .trimmingCharacters(in: CharacterSet(charactersIn: "$£€¥HKD "))
            amount = Double(cleanString)
        }
        
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
        var category: String?
        
        let combinedText = ocrText.joined(separator: " ")
        let lowerText = combinedText.lowercased()
        
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
        
        // Detect category from keywords
        let categoryKeywords: [(keywords: [String], category: String)] = [
            // Food - 飲食 (English and Chinese)
            (["restaurant", "cafe", "coffee", "food", "lunch", "dinner", "breakfast", "meal", "pizza", "burger", "sushi", "noodle", "tea", "drink", "bar", "bakery", "starbucks", "mcdonald", "kfc", "subway", "飲食", "餐廳", "咖啡", "茶", "飯", "麵", "早餐", "午餐", "晚餐", "外賣", "堂食", "餐", "食", "吃", "喝", "小食", "甜品", "雪糕", "蛋糕", "麵包", "奶茶", "珍珠奶茶", "boba"], "Food"),
            // Transport
            (["taxi", "uber", "grab", "bus", "train", "metro", "mtr", "subway", "parking", "fuel", "petrol", "gas", "交通", "的士", "巴士", "地鐵", "港鐵", "停車", "油站", "加油"], "Transport"),
            // Entertainment
            (["movie", "cinema", "game", "concert", "show", "ticket", "娛樂", "電影", "遊戲", "演唱會", "門票"], "Entertainment"),
            // Shopping
            (["shop", "store", "mall", "market", "supermarket", "grocery", "purchase", "購物", "商店", "商場", "超市", "百貨", "街市"], "Shopping"),
            // Travel
            (["hotel", "flight", "airline", "airport", "booking", "旅遊", "酒店", "機票", "航空", "機場"], "Travel"),
            // Medical
            (["hospital", "clinic", "pharmacy", "doctor", "medicine", "醫療", "醫院", "診所", "藥房", "醫生", "藥"], "Medical")
        ]
        
        for (keywords, cat) in categoryKeywords {
            for keyword in keywords {
                if lowerText.contains(keyword) {
                    category = cat
                    break
                }
            }
            if category != nil { break }
        }
        
        return ExtractedExpenseData(
            merchant: merchant,
            amount: amount,
            currency: currency,
            date: detectedDate,
            category: category
        )
    }
}
