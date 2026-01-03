//
//  AddExpenseView.swift
//  MoneyFlow
//
//  Created by Wing - on 2026/1/3.
//

import SwiftUI
import SwiftData

struct AddExpenseView: View {
    @Environment(\.dismiss) private var dismiss
    let modelContext: ModelContext
    
    @State private var amount: String = ""
    @State private var merchant: String = ""
    @State private var category: String = "Food"
    @State private var currency: String = "HKD"
    @State private var date: Date = Date()
    @State private var note: String = ""
    
    // Receipt scanning
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var selectedImage: UIImage?
    @State private var isProcessing = false
    @State private var processingMessage = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    // Voice input
    @State private var showingVoiceInput = false
    
    private let ocrService = OCRService()
    private let aiService = AIService()
    
    let categories = ["Food", "Transport", "Entertainment", "Shopping", "Travel", "Medical", "Other"]
    let currencies = ["HKD", "USD", "CNY", "JPY", "EUR", "GBP"]
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background gradient
                LinearGradient(
                    colors: [Color.blue.opacity(0.1), Color.purple.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Smart scanning section
                        VStack(spacing: 12) {
                            Text("📸 Smart Capture")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: 12) {
                                // Camera button
                                Button(action: {
                                    showingCamera = true
                                }) {
                                    VStack(spacing: 4) {
                                        Image(systemName: "camera.fill")
                                            .font(.title2)
                                        Text("Camera")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        LinearGradient(
                                            colors: [.blue, .cyan],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                                
                                // Photo library button
                                Button(action: {
                                    showingImagePicker = true
                                }) {
                                    VStack(spacing: 4) {
                                        Image(systemName: "photo.fill")
                                            .font(.title2)
                                        Text("Photos")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        LinearGradient(
                                            colors: [.purple, .pink],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                                
                                // Voice input button
                                Button(action: {
                                    showingVoiceInput = true
                                }) {
                                    VStack(spacing: 4) {
                                        Image(systemName: "mic.fill")
                                            .font(.title2)
                                        Text("Voice")
                                            .font(.caption)
                                            .fontWeight(.medium)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(
                                        LinearGradient(
                                            colors: [.green, .mint],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                                }
                            }
                            
                            // Processing indicator
                            if isProcessing {
                                HStack(spacing: 12) {
                                    ProgressView()
                                        .progressViewStyle(.circular)
                                    Text(processingMessage)
                                        .font(.subheadline)
                                        .foregroundColor(.secondary)
                                }
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(.blue.opacity(0.1))
                                )
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.white.opacity(0.7))
                                .shadow(color: .blue.opacity(0.1), radius: 10, x: 0, y: 5)
                        )
                        
                        // Amount input
                        VStack(spacing: 8) {
                            Text("Amount")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: 12) {
                                Picker("Currency", selection: $currency) {
                                    ForEach(currencies, id: \.self) { curr in
                                        Text(curr).tag(curr)
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(.ultraThinMaterial)
                                )
                                
                                TextField("0.00", text: $amount)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .multilineTextAlignment(.trailing)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(.ultraThinMaterial)
                                    )
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.white.opacity(0.5))
                        )
                        
                        // Merchant name
                        VStack(spacing: 8) {
                            Text("Merchant")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            TextField("e.g., Starbucks", text: $merchant)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(.ultraThinMaterial)
                                )
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.white.opacity(0.5))
                        )
                        
                        // Category selection
                        VStack(spacing: 8) {
                            Text("Category")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            LazyVGrid(columns: [
                                GridItem(.flexible()),
                                GridItem(.flexible()),
                                GridItem(.flexible())
                            ], spacing: 12) {
                                ForEach(categories, id: \.self) { cat in
                                    CategoryButton(
                                        category: cat,
                                        isSelected: category == cat
                                    ) {
                                        withAnimation(.spring(response: 0.3)) {
                                            category = cat
                                        }
                                    }
                                }
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.white.opacity(0.5))
                        )
                        
                        // Date picker
                        VStack(spacing: 8) {
                            Text("Date")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            DatePicker("", selection: $date, displayedComponents: [.date])
                                .datePickerStyle(.graphical)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(.ultraThinMaterial)
                                )
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.white.opacity(0.5))
                        )
                        
                        // Note
                        VStack(spacing: 8) {
                            Text("Note (Optional)")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            TextField("Enter note...", text: $note, axis: .vertical)
                                .lineLimit(3...6)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(.ultraThinMaterial)
                                )
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.white.opacity(0.5))
                        )
                    }
                    .padding()
                }
            }
            .navigationTitle("Add Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        saveExpense()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isFormValid)
                }
            }
        }
        .sheet(isPresented: $showingImagePicker) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .photoLibrary)
        }
        .sheet(isPresented: $showingCamera) {
            ImagePicker(selectedImage: $selectedImage, sourceType: .camera)
        }
        .sheet(isPresented: $showingVoiceInput) {
            VoiceInputView { extractedData in
                fillFormFromExtractedData(extractedData)
            }
        }
        .alert("Notice", isPresented: $showingAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(alertMessage)
        }
        .onChange(of: selectedImage) { oldValue, newValue in
            if let image = newValue {
                processReceipt(image)
            }
        }
    }
    
    private var isFormValid: Bool {
        guard let amountValue = Double(amount), amountValue > 0 else {
            return false
        }
        return !merchant.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    private func saveExpense() {
        guard let amountValue = Double(amount) else { return }
        
        let newExpense = Expense(
            amount: amountValue,
            currency: currency,
            merchant: merchant,
            category: category,
            date: date,
            note: note.isEmpty ? nil : note
        )
        
        modelContext.insert(newExpense)
        
        do {
            try modelContext.save()
            dismiss()
        } catch {
            print("Error saving expense: \(error)")
        }
    }
    
    // MARK: - Receipt Processing
    
    private func processReceipt(_ image: UIImage) {
        Task {
            await MainActor.run {
                isProcessing = true
                processingMessage = "Recognizing receipt..."
            }
            
            do {
                let recognizedText = try await ocrService.recognizeText(from: image)
                
                await MainActor.run {
                    processingMessage = "Extracting data..."
                }
                
                let extractedData = try await aiService.extractExpenseData(from: recognizedText)
                
                await MainActor.run {
                    fillFormFromExtractedData(extractedData)
                    
                    isProcessing = false
                    alertMessage = extractedData.isValid ? 
                        "✅ Receipt scanned successfully!" : 
                        "⚠️ Some data could not be extracted."
                    showingAlert = true
                }
                
            } catch {
                await MainActor.run {
                    isProcessing = false
                    alertMessage = "❌ Scan failed: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
    
    private func fillFormFromExtractedData(_ data: ExtractedExpenseData) {
        if let merchant = data.merchant {
            self.merchant = merchant
        }
        
        if let amount = data.amount {
            self.amount = String(format: "%.2f", amount)
        }
        
        if let currency = data.currency {
            self.currency = currency
        }
        
        if let date = data.date {
            self.date = date
        }
        
        if let category = data.category {
            self.category = category
        }
    }
}

// MARK: - Category Button
struct CategoryButton: View {
    let category: String
    let isSelected: Bool
    let action: () -> Void
    
    var categoryIcon: String {
        switch category {
        case "Food": return "🍜"
        case "Transport": return "🚗"
        case "Entertainment": return "🎮"
        case "Shopping": return "🛒"
        case "Travel": return "✈️"
        case "Medical": return "💊"
        default: return "💰"
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Text(categoryIcon)
                    .font(.title)
                
                Text(category)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .regular)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? 
                          LinearGradient(
                            colors: [.blue, .purple],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          ) : 
                          LinearGradient(
                            colors: [.gray.opacity(0.1), .gray.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                          )
                    )
                    .shadow(color: isSelected ? .blue.opacity(0.3) : .clear, radius: 8, x: 0, y: 4)
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AddExpenseView(modelContext: ModelContext(
        try! ModelContainer(for: Expense.self, User.self, Group.self)
    ))
}
