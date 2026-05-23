import Foundation
@preconcurrency import Vision
import UIKit
import CoreGraphics

/// On-device OCR using Apple Vision. Returns lines + bounding boxes.
struct OCRLine: Sendable {
    let text: String
    let boundingBox: CGRect   // normalized 0..1, Vision coordinates (origin lower-left)
}

enum ReceiptOCR {
    /// Run text recognition on a single image. Off the main thread.
    static func recognize(image: UIImage) async throws -> [OCRLine] {
        guard let cgImage = image.cgImage else { return [] }
        return try await withCheckedThrowingContinuation { continuation in
            let request = VNRecognizeTextRequest { request, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let observations = (request.results as? [VNRecognizedTextObservation]) ?? []
                let lines = observations.compactMap { obs -> OCRLine? in
                    guard let top = obs.topCandidates(1).first else { return nil }
                    return OCRLine(text: top.string, boundingBox: obs.boundingBox)
                }
                continuation.resume(returning: lines)
            }
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = true
            request.recognitionLanguages = ["en-US"]

            let handler = VNImageRequestHandler(cgImage: cgImage, orientation: .up)
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    static func recognizeAll(images: [UIImage]) async throws -> [OCRLine] {
        var combined: [OCRLine] = []
        for image in images {
            let lines = try await recognize(image: image)
            combined.append(contentsOf: lines)
        }
        return combined
    }
}
