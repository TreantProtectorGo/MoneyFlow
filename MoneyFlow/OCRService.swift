//
//  OCRService.swift
//  MoneyFlow
//
//  Created by Wing - on 2026/1/3.
//

import Foundation
import Vision
import UIKit

class OCRService {
    
    enum OCRError: LocalizedError {
        case imageProcessingFailed
        case noTextFound
        case recognitionFailed(String)
        
        var errorDescription: String? {
            switch self {
            case .imageProcessingFailed:
                return "Failed to process image"
            case .noTextFound:
                return "No text found in image"
            case .recognitionFailed(let reason):
                return "Text recognition failed: \(reason)"
            }
        }
    }
    
    /// Recognize text from image
    func recognizeText(from image: UIImage) async throws -> [String] {
        guard let cgImage = image.cgImage else {
            throw OCRError.imageProcessingFailed
        }
        
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error = error {
                    continuation.resume(throwing: OCRError.recognitionFailed(error.localizedDescription))
                    return
                }
                
                guard let observations = request.results as? [VNRecognizedTextObservation] else {
                    continuation.resume(throwing: OCRError.noTextFound)
                    return
                }
                
                let recognizedStrings = observations.compactMap { observation in
                    observation.topCandidates(1).first?.string
                }
                
                if recognizedStrings.isEmpty {
                    continuation.resume(throwing: OCRError.noTextFound)
                } else {
                    continuation.resume(returning: recognizedStrings)
                }
            }
            
            // Configure recognition settings
            request.recognitionLevel = .accurate
            request.recognitionLanguages = ["zh-Hant", "en-US"]
            request.usesLanguageCorrection = true
            
            // Execute request
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            do {
                try handler.perform([request])
            } catch {
                continuation.resume(throwing: OCRError.recognitionFailed(error.localizedDescription))
            }
        }
    }
    
    /// Preprocess image to improve OCR accuracy
    func preprocessImage(_ image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        
        // Limit max size to improve processing speed
        let maxDimension: CGFloat = 1024
        let size = image.size
        let scale: CGFloat
        
        if size.width > size.height {
            scale = maxDimension / size.width
        } else {
            scale = maxDimension / size.height
        }
        
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)
        
        UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage
    }
}
