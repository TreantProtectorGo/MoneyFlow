//
//  CameraView.swift
//  MoneyFlow
//
//  Created by Wing - on 2026/1/14.
//

import SwiftUI
import SwiftData

struct CameraView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @State private var showingImagePicker = false
    @State private var showingCamera = false
    @State private var capturedImage: UIImage?
    @State private var isProcessing = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    private let ocrService = OCRService()
    private let aiService = AIService()
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    if let image = capturedImage {
                        // Show captured image
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFit()
                            .frame(maxHeight: 300)
                            .cornerRadius(12)
                            .padding(.horizontal)
                        
                        if isProcessing {
                            HStack(spacing: 12) {
                                ProgressView()
                                Text("Processing receipt...")
                                    .font(.subheadline)
                            }
                            .padding()
                        }
                    } else {
                        // Show camera icon
                        Image(systemName: "camera.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.blue.opacity(0.5))
                        
                        Text("Scan Receipt")
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                    
                    if capturedImage == nil {
                        VStack(spacing: 16) {
                            Button(action: {
                                showingCamera = true
                            }) {
                                Label("Take Photo", systemImage: "camera")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.blue)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                            
                            Button(action: {
                                showingImagePicker = true
                            }) {
                                Label("Choose from Library", systemImage: "photo")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(.systemGray5))
                                    .foregroundColor(.primary)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 40)
                    } else if !isProcessing {
                        VStack(spacing: 16) {
                            Button(action: processImage) {
                                Label("Process Receipt", systemImage: "doc.text.viewfinder")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.green)
                                    .foregroundColor(.white)
                                    .cornerRadius(12)
                            }
                            
                            Button(action: {
                                capturedImage = nil
                            }) {
                                Label("Retake", systemImage: "arrow.counterclockwise")
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color(.systemGray5))
                                    .foregroundColor(.primary)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal, 40)
                    }
                    
                    Spacer()
                }
            }
            .navigationTitle("Scan Receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingCamera) {
                ImagePicker(selectedImage: $capturedImage, sourceType: .camera)
            }
            .sheet(isPresented: $showingImagePicker) {
                ImagePicker(selectedImage: $capturedImage, sourceType: .photoLibrary)
            }
            .alert("Notice", isPresented: $showingAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func processImage() {
        guard let image = capturedImage else { return }
        
        isProcessing = true
        
        Task {
            do {
                // OCR recognition
                let ocrResults = try await ocrService.recognizeText(from: image)
                
                // AI extraction
                let extracted = try await aiService.extractExpenseData(from: ocrResults)
                
                await MainActor.run {
                    isProcessing = false
                    
                    // Create expense if valid
                    if extracted.isValid {
                        let expense = Expense(
                            amount: extracted.amount ?? 0,
                            currency: extracted.currency ?? "HKD",
                            merchant: extracted.merchant ?? "Unknown",
                            category: extracted.category ?? "Other",
                            date: extracted.date ?? Date(),
                            receiptImageData: image.jpegData(compressionQuality: 0.8)
                        )
                        modelContext.insert(expense)
                        try? modelContext.save()
                        dismiss()
                    } else {
                        alertMessage = "Could not extract expense data from receipt. Please try again or enter manually."
                        showingAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    isProcessing = false
                    alertMessage = "Processing failed: \(error.localizedDescription)"
                    showingAlert = true
                }
            }
        }
    }
}

#Preview {
    CameraView()
}
