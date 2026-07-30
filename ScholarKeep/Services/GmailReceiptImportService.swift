import Foundation
import SwiftData

struct GmailScanResult {
    let searchedCount: Int
    let importedCount: Int
    let duplicateCount: Int
}

@MainActor
enum GmailReceiptImportService {
    static func scan(
        modelContext: ModelContext,
        newerThanDays: Int = 365,
        maxMessages: Int = 50
    ) async throws -> GmailScanResult {
        let descriptor = FetchDescriptor<ReceiptCandidate>()
        let existing = try modelContext.fetch(descriptor)
        let existingIDs = Set(
            existing
                .filter { $0.source == .gmail }
                .map(\.sourceMessageID)
        )

        let client = GmailAPIClient(accessTokenProvider: {
            try await GoogleOAuthService.shared.validAccessToken()
        })
        let drafts = try await client.receiptDrafts(
            newerThanDays: newerThanDays,
            maxMessages: maxMessages
        )
        var inserted = 0
        var duplicateCount = 0

        for draft in drafts {
            if existingIDs.contains(draft.messageID) {
                duplicateCount += 1
                continue
            }
            let candidate = await candidate(from: draft)
            modelContext.insert(candidate)
            inserted += 1
        }
        try modelContext.save()
        return GmailScanResult(
            searchedCount: drafts.count,
            importedCount: inserted,
            duplicateCount: duplicateCount
        )
    }

    private static func candidate(from draft: GmailReceiptDraft) async -> ReceiptCandidate {
        let combinedText = [draft.subject, draft.snippet, draft.bodyText]
            .joined(separator: "\n")
        var vendor = EmailReceiptDetector.inferredVendor(
            sender: draft.sender,
            subject: draft.subject
        )
        var purchaseDate = EmailReceiptDetector.inferredDate(from: combinedText) ?? draft.receivedAt
        let inferredAmounts = EmailReceiptDetector.inferredAmounts(from: combinedText)
        var subtotal = inferredAmounts.subtotal
        var tax = inferredAmounts.tax
        var total = inferredAmounts.total
        var lineItems: [ParsedLineItem] = []
        var ocrText = ""

        if let data = draft.attachmentData,
           data.count <= 15_000_000,
           let mime = draft.attachmentMimeType,
           let result = try? await ReceiptDocumentReader.read(data: data, mimeType: mime) {
            if !result.parsed.vendorName.isEmpty { vendor = result.parsed.vendorName }
            if let date = result.parsed.purchaseDate { purchaseDate = date }
            subtotal = result.parsed.subtotal ?? subtotal
            tax = result.parsed.tax ?? tax
            total = result.parsed.total ?? total
            lineItems = result.parsed.lineItems
            ocrText = result.ocrText
        }

        return ReceiptCandidate(
            source: .gmail,
            sourceMessageID: draft.messageID,
            sourceThreadID: draft.threadID,
            sender: draft.sender,
            subject: draft.subject,
            receivedAt: draft.receivedAt,
            snippet: draft.snippet,
            bodyText: draft.bodyText,
            suggestedVendor: vendor,
            suggestedPurchaseDate: purchaseDate,
            suggestedSubtotal: subtotal,
            suggestedTax: tax,
            suggestedTotal: total,
            suggestedLineItems: lineItems,
            attachmentFilename: draft.attachmentFilename,
            attachmentMimeType: draft.attachmentMimeType,
            attachmentData: draft.attachmentData,
            ocrText: ocrText,
            detectionScore: draft.detection.score,
            detectionReasons: draft.detection.reasons
        )
    }
}
