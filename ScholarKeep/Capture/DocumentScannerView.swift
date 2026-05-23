import SwiftUI
import VisionKit
import UIKit

/// SwiftUI wrapper around VNDocumentCameraViewController.
/// Returns one UIImage per scanned page.
struct DocumentScannerView: UIViewControllerRepresentable {
    enum ScanResult {
        case scanned([UIImage])
        case cancelled
        case failed(Error)
    }

    let onCompletion: (ScanResult) -> Void

    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let vc = VNDocumentCameraViewController()
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onCompletion: onCompletion) }

    final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
        let onCompletion: (ScanResult) -> Void

        init(onCompletion: @escaping (ScanResult) -> Void) {
            self.onCompletion = onCompletion
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController,
                                          didFinishWith scan: VNDocumentCameraScan) {
            var images: [UIImage] = []
            for i in 0..<scan.pageCount {
                images.append(scan.imageOfPage(at: i))
            }
            onCompletion(.scanned(images))
        }

        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
            onCompletion(.cancelled)
        }

        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            onCompletion(.failed(error))
        }
    }
}
