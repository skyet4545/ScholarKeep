import SwiftUI
import SwiftData
import PhotosUI
import UIKit
import VisionKit

/// Orchestrates a single capture: scan → OCR → review.
/// Handles three sources: VisionKit scanner, photo library, manual entry.
struct CaptureFlowView: View {
    enum Source { case scanner, photoLibrary }

    @Environment(\.dismiss) private var dismiss
    let student: Student
    let source: Source

    @State private var showScanner = false
    @State private var showPhotoPicker = false
    @State private var scannerUnavailable = false
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
                errorView(processingError)
            } else if scannerUnavailable {
                scannerUnavailableView
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
        .photosPicker(isPresented: $showPhotoPicker, selection: $photoItem, matching: .images)
        .onChange(of: showPhotoPicker) { _, isShowing in
            // User dismissed the picker without choosing → close the capture flow.
            if !isShowing && photoItem == nil && images.isEmpty && parsed == nil && !isProcessing {
                dismiss()
            }
        }
        .onChange(of: photoItem) { _, newItem in
            guard let newItem else { return }
            Task {
                if let data = try? await newItem.loadTransferable(type: Data.self),
                   let image = UIImage(data: data) {
                    await MainActor.run { processImages([image]) }
                } else {
                    await MainActor.run { dismiss() }
                }
            }
        }
        .onAppear {
            switch source {
            case .scanner:
                if VNDocumentCameraViewController.isSupported {
                    showScanner = true
                } else {
                    scannerUnavailable = true
                }
            case .photoLibrary:
                showPhotoPicker = true
            }
        }
    }

    private func errorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Image(systemName: "exclamationmark.triangle")
                .font(.largeTitle)
                .foregroundStyle(.red)
            Text(message).multilineTextAlignment(.center).padding()
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var scannerUnavailableView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.metering.unknown")
                .font(.largeTitle)
                .foregroundStyle(.secondary)
            Text("Camera scanning isn't available on this device").font(.headline)
            Text("Pick a receipt image from your photo library or add the expense manually.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal, 24)
            Button("Pick from library") {
                scannerUnavailable = false
                showPhotoPicker = true
            }
            .buttonStyle(.borderedProminent)
            Button("Cancel", role: .cancel) { dismiss() }
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
