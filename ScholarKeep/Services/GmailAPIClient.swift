import Foundation

struct GmailProfile: Decodable {
    let emailAddress: String
}

struct GmailReceiptDraft: Sendable {
    let messageID: String
    let threadID: String?
    let sender: String
    let subject: String
    let receivedAt: Date
    let snippet: String
    let bodyText: String
    let attachmentFilename: String?
    let attachmentMimeType: String?
    let attachmentData: Data?
    let detection: EmailReceiptDetection
}

enum GmailAPIError: LocalizedError {
    case invalidResponse
    case unauthorized
    case requestFailed(Int, String)

    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Gmail returned an unreadable response."
        case .unauthorized:
            return "Gmail access expired. Please reconnect your account."
        case .requestFailed(let status, let detail):
            return "Gmail request failed (\(status)). \(detail)"
        }
    }
}

struct GmailAPIClient {
    typealias AccessTokenProvider = @MainActor () async throws -> String

    private let accessTokenProvider: AccessTokenProvider
    private let session: URLSession
    private let baseURL = URL(string: "https://gmail.googleapis.com/gmail/v1/users/me")!

    init(
        accessTokenProvider: @escaping AccessTokenProvider,
        session: URLSession = .shared
    ) {
        self.accessTokenProvider = accessTokenProvider
        self.session = session
    }

    func profile() async throws -> GmailProfile {
        try await request(path: "profile")
    }

    func receiptDrafts(
        newerThanDays: Int = 365,
        maxMessages: Int = 50
    ) async throws -> [GmailReceiptDraft] {
        let query = """
        newer_than:\(max(1, newerThanDays))d {subject:receipt subject:invoice \
        subject:"order confirmation" subject:"payment confirmation" \
        subject:"payment received" subject:"your order" subject:"purchase confirmation"}
        """
        var components = URLComponents(
            url: baseURL.appendingPathComponent("messages"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "maxResults", value: "\(min(max(1, maxMessages), 100))")
        ]
        let list: GmailMessageList = try await request(url: components.url!)
        var drafts: [GmailReceiptDraft] = []

        for reference in list.messages ?? [] {
            let message: GmailMessage = try await request(
                path: "messages/\(reference.id)",
                queryItems: [URLQueryItem(name: "format", value: "full")]
            )
            let draft = try await makeDraft(from: message)
            if draft.detection.isLikelyReceipt {
                drafts.append(draft)
            }
        }
        return drafts.sorted { $0.receivedAt > $1.receivedAt }
    }

    private func makeDraft(from message: GmailMessage) async throws -> GmailReceiptDraft {
        let sender = message.payload.header(named: "From") ?? ""
        let subject = message.payload.header(named: "Subject") ?? "Possible receipt"
        let bodyText = message.payload.bestBodyText
        let attachments = message.payload.receiptAttachments
        let firstAttachment = attachments.first
        let attachmentData: Data?
        if let firstAttachment {
            if let inline = firstAttachment.inlineData {
                attachmentData = Data(base64URLEncoded: inline)
            } else if let attachmentID = firstAttachment.attachmentID {
                let response: GmailAttachmentResponse = try await request(
                    path: "messages/\(message.id)/attachments/\(attachmentID)"
                )
                attachmentData = Data(base64URLEncoded: response.data)
            } else {
                attachmentData = nil
            }
        } else {
            attachmentData = nil
        }

        let receivedAt: Date = {
            if let milliseconds = Double(message.internalDate ?? "") {
                return Date(timeIntervalSince1970: milliseconds / 1000)
            }
            if let raw = message.payload.header(named: "Date"),
               let date = Self.emailDateFormatter.date(from: raw) {
                return date
            }
            return .now
        }()

        let detection = EmailReceiptDetector.evaluate(
            subject: subject,
            sender: sender,
            snippet: message.snippet ?? "",
            bodyText: bodyText,
            hasReceiptAttachment: firstAttachment != nil
        )

        return GmailReceiptDraft(
            messageID: message.id,
            threadID: message.threadId,
            sender: sender,
            subject: subject,
            receivedAt: receivedAt,
            snippet: message.snippet ?? "",
            bodyText: bodyText,
            attachmentFilename: firstAttachment?.filename,
            attachmentMimeType: firstAttachment?.mimeType,
            attachmentData: attachmentData,
            detection: detection
        )
    }

