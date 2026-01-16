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
        
        let systemPrompt = """
        You are a voice expense tracking assistant. Users describe expenses in natural language. Extract:
        1. merchant: Merchant name
        2. amount: Amount (number only)
        3. currency: Currency code (default HKD unless explicitly mentioned)
        4. date: Date (convert "today", "yesterday" to ISO 8601; null if not mentioned)
        5. category: Expense category (choose from: Food, Transport, Entertainment, Shopping, Travel, Medical, Other)
        
        Example input: "Spent eighty-five dollars at Starbucks"
        Example output: {"merchant": "Starbucks", "amount": 85, "currency": "HKD", "date": null, "category": "Food"}
        
        Respond in JSON format. Set to null if information is uncertain.
        """
        
        let endpoint = "https://openrouter.ai/api/v1/chat/completions"
        let model = "openai/gpt-oss-20b:free"
        
        let requestBody: [String: Any] = [
            "model": model,
            "messages": [
                ["role": "system", "content": systemPrompt],
                ["role": "user", "content": voiceText]
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
        request.setValue("MoneyFlow/1.0", forHTTPHeaderField: "HTTP-Referer")
        request.setValue("MoneyFlow Expense Tracker", forHTTPHeaderField: "X-Title")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        request.timeoutInterval = 30
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse,
              (200...299).contains(httpResponse.statusCode) else {
            throw AIError.networkError("HTTP status code error")
        }
        
        // Parse response
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
