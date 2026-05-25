import Foundation

/// Bridge between the Share Extension and the main app.
///
/// The Share Extension can't safely open the SwiftData store (memory caps,
/// no SwiftData CloudKit support cross-process). Instead it drops a small
/// payload into the App Group container, and the main app picks it up on
/// next launch.
///
/// File layout in the App Group container:
///   inbox/
///     <uuid>.json          ← PendingShare metadata
///     <uuid>-attachment.*  ← optional image/PDF attachment
enum ShareInbox {
    static let appGroupID = "group.com.carlosreyes.scholarkeep"

    static var containerURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)
    }

    static var inboxURL: URL? {
        guard let base = containerURL else { return nil }
        let url = base.appendingPathComponent("inbox", isDirectory: true)
        if !FileManager.default.fileExists(atPath: url.path) {
            try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        }
        return url
    }

    // MARK: Pending share payload

    struct PendingShare: Codable, Identifiable, Equatable {
        let id: UUID
        let createdAt: Date
        /// Free-text content shared (subject + body of an email, snippet of a webpage, etc.)
        var text: String?
        /// Source URL if shared from Safari / Mail link / web page.
        var sourceURL: URL?
        /// File name of the attached image/PDF in the inbox folder, if any.
        var attachmentFilename: String?
        /// Best-guess content kind (image vs. text vs. url) for UI labelling.
        var kind: Kind

        enum Kind: String, Codable { case text, url, image, pdf, mixed }
    }

    // MARK: Read (main app)

    /// Returns all pending shares sorted oldest-first.
    static func pending() -> [PendingShare] {
        guard let inbox = inboxURL,
              let files = try? FileManager.default.contentsOfDirectory(at: inbox,
                                                                       includingPropertiesForKeys: nil) else {
            return []
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return files
            .filter { $0.pathExtension == "json" }
            .compactMap { url -> PendingShare? in
                guard let data = try? Data(contentsOf: url),
                      let share = try? decoder.decode(PendingShare.self, from: data) else {
                    return nil
                }
                return share
            }
            .sorted { $0.createdAt < $1.createdAt }
    }

    /// Returns the file URL for a pending share's attachment, if present.
    static func attachmentURL(for share: PendingShare) -> URL? {
        guard let inbox = inboxURL, let filename = share.attachmentFilename else { return nil }
        return inbox.appendingPathComponent(filename)
    }

    /// Removes a pending share's JSON and attachment from disk after the
    /// main app has finished importing it.
    static func consume(_ share: PendingShare) {
        guard let inbox = inboxURL else { return }
        try? FileManager.default.removeItem(at: inbox.appendingPathComponent("\(share.id.uuidString).json"))
        if let attachmentURL = attachmentURL(for: share) {
            try? FileManager.default.removeItem(at: attachmentURL)
        }
    }

    // MARK: Write (share extension)

    /// Drop a new share into the inbox. `attachmentData` will be saved alongside.
    @discardableResult
    static func write(text: String?,
                      sourceURL: URL?,
                      attachmentData: Data?,
                      attachmentExtension: String?,
                      kind: PendingShare.Kind) -> Bool {
        guard let inbox = inboxURL else { return false }

        let id = UUID()
        var share = PendingShare(
            id: id,
            createdAt: .now,
            text: text,
            sourceURL: sourceURL,
            attachmentFilename: nil,
            kind: kind
        )

        if let data = attachmentData, let ext = attachmentExtension {
            let filename = "\(id.uuidString)-attachment.\(ext)"
            let url = inbox.appendingPathComponent(filename)
            do {
                try data.write(to: url)
                share.attachmentFilename = filename
            } catch {
                // Fall through — share without attachment
            }
        }

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        guard let payload = try? encoder.encode(share) else { return false }
        let jsonURL = inbox.appendingPathComponent("\(id.uuidString).json")
        do {
            try payload.write(to: jsonURL, options: .atomic)
            return true
        } catch {
            return false
        }
    }
}
