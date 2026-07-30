import SwiftUI
import SwiftData
import UIKit

/// Sheet presented when the main app launches and finds items in the
/// Share Extension's App Group inbox. The user reviews each one, picks the
/// student, and saves it as an Expense. Or dismisses to keep it pending.
struct SharedInboxImportSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings
    @Query(sort: \Student.createdAt) private var students: [Student]

    let pending: [ShareInbox.PendingShare]

    @State private var index = 0
    @State private var selectedStudentID: UUID?
    @State private var parsedReceipt: ParsedReceipt?
    @State private var parsedOCRText = ""
    @State private var isReadingReceipt = false
    @State private var readError: String?

    private var current: ShareInbox.PendingShare? {
        guard index < pending.count else { return nil }
        return pending[index]
    }

    private var activeStudent: Student? {
        if let id = selectedStudentID { return students.first { $0.id == id } }
        if let id = settings.activeStudentID { return students.first { $0.id == id } }
        return students.first
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DS.canvas.ignoresSafeArea()
                if let share = current {
                    importContent(for: share)
                } else {
                    allDoneView
                }
            }
            .navigationTitle(current != nil ? "Review (\(index + 1) of \(pending.count))" : "All caught up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Done") { dismiss() }
                }
            }
            .onAppear {
                if selectedStudentID == nil {
                    selectedStudentID = settings.activeStudentID ?? students.first?.id
                }
            }
            .task(id: current?.id) {
                await readCurrentShare()
            }
        }
    }

    // MARK: Per-item view

    private func importContent(for share: ShareInbox.PendingShare) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.lg) {
                VStack(alignment: .leading, spacing: DS.sm) {
                    Text("FROM SHARE SHEET")
                        .font(.footnote.weight(.semibold))
                        .foregroundStyle(.secondary)
                        .tracking(0.5)
                        .padding(.horizontal, DS.lg + 4)
                    contentPreview(for: share)
                }

                if students.count > 1 {
                    studentPicker
                }

                receiptDetectionCard

                VStack(spacing: DS.sm) {
                    JournalCTA("Save to ScholarKeep", symbol: "tray.and.arrow.down.fill") {
                        saveAsExpense(share)
                    }
                    .padding(.horizontal, DS.lg)

                    Button(role: .destructive) {
                        skip(share)
                    } label: {
                        Text("Discard")
                            .font(.subheadline.weight(.semibold))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                    }
                    .padding(.horizontal, DS.lg)
                }
                .padding(.top, DS.lg)
            }
            .padding(.vertical, DS.lg)
        }
    }

    @ViewBuilder
    private func contentPreview(for share: ShareInbox.PendingShare) -> some View {
        VStack(alignment: .leading, spacing: DS.md) {
            if let attachmentURL = ShareInbox.attachmentURL(for: share),
               attachmentURL.pathExtension.lowercased() != "pdf",
               let image = UIImage(contentsOfFile: attachmentURL.path) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 280)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else if let attachmentURL = ShareInbox.attachmentURL(for: share),
                      attachmentURL.pathExtension.lowercased() == "pdf" {
                HStack(spacing: DS.md) {
                    Image(systemName: "doc.fill")
                        .font(.title.weight(.semibold))
                        .foregroundStyle(DS.accent)
                        .frame(width: 44, height: 44)
                        .background(DS.accentSoft, in: RoundedRectangle(cornerRadius: 10))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("PDF document")
                            .font(.subheadline.weight(.semibold))
                        Text(share.attachmentFilename ?? "")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                    Spacer()
                }
            }
            if let url = share.sourceURL {
                Label(url.host ?? url.absoluteString, systemImage: "link")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            if let text = share.text, !text.isEmpty {
                Text(text)
                    .font(.callout)
                    .foregroundStyle(.primary)
                    .lineLimit(20)
            }
            Text("Saved \(share.createdAt.formatted(date: .abbreviated, time: .shortened))")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding(DS.lg)
        .background(DS.grouped, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
        .padding(.horizontal, DS.lg)
    }

    @ViewBuilder
    private var receiptDetectionCard: some View {
        VStack(alignment: .leading, spacing: DS.sm) {
            Text("RECEIPT DETAILS")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(0.5)
            if isReadingReceipt {
                HStack(spacing: DS.sm) {
                    ProgressView()
                    Text("Reading receipt on this device…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else if let parsedReceipt {
                VStack(alignment: .leading, spacing: 6) {
                    if !parsedReceipt.vendorName.isEmpty {
                        LabeledContent("Vendor", value: parsedReceipt.vendorName)
                    }
                    if let date = parsedReceipt.purchaseDate {
                        LabeledContent("Purchase date", value: date.formatted(date: .abbreviated, time: .omitted))
                    }
                    if let total = parsedReceipt.total {
                        LabeledContent("Total", value: total.formatted(.currency(code: "USD")))
                    }
                    if !parsedReceipt.lineItems.isEmpty {
                        LabeledContent("Line items", value: "\(parsedReceipt.lineItems.count)")
                    }
                }
                .font(.subheadline)
            } else if let readError {
                Label(readError, systemImage: "exclamationmark.triangle")
                    .font(.footnote)
                    .foregroundStyle(DS.statusWarn)
            } else {
                Text("ScholarKeep will preserve this item for manual review.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(DS.lg)
        .background(DS.grouped, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .padding(.horizontal, DS.lg)
    }

    private var studentPicker: some View {
        VStack(alignment: .leading, spacing: DS.sm) {
            Text("FOR")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(0.5)
                .padding(.horizontal, DS.lg + 4)
            VStack(spacing: 0) {
                ForEach(students) { s in
                    Button {
                        selectedStudentID = s.id
                    } label: {
                        HStack(spacing: DS.md) {
                            Text(String(s.displayName.prefix(1)).uppercased())
                                .font(.footnote.weight(.bold))
                                .foregroundStyle(DS.accent)
                                .frame(width: 28, height: 28)
                                .background(DS.accentSoft, in: RoundedRectangle(cornerRadius: 8))
                            VStack(alignment: .leading, spacing: 1) {
                                Text(s.displayName).font(.subheadline)
                                Text(s.program.shortName).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if selectedStudentID == s.id {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(DS.accent)
                            }
                        }
                        .padding(.horizontal, DS.base)
                        .padding(.vertical, DS.md)
                    }
                    .buttonStyle(.plain)
                    if s.id != students.last?.id {
                        Divider().padding(.leading, 56)
                    }
                }
            }
            .background(DS.grouped, in: RoundedRectangle(cornerRadius: DS.cardRadius))
            .padding(.horizontal, DS.lg)
        }
    }

    // MARK: All done

    private var allDoneView: some View {
        VStack(spacing: DS.lg) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(DS.statusGood)
            Text("All caught up")
                .font(.title3.weight(.semibold))
            Text("Every shared receipt has been reviewed.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button("Done") { dismiss() }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .padding(.top, DS.sm)
        }
        .padding()
    }

    // MARK: Actions

    private func saveAsExpense(_ share: ShareInbox.PendingShare) {
        guard let student = activeStudent else {
            skip(share)
            return
        }

        let summary = (share.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        let firstLine = summary.split(separator: "\n").first.map(String.init) ?? "Shared receipt"
        let detectedVendor = parsedReceipt?.vendorName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let vendor = detectedVendor.isEmpty ? String(firstLine.prefix(80)) : detectedVendor

        let expense = Expense(
            vendorName: vendor.isEmpty ? "Shared receipt" : vendor,
            purchaseDate: parsedReceipt?.purchaseDate ?? share.createdAt,
            subtotal: parsedReceipt?.subtotal ?? 0,
            tax: parsedReceipt?.tax ?? 0,
            shipping: 0,
            total: parsedReceipt?.total ?? 0,
            currency: "USD",
            categoryKey: nil,
            subcategory: "",
            paymentMethod: .other,
            acquisitionPath: .reimbursement
        )
        expense.student = student
        if let url = share.sourceURL {
            expense.notes = "Imported from \(url.host ?? url.absoluteString)\n\n" + (share.text ?? "")
        } else if let text = share.text {
            expense.notes = text
        }

        modelContext.insert(expense)
        expense.lineItems = (parsedReceipt?.lineItems ?? []).map {
            LineItem(descriptionText: $0.descriptionText, unitPrice: $0.amount, amount: $0.amount)
        }
        var checklist = ReadinessChecklist()
        checklist.itemizedReceipt = !(parsedReceipt?.lineItems.isEmpty ?? true)
        checklist.noHandwrittenAlterations = true
        expense.readinessChecklist = checklist

        // Attach the image/PDF if any.
        if let attachmentURL = ShareInbox.attachmentURL(for: share),
           let data = try? Data(contentsOf: attachmentURL) {
            let mime = ReceiptDocumentReader.inferredMimeType(for: attachmentURL)
            let attachment = Attachment(
                type: .receipt,
                mimeType: mime,
                fileData: data,
                ocrText: parsedOCRText,
                expense: expense
            )
            expense.attachments = [attachment]
            modelContext.insert(attachment)
        }

        try? modelContext.save()
        ShareInbox.consume(share)
        advance()
    }

    private func skip(_ share: ShareInbox.PendingShare) {
        ShareInbox.consume(share)
        advance()
    }

    private func advance() {
        parsedReceipt = nil
        parsedOCRText = ""
        readError = nil
        if index < pending.count - 1 {
            index += 1
        } else {
            index = pending.count
        }
    }

    @MainActor
    private func readCurrentShare() async {
        guard let share = current else { return }
        parsedReceipt = nil
        parsedOCRText = ""
        readError = nil

        if let attachmentURL = ShareInbox.attachmentURL(for: share),
           let data = try? Data(contentsOf: attachmentURL) {
            isReadingReceipt = true
            defer { isReadingReceipt = false }
            do {
                let result = try await ReceiptDocumentReader.read(
                    data: data,
                    mimeType: ReceiptDocumentReader.inferredMimeType(for: attachmentURL)
                )
                guard current?.id == share.id else { return }
                parsedReceipt = result.parsed
                parsedOCRText = result.ocrText
            } catch {
                readError = "The file was saved, but its details could not be read automatically."
            }
            return
        }

        guard let text = share.text, !text.isEmpty else { return }
        let amounts = EmailReceiptDetector.inferredAmounts(from: text)
        var parsed = ParsedReceipt()
        parsed.vendorName = text.split(separator: "\n").first.map(String.init) ?? "Shared receipt"
        parsed.purchaseDate = EmailReceiptDetector.inferredDate(from: text)
        parsed.subtotal = amounts.subtotal
        parsed.tax = amounts.tax
        parsed.total = amounts.total
        parsed.rawText = text
        parsedReceipt = parsed
        parsedOCRText = text
    }
}
