import SwiftUI
import SwiftData
import PhotosUI
import UIKit

/// Orchestrates a single capture: scan → OCR → review.
struct CaptureFlowView: View {
    enum Source { case scanner, photoLibrary }

    @Environment(\.dismiss) private var dismiss
    let student: Student
    let source: Source

    @State private var showScanner = false
    @State private var photoItem: PhotosPickerItem?
    @State private var images: [UIImage] = []
    @State private var parsed: ParsedReceipt?
    @State private var ocrText: String = ""
    @State private var processingError: String?
    @State private var isProcessing = false

    var body: some View {
        Group {
            if let parsed {
                ExpenseReviewView(
                    scannedImages: images,
                    parsed: parsed,
                    rawOCRText: ocrText,
                    student: student
                )
            } else if isProcessing {
                ProgressView("Reading receipt…")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let processingError {
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.largeTitle)
                        .foregroundStyle(.red)
                    Text(processingError).multilineTextAlignment(.center).padding()
                    Button("Done") { dismiss() }
                }
            } else {
                Color.clear
            }
        }
        .sheet(isPresented: $showScanner) {
            DocumentScannerView { result in
                showScanner = false
                switch result {
                case .scanned(let imgs): processImages(imgs)
                case .cancelled:         dismiss()
                case .failed(let error): processingError = error.localizedDescription
                }
            }
            .ignoresSafeArea()
        }
        .photosPicker(isPresented: photoPickerBinding, selection: $photoItem, matching: .images)
        .onChange(of: photoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    processImages([image])
                } else {
                    dismiss()
                }
            }
        }
        .onAppear {
            switch source {
            case .scanner:       showScanner = true
            case .photoLibrary:  photoItem = nil
            }
        }
    }

    private var photoPickerBinding: Binding<Bool> {
        Binding(
            get: { source == .photoLibrary && photoItem == nil && images.isEmpty && parsed == nil && !isProcessing },
            set: { _ in }
        )
    }

    private func processImages(_ imgs: [UIImage]) {
        images = imgs
        isProcessing = true
        Task {
            do {
                let lines = try await ReceiptOCR.recognizeAll(images: imgs)
                let parsedReceipt = ReceiptParser.parse(lines: lines)
                await MainActor.run {
                    self.ocrText = parsedReceipt.rawText
                    self.parsed = parsedReceipt
                    self.isProcessing = false
                }
            } catch {
                await MainActor.run {
                    self.processingError = "OCR failed: \(error.localizedDescription)"
                    self.isProcessing = false
                }
            }
        }
    }
}
