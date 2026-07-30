import Foundation
import SwiftData

enum ReceiptCandidateStatus: String, Codable, CaseIterable {
    case pending
    case imported
    case dismissed
}

enum ReceiptCandidateSource: String, Codable {
    case gmail
    case shareSheet
}

/// A possible receipt discovered from an external source.
///
/// Candidates are deliberately separate from `Expense`: the parent must review
/// and assign a student before external content becomes a scholarship record.
@Model
final class ReceiptCandidate {
    var id: UUID = UUID()
    var sourceRaw: String = ReceiptCandidateSource.gmail.rawValue
    var sourceMessageID: String = ""
    var sourceThreadID: String?
    var sender: String = ""
    var subject: String = ""
    var receivedAt: Date = Date.now
    var snippet: String = ""
    var bodyText: String = ""

    var suggestedVendor: String = ""
    var suggestedPurchaseDate: Date?
    var suggestedSubtotal: Decimal?
    var suggestedTax: Decimal?
    var suggestedTotal: Decimal?
    var suggestedLineItemsData: Data?

    var attachmentFilename: String?
    var attachmentMimeType: String?
    @Attribute(.externalStorage) var attachmentData: Data?
    var ocrText: String = ""

    var detectionScore: Int = 0
    var detectionReasons: [String] = []
    var statusRaw: String = ReceiptCandidateStatus.pending.rawValue
    var createdAt: Date = Date.now
    var importedExpenseID: UUID?

    init(
        id: UUID = UUID(),
        source: ReceiptCandidateSource,
        sourceMessageID: String,
        sourceThreadID: String? = nil,
        sender: String,
        subject: String,
        receivedAt: Date,
        snippet: String,
        bodyText: String,
        suggestedVendor: String = "",
        suggestedPurchaseDate: Date? = nil,
        suggestedSubtotal: Decimal? = nil,
        suggestedTax: Decimal? = nil,
        suggestedTotal: Decimal? = nil,
        suggestedLineItems: [ParsedLineItem] = [],
        attachmentFilename: String? = nil,
        attachmentMimeType: String? = nil,
        attachmentData: Data? = nil,
        ocrText: String = "",
        detectionScore: Int = 0,
        detectionReasons: [String] = [],
        status: ReceiptCandidateStatus = .pending,
        createdAt: Date = .now
    ) {
        self.id = id
        self.sourceRaw = source.rawValue
        self.sourceMessageID = sourceMessageID
        self.sourceThreadID = sourceThreadID
        self.sender = sender
        self.subject = subject
        self.receivedAt = receivedAt
        self.snippet = snippet
        self.bodyText = bodyText
        self.suggestedVendor = suggestedVendor
        self.suggestedPurchaseDate = suggestedPurchaseDate
        self.suggestedSubtotal = suggestedSubtotal
        self.suggestedTax = suggestedTax
        self.suggestedTotal = suggestedTotal
        self.suggestedLineItemsData = try? JSONEncoder().encode(
            suggestedLineItems.map(StoredLineItem.init)
        )
        self.attachmentFilename = attachmentFilename
        self.attachmentMimeType = attachmentMimeType
        self.attachmentData = attachmentData
        self.ocrText = ocrText
        self.detectionScore = detectionScore
        self.detectionReasons = detectionReasons
        self.statusRaw = status.rawValue
        self.createdAt = createdAt
    }

    var source: ReceiptCandidateSource {
        get { ReceiptCandidateSource(rawValue: sourceRaw) ?? .gmail }
        set { sourceRaw = newValue.rawValue }
    }

    var status: ReceiptCandidateStatus {
        get { ReceiptCandidateStatus(rawValue: statusRaw) ?? .pending }
        set { statusRaw = newValue.rawValue }
    }

    var suggestedLineItems: [ParsedLineItem] {
        get {
            guard let data = suggestedLineItemsData,
                  let stored = try? JSONDecoder().decode([StoredLineItem].self, from: data)
            else { return [] }
            return stored.map(\.parsed)
        }
        set {
            suggestedLineItemsData = try? JSONEncoder().encode(newValue.map(StoredLineItem.init))
        }
    }
}

private struct StoredLineItem: Codable {
    let descriptionText: String
    let amount: Decimal

    init(_ item: ParsedLineItem) {
        descriptionText = item.descriptionText
        amount = item.amount
    }

    var parsed: ParsedLineItem {
        ParsedLineItem(descriptionText: descriptionText, amount: amount)
    }
}
