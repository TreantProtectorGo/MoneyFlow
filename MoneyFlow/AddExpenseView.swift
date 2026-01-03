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
                // iOS 26 gradient background
                LinearGradient(
                    colors: [
                        Color(red: 0.95, green: 0.97, blue: 1.0),
                        Color(red: 0.98, green: 0.95, blue: 1.0)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Smart scanning section
                        VStack(spacing: 16) {
                            Label("Smart Capture", systemImage: "wand.and.stars")
                                .font(.headline.weight(.semibold))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: 12) {
                                // Camera button
                                Button(action: {
                                    showingCamera = true
                                }) {
                                    VStack(spacing: 8) {
                                        Image(systemName: "camera.fill")
                                            .font(.title2)
                                            .symbolRenderingMode(.hierarchical)
                                        Text("Camera")
                                            .font(.caption.weight(.medium))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 80)
                                    .background(Color.blue.gradient)
                                    .foregroundStyle(.white)
                                    .cornerRadius(16, antialiased: true)
                                }
                                
                                // Photo library button
                                Button(action: {
                                    showingImagePicker = true
                                }) {
                                    VStack(spacing: 8) {
                                        Image(systemName: "photo.fill")
                                            .font(.title2)
                                            .symbolRenderingMode(.hierarchical)
                                        Text("Photos")
                                            .font(.caption.weight(.medium))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 80)
                                    .background(Color.purple.gradient)
                                    .foregroundStyle(.white)
                                    .cornerRadius(16, antialiased: true)
                                }
                                
                                // Voice input button
                                Button(action: {
                                    showingVoiceInput = true
                                }) {
                                    VStack(spacing: 8) {
                                        Image(systemName: "mic.fill")
                                            .font(.title2)
                                            .symbolRenderingMode(.hierarchical)
                                        Text("Voice")
                                            .font(.caption.weight(.medium))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 80)
                                    .background(Color.green.gradient)
                                    .foregroundStyle(.white)
                                    .cornerRadius(16, antialiased: true)
                                }
                            }
                            
                            // Processing indicator
                            if isProcessing {
                                HStack(spacing: 12) {
                                    ProgressView()
                                        .tint(.blue)
                                    Text(processingMessage)
                                        .font(.subheadline.weight(.medium))
                                        .foregroundStyle(.secondary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(.blue.opacity(0.1))
                                }
                            }
                        }
                        .padding(20)
                        .background {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(.background)
                                .shadow(color: .black.opacity(0.06), radius: 20, x: 0, y: 8)
                                .shadow(color: .black.opacity(0.04), radius: 1, x: 0, y: 1)
                        }
                        
                        // Amount input
                        VStack(spacing: 12) {
                            Label("Amount", systemImage: "dollarsign.circle")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: 12) {
                                Picker("Currency", selection: $currency) {
                                    ForEach(currencies, id: \.self) { curr in
                                        Text(curr).tag(curr)
                                    }
                                }
                                .pickerStyle(.menu)
                                .padding(12)
                                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                                
                                TextField("0.00", text: $amount)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .multilineTextAlignment(.trailing)
                                    .padding(16)
                                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                            }
                        }
                        .padding(20)
                        .background {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(.background)
                                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
                        }
                        
                        // Merchant name
                        VStack(spacing: 12) {
                            Label("Merchant", systemImage: "building.2")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            TextField("e.g., Starbucks", text: $merchant)
                                .padding(16)
                                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .padding(20)
                        .background {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(.background)
                                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
                        }
                        
                        // Category selection
                        VStack(spacing: 12) {
                            Label("Category", systemImage: "tag")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
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
                                        withAnimation(.smooth) {
                                            category = cat
                                        }
                                    }
                                }
                            }
                        }
                        .padding(20)
                        .background {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(.background)
                                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
                        }
                        
                        // Date picker
                        VStack(spacing: 12) {
                            Label("Date", systemImage: "calendar")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            DatePicker("", selection: $date, displayedComponents: [.date])
                                .datePickerStyle(.graphical)
                                .tint(.blue)
                        }
                        .padding(20)
                        .background {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(.background)
                                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
                        }
                        
                        // Note
                        VStack(spacing: 12) {
                            Label("Note", systemImage: "note.text")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            TextField("Add a note...", text: $note, axis: .vertical)
                                .lineLimit(3...6)
                                .padding(16)
                                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                        }
                        .padding(20)
                        .background {
                            RoundedRectangle(cornerRadius: 24, style: .continuous)
                                .fill(.background)
                                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 4)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
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
