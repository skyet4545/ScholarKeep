import SwiftData
import SwiftUI
import UIKit

struct ReceiptCandidateReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Student.createdAt) private var students: [Student]

    @Bindable var candidate: ReceiptCandidate

    @State private var selectedStudentID: UUID?
    @State private var vendorName: String = ""
    @State private var purchaseDate: Date = .now
    @State private var subtotalText: String = ""
    @State private var taxText: String = ""
    @State private var totalText: String = ""
    @State private var categoryKey: String?
    @State private var saveError: String?

    private var selectedStudent: Student? {
        guard let selectedStudentID else { return students.first }
        return students.first { $0.id == selectedStudentID }
    }

    var body: some View {
        Form {
            sourceSection
            if !students.isEmpty {
                Section("Student") {
                    Picker("For", selection: $selectedStudentID) {
                        ForEach(students) { student in
                            Text(student.displayName).tag(Optional(student.id))
                        }
                    }
                }
            }
            Section("Receipt") {
                TextField("Vendor / provider", text: $vendorName)
                DatePicker("Purchase date", selection: $purchaseDate, displayedComponents: .date)
                decimalField("Subtotal", text: $subtotalText)
                decimalField("Tax", text: $taxText)
                decimalField("Total", text: $totalText)
            }
            if let student = selectedStudent {
                Section("Category") {
                    CategoryPickerView(selection: $categoryKey, student: student)
                }
            }
            if !candidate.detectionReasons.isEmpty {
                Section("Why ScholarKeep found it") {
                    ForEach(candidate.detectionReasons, id: \.self) { reason in
                        Label(reason, systemImage: "checkmark.circle")
                    }
                }
            }
            if let saveError {
                Section { Text(saveError).foregroundStyle(.red) }
            }
            if candidate.status == .pending {
                Section {
                    Button {
                        saveExpense()
                    } label: {
                        Label("Save as draft expense", systemImage: "tray.and.arrow.down.fill")
                    }
                    .disabled(selectedStudent == nil || vendorName.trimmingCharacters(in: .whitespaces).isEmpty)

                    Button(role: .destructive) {
                        candidate.status = .dismissed
                        try? modelContext.save()
                        dismiss()
                    } label: {
                        Text("Not a receipt")
                    }
                }
            }
        }
        .navigationTitle("Review Receipt")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: loadSuggestedValues)
    }

    @ViewBuilder
    private var sourceSection: some View {
        Section {
            VStack(alignment: .leading, spacing: DS.sm) {
                Label(candidate.subject, systemImage: "envelope.fill")
                    .font(.headline)
                Text(candidate.sender)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Text(candidate.receivedAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.tertiary)
                if !candidate.snippet.isEmpty {
                    Text(candidate.snippet)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .lineLimit(5)
                }
            }
            if let data = candidate.attachmentData,
               let mime = candidate.attachmentMimeType {
                if mime.hasPrefix("image/"), let image = UIImage(data: data) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxHeight: 260)
                } else {
                    Label(candidate.attachmentFilename ?? "PDF receipt", systemImage: "doc.fill")
                }
            } else {
                Label("No image or PDF was attached", systemImage: "exclamationmark.triangle")
                    .font(.footnote)
                    .foregroundStyle(DS.statusWarn)
            }
        } header: {
            Text("Source")
        } footer: {
            Text("Review the original evidence before submitting it to your scholarship organization.")
        }
    }

    private func decimalField(_ label: String, text: Binding<String>) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0.00", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 110)
        }
    }

    private func loadSuggestedValues() {
        guard vendorName.isEmpty else { return }
        selectedStudentID = students.first?.id
        vendorName = candidate.suggestedVendor
        purchaseDate = candidate.suggestedPurchaseDate ?? candidate.receivedAt
        subtotalText = candidate.suggestedSubtotal?.editingText ?? ""
        taxText = candidate.suggestedTax?.editingText ?? ""
        totalText = candidate.suggestedTotal?.editingText ?? ""
    }

    private func saveExpense() {
        guard let student = selectedStudent else { return }
        let lineItems = candidate.suggestedLineItems
        let expense = Expense(
            vendorName: vendorName.trimmingCharacters(in: .whitespacesAndNewlines),
            purchaseDate: purchaseDate,
            subtotal: DecimalParsing.parse(subtotalText) ?? 0,
            tax: DecimalParsing.parse(taxText) ?? 0,
            total: DecimalParsing.parse(totalText) ?? 0,
            categoryKey: categoryKey,
            paymentMethod: .other,
            acquisitionPath: .reimbursement,
            notes: emailSourceNote,
            student: student
        )
        expense.lineItems = lineItems.map {
            LineItem(descriptionText: $0.descriptionText, unitPrice: $0.amount, amount: $0.amount)
        }
        var checklist = ReadinessChecklist()
        checklist.itemizedReceipt = !lineItems.isEmpty
        checklist.noHandwrittenAlterations = true
        expense.readinessChecklist = checklist

        if let data = candidate.attachmentData {
            let attachment = Attachment(
                type: .receipt,
                mimeType: candidate.attachmentMimeType ?? "application/octet-stream",
                fileData: data,
                ocrText: candidate.ocrText,
                expense: expense
            )
            expense.attachments = [attachment]
        }

        modelContext.insert(expense)
        candidate.status = .imported
        candidate.importedExpenseID = expense.id
        do {
            try modelContext.save()
            dismiss()
        } catch {
            saveError = "Couldn't save this receipt: \(error.localizedDescription)"
        }
    }

    private var emailSourceNote: String {
        var parts = [
            "Imported from Gmail",
            "From: \(candidate.sender)",
            "Subject: \(candidate.subject)",
            "Received: \(candidate.receivedAt.formatted(date: .numeric, time: .shortened))"
        ]
        if !candidate.bodyText.isEmpty {
            parts.append("")
            parts.append(String(candidate.bodyText.prefix(4_000)))
        }
        return parts.joined(separator: "\n")
    }
}

private extension Decimal {
    var editingText: String {
        NSDecimalNumber(decimal: self).stringValue
    }
}
