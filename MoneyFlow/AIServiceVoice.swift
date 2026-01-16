//
//  AIServiceVoice.swift
//  MoneyFlow
//
//  Created by Wing - on 2026/1/3.
//
//  Voice Intent Parsing Extension using OpenRouter API
//

import Foundation

extension AIService {
    
    // MARK: - Voice Intent Parsing
    
    /// Extract expense intent from voice text
    func extractExpenseFromVoice(_ voiceText: String) async throws -> ExtractedExpenseData {
        // Fallback to local rules if no API key available
        guard let apiKey = ProcessInfo.processInfo.environment["OPENROUTER_API_KEY"], !apiKey.isEmpty else {
            return extractVoiceWithLocalRules(from: voiceText)
        }
        
        let prompt = """
        You are a voice expense tracking assistant. Users describe expenses in natural language. Extract:
        1. merchant: Merchant name
        2. amount: Amount (number only)
        3. currency: Currency code (default HKD unless explicitly mentioned)
        4. date: Date (convert "today", "yesterday" to ISO 8601; null if not mentioned)
        5. category: Expense category (choose from: Food, Transport, Entertainment, Shopping, Travel, Medical, Other)
        
        Respond in JSON format only. Set to null if information is uncertain.
        
        User said: \(voiceText)
        """
        
        let endpoint = "https://openrouter.ai/api/v1/chat/completions"
        let model = "qwen/qwen-2.5-vl-7b-instruct:free"
        
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
                            "currency": ["type": ["string", "null"], "description": "Currency code (default HKD)"],
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
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            print("API Error (\(httpResponse.statusCode)): \(errorBody)")
            throw AIError.networkError("HTTP \(httpResponse.statusCode)")
        }
        
        // Parse response
        // Parse response
        // Debug: Print raw response
        if let responseString = String(data: data, encoding: .utf8) {
            print("🤖 Voice AI Raw Response: \(responseString)")
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
    
    /// Parse voice using local rules (no API required)
    private func extractVoiceWithLocalRules(from voiceText: String) -> ExtractedExpenseData {
        var merchant: String?
        var amount: Double?
        var currency: String = "HKD"
        var category: String?
        
        let text = voiceText.lowercased()
        
        // Extract amount - supports Chinese numbers and digits
        let amountPatterns = [
            #"花了?\s*([0-9]+\.?[0-9]*)\s*[塊元蚊]"#,
            #"([0-9]+\.?[0-9]*)\s*[塊元蚊]"#,
            #"([0-9]+\.?[0-9]*)\s*dollar"#,
            #"([0-9]+\.?[0-9]*)\s*[dollarhkd]"#
        ]
        
        for pattern in amountPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern, options: .caseInsensitive),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                amount = Double(String(text[range]))
                break
            }
        }
        
        // Extract merchant (patterns: "at...", "went to...")
        let merchantPatterns = [
            #"在(.+?)[花買用]"#,
            #"去(.+?)[花買]"#,
            #"(.+?)[花買]了"#
        ]
        
        for pattern in merchantPatterns {
            if let regex = try? NSRegularExpression(pattern: pattern),
               let match = regex.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)),
               let range = Range(match.range(at: 1), in: text) {
                merchant = String(text[range]).trimmingCharacters(in: .whitespaces)
                break
            }
        }
        
        // Category keyword detection (keeping Chinese keywords for voice input)
        let categoryKeywords: [String: String] = [
            "吃": "Food", "食": "Food", "飯": "Food", "餐": "Food", "喝": "Food",
            "車": "Transport", "計程車": "Transport", "uber": "Transport", "巴士": "Transport", "地鐵": "Transport",
            "玩": "Entertainment", "電影": "Entertainment", "遊戲": "Entertainment",
            "買": "Shopping", "購": "Shopping", "shopping": "Shopping",
            "旅": "Travel", "飛": "Travel", "酒店": "Travel", "住": "Travel",
            "藥": "Medical", "醫": "Medical", "診所": "Medical", "看病": "Medical"
        ]
        
        for (keyword, cat) in categoryKeywords {
            if text.contains(keyword) {
                category = cat
                break
            }
        }
        
        return ExtractedExpenseData(
            merchant: merchant,
            amount: amount,
            currency: currency,
            date: nil,
            category: category
        )
    }
}
