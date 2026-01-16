//
//  VoiceInputView.swift
//  MoneyFlow
//
//  Created by Wing - on 2026/1/3.
//

import SwiftUI

struct VoiceInputView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var speechService = SpeechRecognitionService()
    @State private var isProcessing = false
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    let onExpenseExtracted: (ExtractedExpenseData) -> Void
    private let aiService = AIService()
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                VStack(spacing: 30) {
                    Spacer()
                    
                    // Microphone animation
                    ZStack {
                        if speechService.isRecording {
                            Circle()
                                .fill(Color.red.opacity(0.2))
                                .frame(width: 200, height: 200)
                                .scaleEffect(speechService.isRecording ? 1.2 : 1.0)
                                .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: speechService.isRecording)
                        }
                        
                        Image(systemName: "mic.fill")
                            .font(.system(size: 80))
                            .foregroundStyle(
                                speechService.isRecording ?
                                LinearGradient(colors: [.red, .pink], startPoint: .top, endPoint: .bottom) :
                                LinearGradient(colors: [.purple, .pink], startPoint: .top, endPoint: .bottom)
                            )
                    }
                    
                    // Status text
                    Text(speechService.isRecording ? "Listening..." : "Tap button below to start")
                        .font(.title2)
                        .fontWeight(.semibold)
                    
                    // Recognized text
                    if !speechService.recognizedText.isEmpty || speechService.isRecording {
                        ScrollView {
                            TextField("Tap to edit text...", text: $speechService.recognizedText, axis: .vertical)
                                .font(.body)
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.white.opacity(0.8))
                                .cornerRadius(12)
                        }
                        .frame(maxHeight: 200)
                        .padding(.horizontal)
                    }

                    
                    Spacer()
                    
                    // Control buttons
                    if !isProcessing {
                        if speechService.isRecording {
                            Button(action: stopAndProcess) {
                                HStack {
                                    Image(systemName: "stop.fill")
                                    Text("Done")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(
                                    LinearGradient(
                                        colors: [.red, .orange],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .cornerRadius(15)
                            }
                            .padding(.horizontal)
                        } else {
                            Button(action: startRecording) {
                                HStack {
                                    Text("Start Recording")
                                        .fontWeight(.semibold)
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .glassEffect(.regular, in: .rect(cornerRadius: 24))
                            }
                            .padding(.horizontal)
                        }
                    } else {
                        HStack(spacing: 12) {
                            ProgressView()
                            Text("Processing...")
                                .font(.subheadline)
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 15)
                                .fill(.blue.opacity(0.1))
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Voice Expense")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        speechService.stopRecording()
                        dismiss()
                    }
                }
            }
            .alert("Notice", isPresented: $showingAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(alertMessage)
            }
        }
        .task {
            await requestPermission()
        }
    }
    
    private func requestPermission() async {
        let authorized = await speechService.requestAuthorization()
        if !authorized {
            alertMessage = "Microphone and speech recognition permissions are required"
            showingAlert = true
        }
    }
    
    private func startRecording() {
        do {
            try speechService.startRecording()
        } catch {
            alertMessage = "Failed to start recording: \(error.localizedDescription)"
            showingAlert = true
        }
    }
    
    private func stopAndProcess() {
        speechService.stopRecording()
        
        guard !speechService.recognizedText.isEmpty else {
            alertMessage = "No speech recognized, please try again"
            showingAlert = true
            return
        }
        
        Task {
            isProcessing = true
            
            do {
                let extractedData = try await aiService.extractExpenseFromVoice(speechService.recognizedText)
                
                await MainActor.run {
                    isProcessing = false
                    onExpenseExtracted(extractedData)
                    dismiss()
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
    VoiceInputView { data in
        print("Extracted: \(data)")
    }
}
