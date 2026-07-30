import Foundation
import PDFKit
import UIKit

enum ReceiptDocumentReaderError: LocalizedError {
    case unsupportedDocument
    case unreadableDocument

    var errorDescription: String? {
        switch self {
        case .unsupportedDocument:
            return "ScholarKeep can read receipt images and PDFs."
        case .unreadableDocument:
            return "ScholarKeep could not read this receipt."
        }
    }
}

struct ReceiptDocumentResult {
    let parsed: ParsedReceipt
    let ocrText: String
}

enum ReceiptDocumentReader {
    static func read(data: Data, mimeType: String) async throws -> ReceiptDocumentResult {
        let images: [UIImage]
        if mimeType == "application/pdf" {
            images = try renderPDF(data: data)
        } else if mimeType.hasPrefix("image/"), let image = UIImage(data: data) {
            images = [image]
        } else {
            throw ReceiptDocumentReaderError.unsupportedDocument
        }

        guard !images.isEmpty else { throw ReceiptDocumentReaderError.unreadableDocument }
        let lines = try await ReceiptOCR.recognizeAll(images: images)
        let parsed = ReceiptParser.parse(lines: lines)
        return ReceiptDocumentResult(parsed: parsed, ocrText: parsed.rawText)
    }

    static func inferredMimeType(for url: URL) -> String {
        switch url.pathExtension.lowercased() {
        case "pdf": return "application/pdf"
        case "png": return "image/png"
        case "heic", "heif": return "image/heic"
        default: return "image/jpeg"
        }
    }

    private static func renderPDF(data: Data, maxPages: Int = 6) throws -> [UIImage] {
        guard let document = PDFDocument(data: data) else {
            throw ReceiptDocumentReaderError.unreadableDocument
        }
        return (0..<min(document.pageCount, maxPages)).compactMap { index in
            guard let page = document.page(at: index) else { return nil }
            let box = page.bounds(for: .mediaBox)
            guard box.width > 0, box.height > 0 else { return nil }
            let maxDimension: CGFloat = 2_200
            let scale = min(2.0, maxDimension / max(box.width, box.height))
            let size = CGSize(width: box.width * scale, height: box.height * scale)
            let renderer = UIGraphicsImageRenderer(size: size)
            return renderer.image { context in
                UIColor.white.setFill()
                context.fill(CGRect(origin: .zero, size: size))
                context.cgContext.saveGState()
                context.cgContext.translateBy(x: 0, y: size.height)
                context.cgContext.scaleBy(x: scale, y: -scale)
                page.draw(with: .mediaBox, to: context.cgContext)
                context.cgContext.restoreGState()
            }
        }
    }
}
