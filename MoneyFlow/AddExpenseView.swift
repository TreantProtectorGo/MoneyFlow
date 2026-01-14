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
                    VStack(spacing: 16) {
                        // Amount input - PRIORITY
                        VStack(spacing: 6) {
                            Text("Amount")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
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
                                        .fill(Color(.systemBackground))
                                )
                                .shadow(color: .black.opacity(0.05), radius: 2)
                                
                                TextField("0.00", text: $amount)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 32, weight: .bold, design: .rounded))
                                    .multilineTextAlignment(.trailing)
                                    .foregroundColor(.primary)
                                    .padding()
                                    .background(
                                        RoundedRectangle(cornerRadius: 15)
                                            .fill(Color(.systemBackground))
                                    )
                                    .shadow(color: .black.opacity(0.05), radius: 2)
                            }
                        }
                        .padding(.horizontal)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(.white.opacity(0.7))
                        )
                        
                        
                        // Merchant name - inline placeholder
                        TextField("Merchant (e.g., Starbucks)", text: $merchant)
                            .foregroundColor(.primary)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(Color(.systemBackground))
                            )
                            .shadow(color: .black.opacity(0.05), radius: 2)
                            .padding(.horizontal)
                        
                        // Category selection - Consistent SF Symbols
                        VStack(spacing: 8) {
                            Text("Category")
                                .font(.headline)
                                .foregroundColor(.primary)
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
                                .fill(.white.opacity(0.7))
                        )
                        
                        // Date picker - simple row layout
                        HStack {
                            Text("Date")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Spacer()
                            
                            DatePicker("", selection: $date, displayedComponents: [.date])
                                .labelsHidden()
                            
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color(.systemBackground))
                        )
                        .shadow(color: .black.opacity(0.05), radius: 2)
                        .padding(.horizontal)
                        
                        // Note
                        VStack(spacing: 8) {
                            Text("Note (Optional)")
                                .font(.headline)
                                .foregroundColor(.primary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            TextField("Enter note...", text: $note, axis: .vertical)
                                .foregroundColor(.primary)
                                .lineLimit(3...6)
                                .padding()
                                .background(
                                    RoundedRectangle(cornerRadius: 15)
                                        .fill(Color(.systemBackground))
                                        .shadow(color: .black.opacity(0.05), radius: 2)
                                )
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 20)
                                .fill(.white.opacity(0.7))
                        )
                        
                        // Smart capture section - MINIMIZED and moved to bottom
                        VStack(spacing: 12) {
                            Text("📸 Quick Capture")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: 12) {
                                // Compact camera button
                                Button(action: { showingCamera = true }) {
                                    Label("Camera", systemImage: "camera")
                                        .font(.footnote)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(.blue.opacity(0.15))
                                        .foregroundColor(.blue)
                                        .cornerRadius(10)
                                }
                                
                                // Compact photos button
                                Button(action: { showingImagePicker = true }) {
                                    Label("Photos", systemImage: "photo")
                                        .font(.footnote)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(.purple.opacity(0.15))
                                        .foregroundColor(.purple)
                                        .cornerRadius(10)
                                }
                                
                                // Compact voice button
                                Button(action: { showingVoiceInput = true }) {
                                    Label("Voice", systemImage: "mic")
                                        .font(.footnote)
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                        .background(.green.opacity(0.15))
                                        .foregroundColor(.green)
                                        .cornerRadius(10)
                                }
                            }
                            
                            // Processing indicator
                            if isProcessing {
                                HStack(spacing: 10) {
                                    ProgressView()
                                        .scaleEffect(0.9)
                                    Text(processingMessage)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                .padding(.vertical, 8)
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 8)
                                        .fill(.blue.opacity(0.1))
                                )
                            }
                        }
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(.white.opacity(0.5))
                        )
                    }
                    .padding()
                    .padding(.bottom, 40) // Extra padding for home indicator
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
                    .foregroundColor(isFormValid ? .blue : .gray.opacity(0.5))
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
                processingMessage = "Recognizing..."
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

// MARK: - Category Button (SF Symbols consistent style)
struct CategoryButton: View {
    let category: String
    let isSelected: Bool
    let action: () -> Void
    
    var categoryIcon: String {
        switch category {
        case "Food": return "fork.knife"
        case "Transport": return "car.fill"
        case "Entertainment": return "gamecontroller.fill"
        case "Shopping": return "cart.fill"
        case "Travel": return "airplane"
        case "Medical": return "cross.case.fill"
        default: return "dollarsign.circle.fill"
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: categoryIcon)
                    .font(.title3)
                    .foregroundColor(isSelected ? .white : .gray)
                
                Text(category)
                    .font(.caption2)
                    .fontWeight(isSelected ? .semibold : .regular)
                    .foregroundColor(isSelected ? .white : .secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? .blue : Color(.systemBackground))
                    .shadow(color: isSelected ? .blue.opacity(0.2) : .clear, radius: 4, x: 0, y: 2)
            )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    AddExpenseView(modelContext: ModelContext(
        try! ModelContainer(for: Expense.self, User.self, Group.self)
    ))
}
