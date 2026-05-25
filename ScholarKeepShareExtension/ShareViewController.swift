import UIKit
import UniformTypeIdentifiers

/// Share Extension entry point. Receives the shared content, writes it
/// to the App Group inbox, and dismisses. Heavy lifting (OCR, parsing,
/// saving to SwiftData) happens later in the main app when it next launches.
class ShareViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor.systemBackground
        Task {
            await processSharedContent()
            await MainActor.run { presentConfirmation() }
        }
    }

    // MARK: - Processing

    private func processSharedContent() async {
        guard let extensionContext,
              let inputItems = extensionContext.inputItems as? [NSExtensionItem] else {
            return
        }

        var collectedText: String?
        var collectedURL: URL?
        var attachmentData: Data?
        var attachmentExt: String?
        var kind: ShareInbox.PendingShare.Kind = .text

        for item in inputItems {
            // Walk every attached provider once.
            guard let providers = item.attachments else { continue }

            for provider in providers {
                // Image (jpg/png/heic from camera roll, screenshot, etc.)
                if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
                    if let result = await loadImageData(from: provider) {
                        attachmentData = result.data
                        attachmentExt = result.ext
                        kind = .image
                    }
                    continue
                }

                // PDF (school tuition statement, etc.)
                if provider.hasItemConformingToTypeIdentifier(UTType.pdf.identifier) {
                    if let result = await loadPDFData(from: provider) {
                        attachmentData = result.data
                        attachmentExt = "pdf"
                        kind = .pdf
                    }
                    continue
                }

                // URL (Safari, Mail link, etc.)
                if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
                    if let url = await loadURL(from: provider) {
                        collectedURL = url
                        if kind == .text { kind = .url }
                    }
                    continue
                }

                // Plain text (selected text in any app)
                if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
                    if let text = await loadPlainText(from: provider) {
                        if let existing = collectedText {
                            collectedText = existing + "\n\n" + text
                        } else {
                            collectedText = text
                        }
                    }
                    continue
                }
            }

            // Items also carry an attributedContentText (Mail's body) or a
            // contentText property — pull whichever is non-empty.
            if collectedText == nil {
                if let attr = item.attributedContentText?.string, !attr.isEmpty {
                    collectedText = attr
                }
            }
        }

        // If we found multiple kinds, mark mixed for clearer UI later.
        if attachmentData != nil && (collectedText != nil || collectedURL != nil) {
            kind = .mixed
        }

        _ = ShareInbox.write(
            text: collectedText,
            sourceURL: collectedURL,
            attachmentData: attachmentData,
            attachmentExtension: attachmentExt,
            kind: kind
        )
    }

    // MARK: - Loaders

    private struct AttachmentResult { let data: Data; let ext: String }

    private func loadImageData(from provider: NSItemProvider) async -> AttachmentResult? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.image.identifier, options: nil) { item, _ in
                if let url = item as? URL, let data = try? Data(contentsOf: url) {
                    let ext = url.pathExtension.isEmpty ? "jpg" : url.pathExtension.lowercased()
                    continuation.resume(returning: AttachmentResult(data: data, ext: ext))
                    return
                }
                if let data = item as? Data {
                    continuation.resume(returning: AttachmentResult(data: data, ext: "jpg"))
                    return
                }
                if let image = item as? UIImage,
                   let data = image.jpegData(compressionQuality: 0.85) {
                    continuation.resume(returning: AttachmentResult(data: data, ext: "jpg"))
                    return
                }
                continuation.resume(returning: nil)
            }
        }
    }

    private func loadPDFData(from provider: NSItemProvider) async -> AttachmentResult? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.pdf.identifier, options: nil) { item, _ in
                if let url = item as? URL, let data = try? Data(contentsOf: url) {
                    continuation.resume(returning: AttachmentResult(data: data, ext: "pdf"))
                    return
                }
                if let data = item as? Data {
                    continuation.resume(returning: AttachmentResult(data: data, ext: "pdf"))
                    return
                }
                continuation.resume(returning: nil)
            }
        }
    }

    private func loadURL(from provider: NSItemProvider) async -> URL? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.url.identifier, options: nil) { item, _ in
                if let url = item as? URL {
                    continuation.resume(returning: url)
                    return
                }
                continuation.resume(returning: nil)
            }
        }
    }

    private func loadPlainText(from provider: NSItemProvider) async -> String? {
        await withCheckedContinuation { continuation in
            provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, _ in
                if let text = item as? String {
                    continuation.resume(returning: text)
                    return
                }
                if let data = item as? Data, let text = String(data: data, encoding: .utf8) {
                    continuation.resume(returning: text)
                    return
                }
                continuation.resume(returning: nil)
            }
        }
    }

    // MARK: - Confirmation UI

    private func presentConfirmation() {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 14
        stack.translatesAutoresizingMaskIntoConstraints = false

        let icon = UIImageView(image: UIImage(systemName: "checkmark.circle.fill"))
        icon.tintColor = UIColor.systemGreen
        icon.preferredSymbolConfiguration = UIImage.SymbolConfiguration(pointSize: 48, weight: .regular)

        let title = UILabel()
        title.text = "Saved to ScholarKeep"
        title.font = .systemFont(ofSize: 22, weight: .bold)
        title.textColor = .label

        let body = UILabel()
        body.text = "Open ScholarKeep to review and add this receipt to your records."
        body.font = .systemFont(ofSize: 15, weight: .regular)
        body.textColor = .secondaryLabel
        body.textAlignment = .center
        body.numberOfLines = 0
        body.translatesAutoresizingMaskIntoConstraints = false

        let button = UIButton(configuration: {
            var c = UIButton.Configuration.borderedProminent()
            c.title = "Done"
            c.cornerStyle = .large
            return c
        }())
        button.addTarget(self, action: #selector(dismissExtension), for: .touchUpInside)

        stack.addArrangedSubview(icon)
        stack.addArrangedSubview(title)
        stack.addArrangedSubview(body)
        stack.addArrangedSubview(UIView()) // spacer
        stack.addArrangedSubview(button)

        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 32),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -32),
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            body.widthAnchor.constraint(equalTo: stack.widthAnchor)
        ])
    }

    @objc private func dismissExtension() {
        extensionContext?.completeRequest(returningItems: nil, completionHandler: nil)
    }
}
