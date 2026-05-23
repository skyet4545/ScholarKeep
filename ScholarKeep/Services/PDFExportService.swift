import Foundation
import PDFKit
import UIKit

/// Generates the per-expense "submission package" PDF and per-claim PDF described in §5.
/// Output written to the app's temporary directory and returned as a URL.
enum PDFExportService {

    // MARK: Public

    static func exportExpense(_ expense: Expense) throws -> URL {
        let filename = sanitize("ScholarKeep_Expense_\(expense.vendorName)_\(expense.purchaseDate.iso8601Day()).pdf")
        let pdfData = renderExpensePDF(expense)
        return try writePDF(data: pdfData, filename: filename)
    }

    static func exportClaim(_ claim: Claim) throws -> URL {
        let filename = sanitize("ScholarKeep_Claim_\(claim.title)_\(Date().iso8601Day()).pdf")
        let pdfData = renderClaimPDF(claim)
        return try writePDF(data: pdfData, filename: filename)
    }

    // MARK: PDF rendering

    private static let pageRect = CGRect(x: 0, y: 0, width: 612, height: 792) // US Letter
    private static let bottomMargin: CGFloat = 36
    private static let pageBottom: CGFloat = 792 - 36

    private static func renderExpensePDF(_ expense: Expense) -> Data {
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "ScholarKeep submission package",
            kCGPDFContextAuthor as String: "ScholarKeep"
        ]
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        return renderer.pdfData { ctx in
            ctx.beginPage()
            var y: CGFloat = 36
            drawTitle("Submission package — \(expense.vendorName.isEmpty ? "Expense" : expense.vendorName)", at: &y)
            drawDisclaimerHeader(at: &y)
            drawExpenseSummary(expense, at: &y, ctx: ctx)
            drawChecklist(expense.readinessChecklist, at: &y, ctx: ctx)
            for attachment in expense.attachments {
                ctx.beginPage()
                drawAttachmentPage(attachment, ctx: ctx)
            }
        }
    }

    private static func renderClaimPDF(_ claim: Claim) -> Data {
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "ScholarKeep claim — \(claim.title)",
            kCGPDFContextAuthor as String: "ScholarKeep"
        ]
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: format)
        return renderer.pdfData { ctx in
            ctx.beginPage()
            var y: CGFloat = 36
            drawTitle("Claim — \(claim.title)", at: &y)
            drawDisclaimerHeader(at: &y)
            drawClaimSummary(claim, at: &y, ctx: ctx)
            for expense in claim.expenses {
                ctx.beginPage()
                var ey: CGFloat = 36
                drawTitle("Expense — \(expense.vendorName.isEmpty ? "—" : expense.vendorName)", at: &ey)
                drawExpenseSummary(expense, at: &ey, ctx: ctx)
                drawChecklist(expense.readinessChecklist, at: &ey, ctx: ctx)
                for attachment in expense.attachments {
                    ctx.beginPage()
                    drawAttachmentPage(attachment, ctx: ctx)
                }
            }
        }
    }

    /// Begin a new page + reset y if we're about to overflow.
    private static func ensureRoom(_ minHeight: CGFloat, _ y: inout CGFloat, ctx: UIGraphicsPDFRendererContext) {
        if y + minHeight > pageBottom {
            ctx.beginPage()
            y = 36
        }
    }

    // MARK: Section drawing

    private static func drawTitle(_ text: String, at y: inout CGFloat) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 18)
        ]
        let height = drawString(text, in: CGRect(x: 36, y: y, width: pageRect.width - 72, height: 24), attrs: attrs)
        y += height + 4
        drawRule(at: &y)
    }

    private static func drawDisclaimerHeader(at y: inout CGFloat) {
        let text = DisclaimerCopy.short
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.italicSystemFont(ofSize: 9),
            .foregroundColor: UIColor.darkGray
        ]
        let height = drawString(text, in: CGRect(x: 36, y: y, width: pageRect.width - 72, height: 60), attrs: attrs)
        y += height + 8
    }

    private static func drawExpenseSummary(_ expense: Expense, at y: inout CGFloat, ctx: UIGraphicsPDFRendererContext) {
        let rows: [(String, String)] = [
            ("Vendor", expense.vendorName),
            ("Date", expense.purchaseDate.formatted(date: .long, time: .omitted)),
            ("Subtotal", expense.subtotal.formatted(.currency(code: expense.currency))),
            ("Tax", expense.tax.formatted(.currency(code: expense.currency))),
            ("Shipping", expense.shipping.formatted(.currency(code: expense.currency))),
            ("Total", expense.total.formatted(.currency(code: expense.currency))),
            ("Path", expense.acquisitionPath.displayName),
            ("Payment", expense.paymentMethod.displayName),
            ("Eligibility", expense.eligibilityResult?.displayName ?? "Not checked"),
            ("Pre-auth", expense.preAuthNumber ?? (expense.requiresPreAuth ? "REQUIRED — missing" : "n/a")),
            ("Student", expense.student?.displayName ?? "—"),
            ("Program", expense.student?.program.displayName ?? "—")
        ]
        for (k, v) in rows {
            ensureRoom(20, &y, ctx: ctx)
            drawKeyValue(k, v, at: &y)
        }
        if !expense.eligibilityReason.isEmpty {
            ensureRoom(40, &y, ctx: ctx)
            y += 4
            drawSubtitle("Eligibility reason", at: &y)
            drawParagraph(expense.eligibilityReason, at: &y)
        }
        if !expense.lineItems.isEmpty {
            ensureRoom(40, &y, ctx: ctx)
            y += 4
            drawSubtitle("Line items", at: &y)
            for item in expense.lineItems {
                ensureRoom(20, &y, ctx: ctx)
                drawKeyValue(item.descriptionText, item.amount.formatted(.currency(code: expense.currency)), at: &y)
            }
        }
        if !expense.notes.isEmpty {
            ensureRoom(40, &y, ctx: ctx)
            y += 4
            drawSubtitle("Notes", at: &y)
            drawParagraph(expense.notes, at: &y)
        }
        if !expense.educationalBenefitNote.isEmpty {
            ensureRoom(40, &y, ctx: ctx)
            y += 4
            drawSubtitle("Educational benefit", at: &y)
            drawParagraph(expense.educationalBenefitNote, at: &y)
        }
        drawRule(at: &y)
    }

    private static func drawClaimSummary(_ claim: Claim, at y: inout CGFloat, ctx: UIGraphicsPDFRendererContext) {
        let total = claim.expenses.reduce(Decimal(0)) { $0 + $1.total }
        let rows: [(String, String)] = [
            ("Title", claim.title),
            ("Status", claim.status.displayName),
            ("Student", claim.student?.displayName ?? "—"),
            ("Submitted", claim.submittedDate?.formatted(date: .long, time: .omitted) ?? "—"),
            ("Decision", claim.decisionDate?.formatted(date: .long, time: .omitted) ?? "—"),
            ("Paid", claim.paidDate?.formatted(date: .long, time: .omitted) ?? "—"),
            ("Reimbursement method", claim.reimbursementMethod?.displayName ?? "—"),
            ("Expected payout", claim.expectedPayout?.formatted(.currency(code: "USD")) ?? "—"),
            ("Actual payout", claim.actualPayout?.formatted(.currency(code: "USD")) ?? "—"),
            ("Total of expenses", total.formatted(.currency(code: "USD"))),
            ("Expense count", "\(claim.expenses.count)")
        ]
        for (k, v) in rows {
            ensureRoom(20, &y, ctx: ctx)
            drawKeyValue(k, v, at: &y)
        }
        if !claim.denialNote.isEmpty {
            ensureRoom(40, &y, ctx: ctx)
            y += 4
            drawSubtitle("Denial note", at: &y)
            drawParagraph(claim.denialNote, at: &y)
        }
        if !claim.appealNote.isEmpty {
            ensureRoom(40, &y, ctx: ctx)
            y += 4
            drawSubtitle("Appeal note", at: &y)
            drawParagraph(claim.appealNote, at: &y)
        }
    }

    private static func drawChecklist(_ checklist: ReadinessChecklist, at y: inout CGFloat, ctx: UIGraphicsPDFRendererContext) {
        ensureRoom(80, &y, ctx: ctx)
        drawSubtitle("Documentation readiness", at: &y)
        let rows: [(String, Bool?)] = [
            ("Itemized receipt", checklist.itemizedReceipt),
            ("Proof of payment", checklist.proofOfPayment),
            ("Student name present", checklist.studentNamePresent),
            ("Provider credentials", checklist.providerCredentials),
            ("Educational Benefit Form", checklist.educationalBenefitForm),
            ("Pre-auth on file (if required)", checklist.preAuthIfRequired),
            ("No handwritten alterations", checklist.noHandwrittenAlterations)
        ]
        for (label, value) in rows {
            ensureRoom(20, &y, ctx: ctx)
            let mark: String
            switch value {
            case .some(true):  mark = "[x]"
            case .some(false): mark = "[ ]"
            case .none:        mark = "[n/a]"
            }
            drawKeyValue(mark, label, at: &y)
        }
        drawRule(at: &y)
    }

    private static func drawAttachmentPage(_ attachment: Attachment, ctx: UIGraphicsPDFRendererContext) {
        let title = "\(attachment.type.displayName)"
        var y: CGFloat = 36
        drawTitle(title, at: &y)
        if attachment.mimeType.hasPrefix("image"),
           let data = attachment.fileData,
           let image = UIImage(data: data) {
            let maxW: CGFloat = pageRect.width - 72
            let maxH: CGFloat = pageRect.height - y - 36
            let scale = min(maxW / image.size.width, maxH / image.size.height, 1)
            let drawSize = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            let origin = CGPoint(x: (pageRect.width - drawSize.width) / 2, y: y)
            image.draw(in: CGRect(origin: origin, size: drawSize))
        } else if attachment.mimeType == "application/pdf",
                  let data = attachment.fileData,
                  let pdf = PDFDocument(data: data),
                  let page = pdf.page(at: 0) {
            let pageBounds = page.bounds(for: .mediaBox)
            let scale = min((pageRect.width - 72) / pageBounds.width, (pageRect.height - y - 36) / pageBounds.height, 1)
            let target = CGRect(x: (pageRect.width - pageBounds.width * scale) / 2,
                                y: y,
                                width: pageBounds.width * scale,
                                height: pageBounds.height * scale)
            if let cg = UIGraphicsGetCurrentContext() {
                cg.saveGState()
                cg.translateBy(x: target.minX, y: target.minY + target.height)
                cg.scaleBy(x: scale, y: -scale)
                page.draw(with: .mediaBox, to: cg)
                cg.restoreGState()
            }
        } else {
            drawParagraph("Attachment of type \(attachment.mimeType) — not rendered here. The original is stored in the app.", at: &y)
        }
    }

    // MARK: Primitives

    @discardableResult
    private static func drawString(_ text: String, in rect: CGRect, attrs: [NSAttributedString.Key: Any]) -> CGFloat {
        let attributed = NSAttributedString(string: text, attributes: attrs)
        let constraint = CGSize(width: rect.width, height: .greatestFiniteMagnitude)
        let computed = attributed.boundingRect(with: constraint, options: [.usesLineFragmentOrigin, .usesFontLeading], context: nil)
        attributed.draw(in: CGRect(x: rect.minX, y: rect.minY, width: rect.width, height: ceil(computed.height)))
        return ceil(computed.height)
    }

    private static func drawSubtitle(_ text: String, at y: inout CGFloat) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.boldSystemFont(ofSize: 12),
            .foregroundColor: UIColor.darkText
        ]
        let h = drawString(text, in: CGRect(x: 36, y: y, width: pageRect.width - 72, height: 16), attrs: attrs)
        y += h + 4
    }

    private static func drawKeyValue(_ key: String, _ value: String, at y: inout CGFloat) {
        let keyAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 10, weight: .semibold), .foregroundColor: UIColor.darkText]
        let valueAttrs: [NSAttributedString.Key: Any] = [.font: UIFont.systemFont(ofSize: 10), .foregroundColor: UIColor.black]
        let keyRect = CGRect(x: 36, y: y, width: 160, height: 14)
        let valueRect = CGRect(x: 200, y: y, width: pageRect.width - 200 - 36, height: 14)
        drawString(key, in: keyRect, attrs: keyAttrs)
        let h = drawString(value, in: valueRect, attrs: valueAttrs)
        y += max(h, 14) + 2
    }

    private static func drawParagraph(_ text: String, at y: inout CGFloat) {
        let attrs: [NSAttributedString.Key: Any] = [
            .font: UIFont.systemFont(ofSize: 10),
            .foregroundColor: UIColor.black
        ]
        let h = drawString(text, in: CGRect(x: 36, y: y, width: pageRect.width - 72, height: .greatestFiniteMagnitude), attrs: attrs)
        y += h + 4
    }

    private static func drawRule(at y: inout CGFloat) {
        let ctx = UIGraphicsGetCurrentContext()
        ctx?.setStrokeColor(UIColor.lightGray.cgColor)
        ctx?.setLineWidth(0.5)
        ctx?.move(to: CGPoint(x: 36, y: y + 2))
        ctx?.addLine(to: CGPoint(x: pageRect.width - 36, y: y + 2))
        ctx?.strokePath()
        y += 8
    }

    // MARK: File output

    private static func writePDF(data: Data, filename: String) throws -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("ScholarKeepExports", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent(filename)
        try data.write(to: url, options: .atomic)
        return url
    }

    private static func sanitize(_ s: String) -> String {
        s.replacingOccurrences(of: "/", with: "-")
         .replacingOccurrences(of: ":", with: "-")
         .replacingOccurrences(of: "  ", with: " ")
    }
}

private extension Date {
    func iso8601Day() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd"
        return f.string(from: self)
    }
}