    private func request<T: Decodable>(
        path: String,
        queryItems: [URLQueryItem] = []
    ) async throws -> T {
        var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = queryItems.isEmpty ? nil : queryItems
        return try await request(url: components.url!)
    }

    private func request<T: Decodable>(url: URL) async throws -> T {
        let token = try await accessTokenProvider()
        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await session.data(for: request)
        guard let http = response as? HTTPURLResponse else {
            throw GmailAPIError.invalidResponse
        }
        if http.statusCode == 401 { throw GmailAPIError.unauthorized }
        guard (200..<300).contains(http.statusCode) else {
            throw GmailAPIError.requestFailed(
                http.statusCode,
                String(data: data, encoding: .utf8) ?? ""
            )
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    private static let emailDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "EEE, d MMM yyyy HH:mm:ss Z"
        return formatter
    }()
}

private struct GmailMessageList: Decodable {
    let messages: [GmailMessageReference]?
}

private struct GmailMessageReference: Decodable {
    let id: String
}

private struct GmailMessage: Decodable {
    let id: String
    let threadId: String?
    let internalDate: String?
    let snippet: String?
    let payload: GmailMessagePart
}

private struct GmailMessagePart: Decodable {
    let mimeType: String?
    let filename: String?
    let headers: [GmailHeader]?
    let body: GmailMessageBody?
    let parts: [GmailMessagePart]?

    func header(named name: String) -> String? {
        headers?.first(where: { $0.name.caseInsensitiveCompare(name) == .orderedSame })?.value
    }

    var bestBodyText: String {
        let flattened = flattenedParts
        if let plain = flattened.first(where: { $0.mimeType == "text/plain" }),
           let encoded = plain.body?.data,
           let data = Data(base64URLEncoded: encoded),
           let text = String(data: data, encoding: .utf8) {
            return text
        }
        if let html = flattened.first(where: { $0.mimeType == "text/html" }),
           let encoded = html.body?.data,
           let data = Data(base64URLEncoded: encoded),
           let value = String(data: data, encoding: .utf8) {
            return value.htmlStripped
        }
        if let encoded = body?.data,
           let data = Data(base64URLEncoded: encoded),
           let text = String(data: data, encoding: .utf8) {
            return mimeType == "text/html" ? text.htmlStripped : text
        }
        return ""
    }

    var receiptAttachments: [GmailReceiptAttachment] {
        flattenedParts.compactMap { part in
            guard let mime = part.mimeType,
                  mime.hasPrefix("image/") || mime == "application/pdf"
            else { return nil }
            return GmailReceiptAttachment(
                filename: (part.filename?.isEmpty == false ? part.filename : nil) ?? "receipt",
                mimeType: mime,
                attachmentID: part.body?.attachmentId,
                inlineData: part.body?.data
            )
        }
    }

    private var flattenedParts: [GmailMessagePart] {
        [self] + (parts ?? []).flatMap(\.flattenedParts)
    }
}

private struct GmailHeader: Decodable {
    let name: String
    let value: String
}

private struct GmailMessageBody: Decodable {
    let attachmentId: String?
    let data: String?
}

private struct GmailAttachmentResponse: Decodable {
    let data: String
}

private struct GmailReceiptAttachment {
    let filename: String
    let mimeType: String
    let attachmentID: String?
    let inlineData: String?
}

private extension Data {
    init?(base64URLEncoded value: String) {
        var base64 = value
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        let remainder = base64.count % 4
        if remainder > 0 {
            base64 += String(repeating: "=", count: 4 - remainder)
        }
        self.init(base64Encoded: base64)
    }
}

private extension String {
    var htmlStripped: String {
        guard let data = data(using: .utf8),
              let attributed = try? NSAttributedString(
                data: data,
                options: [.documentType: NSAttributedString.DocumentType.html],
                documentAttributes: nil
              )
        else {
            return replacingOccurrences(of: "<[^>]+>", with: " ", options: .regularExpression)
        }
        return attributed.string
    }
}
