//
//  ErrorHandling.swift
//  MoneyFlow
//
//  Created by Wing - on 2026/1/16.
//

import Foundation
import SwiftUI

/// Centralized application error types
enum AppError: LocalizedError {
    
    // MARK: - Data Errors
    case invalidInput(String)
    case saveFailed(Error)
    case deleteFailed(Error)
    case fetchFailed(Error)
    
    // MARK: - Network Errors
    case networkError(Error)
    case apiError(String)
    case noInternetConnection
    
    // MARK: - Permission Errors
    case permissionDenied(String)
    case cameraAccessDenied
    case microphoneAccessDenied
    
    // MARK: - Service Errors
    case ocrFailed(Error)
    case aiProcessingFailed(Error)
    case speechRecognitionFailed(Error)
    
    // MARK: - Validation Errors
    case invalidAmount
    case missingRequiredField(String)
    
    // MARK: - Unknown
    case unknown(Error)
    
    /// User-friendly error description
    var errorDescription: String? {
        switch self {
        // Data Errors
        case .invalidInput(let field):
            return "Invalid input for \(field). Please check and try again."
        case .saveFailed:
            return "Failed to save expense. Please try again."
        case .deleteFailed:
            return "Failed to delete expense. Please try again."
        case .fetchFailed:
            return "Failed to load expenses. Please try again."
            
        // Network Errors
        case .networkError:
            return "Network error occurred. Please check your connection."
        case .apiError(let message):
            return "API Error: \(message)"
        case .noInternetConnection:
            return "No internet connection. Please check your network settings."
            
        // Permission Errors
        case .permissionDenied(let feature):
            return "\(feature) permission is required. Please enable it in Settings."
        case .cameraAccessDenied:
            return "Camera access is required to scan receipts. Please enable it in Settings."
        case .microphoneAccessDenied:
            return "Microphone access is required for voice input. Please enable it in Settings."
            
        // Service Errors
        case .ocrFailed:
            return "Failed to recognize text from image. Please try again with a clearer photo."
        case .aiProcessingFailed:
            return "Failed to process data. Please try entering manually."
        case .speechRecognitionFailed:
            return "Failed to recognize speech. Please try again."
            
        // Validation Errors
        case .invalidAmount:
            return "Please enter a valid amount greater than 0."
        case .missingRequiredField(let field):
            return "\(field) is required. Please fill it in."
            
        // Unknown
        case .unknown(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
    
    /// Recovery suggestion
    var recoverySuggestion: String? {
        switch self {
        case .cameraAccessDenied, .microphoneAccessDenied, .permissionDenied:
            return "Go to Settings > MoneyFlow to enable permissions."
        case .noInternetConnection:
            return "Please check your WiFi or cellular data connection."
        case .ocrFailed:
            return "Try taking a clearer photo with better lighting."
        case .invalidAmount:
            return "Amount must be a positive number."
        default:
            return "If the problem persists, please restart the app."
        }
    }
}

/// Error presenter for managing and displaying errors
/// Observable object that can be used across the app
@Observable
class ErrorPresenter {
    
    /// Current error to display
    var currentError: AppError?
    
    /// Whether to show error alert
    var isShowingError: Bool = false
    
    /// Handle and present an error
    /// - Parameter error: The error to handle
    func handle(_ error: Error) {
        // Convert to AppError if needed
        if let appError = error as? AppError {
            currentError = appError
        } else {
            currentError = .unknown(error)
        }
        isShowingError = true
    }
    
    /// Handle and present an AppError
    /// - Parameter error: The AppError to handle
    func handle(_ error: AppError) {
        currentError = error
        isShowingError = true
    }
    
    /// Clear current error
    func clearError() {
        currentError = nil
        isShowingError = false
    }
    
    /// Log error for debugging (can be extended to use proper logging framework)
    private func logError(_ error: Error) {
        #if DEBUG
        print("❌ Error: \(error)")
        if let appError = error as? AppError {
            print("   Description: \(appError.errorDescription ?? "No description")")
            print("   Recovery: \(appError.recoverySuggestion ?? "No suggestion")")
        }
        #endif
    }
}

/// View modifier for error handling
struct ErrorAlert: ViewModifier {
    @Bindable var errorPresenter: ErrorPresenter
    
    func body(content: Content) -> some View {
        content
            .alert("Error", isPresented: $errorPresenter.isShowingError) {
                Button("OK") {
                    errorPresenter.clearError()
                }
            } message: {
                if let error = errorPresenter.currentError {
                    VStack(alignment: .leading, spacing: 8) {
                        if let description = error.errorDescription {
                            Text(description)
                        }
                        if let recovery = error.recoverySuggestion {
                            Text(recovery)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
    }
}

/// View extension for easy error handling
extension View {
    func errorAlert(_ errorPresenter: ErrorPresenter) -> some View {
        modifier(ErrorAlert(errorPresenter: errorPresenter))
    }
}
