import SwiftUI
import SwiftData
import UIKit

/// Post-scan review & confirm screen. Human-in-the-loop — never auto-commits.
struct ExpenseReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let scannedImages: [UIImage]
    let parsed: ParsedReceipt
    let rawOCRText: String
    let student: Student

    @State private var vendorName: String
    @State private var purchaseDate: Date
    @State private var subtotalText: String
    @State private var taxText: String
    @State private var shippingText: String = ""
    @State private var totalText: String
    @State private var paymentMethod: PaymentMethod = .card
    @State private var acquisitionPath: AcquisitionPath = .reimbursement
    @State private var notes: String = ""
    @State private var lineItemDrafts: [LineItemDraft]
    @State private var categoryKey: String? = nil
    @State private var saveError: String?

    @State private var liveEligibility: EligibilityResult?

    init(scannedImages: [UIImage], parsed: ParsedReceipt, rawOCRText: String, student: Student) {
        self.scannedImages = scannedImages
        self.parsed = parsed
        self.rawOCRText = rawOCRText
        self.student = student
        _vendorName = State(initialValue: parsed.vendorName)
        _purchaseDate = State(initialValue: parsed.purchaseDate ?? .now)
        _subtotalText = State(initialValue: parsed.subtotal?.editingString() ?? "")
        _taxText = State(initialValue: parsed.tax?.editingString() ?? "")
        _totalText = State(initialValue: parsed.total?.editingString() ?? "")
        _lineItemDrafts = State(initialValue: parsed.lineItems.map { LineItemDraft(description: $0.descriptionText, amount: $0.amount.editingString()) })
    }

    var body: some View {
        NavigationStack {
            Form {
                eligibilitySection
                receiptSection
                amountsSection
                categorySection
                lineItemsSection
                notesSection
                if let saveError {
                    Section { Text(saveError).foregroundStyle(.red) }
                }
            }
            .navigationTitle(scannedImages.isEmpty ? "New expense" : "Review receipt")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(vendorName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .task(id: categoryKey) { recomputeEligibility() }
            .onChange(of: acquisitionPath) { _, _ in recomputeEligibility() }
            .onChange(of: totalText) { _, _ in recomputeEligibility() }
            .onAppear { recomputeEligibility() }
        }
    }

    private var eligibilitySection: some View {
        Section {
            if let result = liveEligibility {
                EligibilityBadgeView(result: result)
            } else {
                ProgressView("Checking eligibility…").frame(maxWidth: .infinity, alignment: .center)
            }
        } header: {
            Text("Eligibility")
        } footer: {
            Text("Estimate based on the bundled ruleset. Always confirm against the official Purchasing Guide before submitting.")
        }
    }

    private var receiptSection: some View {
        Section("Receipt") {
            TextField("Vendor / provider", text: $vendorName)
            DatePicker("Purchase date", selection: $purchaseDate, displayedComponents: .date)
            Picker("Payment", selection: $paymentMethod) {
                ForEach(PaymentMethod.allCases) { Text($0.displayName).tag($0) }
            }
            Picker("How paid", selection: $acquisitionPath) {
                ForEach(AcquisitionPath.allCases) { Text($0.displayName).tag($0) }
            }
        }
    }

    private var amountsSection: some View {
        Section("Amounts") {
            decimalField("Subtotal", text: $subtotalText)
            decimalField("Tax", text: $taxText)
            decimalField("Shipping", text: $shippingText)
            decimalField("Total", text: $totalText)
        }
    }

    private var categorySection: some View {
        Section("Category") {
            CategoryPickerView(selection: $categoryKey, student: student)
        }
    }

    private var lineItemsSection: some View {
        Section("Line items") {
            if lineItemDrafts.isEmpty {
                Button {
                    lineItemDrafts.append(LineItemDraft())
                } label: {
                    Label("Add line item", systemImage: "plus")
                }
            } else {
                ForEach($lineItemDrafts) { $draft in
                    HStack {
                        TextField("Description", text: $draft.description)
                        TextField("0.00", text: $draft.amount)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 90)
                    }
                }
                .onDelete { offsets in
                    lineItemDrafts.remove(atOffsets: offsets)
                }
                Button { lineItemDrafts.append(LineItemDraft()) } label: {
                    Label("Add line item", systemImage: "plus")
                }
            }
        }
    }

    private var notesSection: some View {
        Section("Notes") {
            TextField("Educational benefit, context…", text: $notes, axis: .vertical)
                .lineLimit(2...5)
        }
    }

    private func decimalField(_ label: String, text: Binding<String>) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0.00", text: text)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 120)
        }
    }

    private func recomputeEligibility() {
        guard let engine = RulesetLoader.shared.engine else {
            liveEligibility = nil
            return
        }
        let total = (DecimalParsing.parse(totalText) ?? 0)
        let withinDeviceWindow = DeviceWindowChecker.studentHasRecentDevice(
            student: student,
            within: engine.ruleset.globalRules.deviceReplacementYears,
            asOf: purchaseDate
        )
        let input = EligibilityInput(
            categoryKey: categoryKey,
            descriptionText: ([vendorName] + lineItemDrafts.map { $0.description } + [notes]).joined(separator: " "),
            amount: total,
            program: student.program,
            acquisitionPath: acquisitionPath,
            studentHasDeviceWithinWindow: withinDeviceWindow
        )
        liveEligibility = engine.evaluate(input: input)
    }

    private func save() {
        let total = (DecimalParsing.parse(totalText) ?? 0)
        let subtotal = DecimalParsing.parse(subtotalText) ?? 0
        let tax = DecimalParsing.parse(taxText) ?? 0
        let shipping = DecimalParsing.parse(shippingText) ?? 0

        // Build expense (Draft).
        let expense = Expense(
            vendorName: vendorName.trimmingCharacters(in: .whitespaces),
            purchaseDate: purchaseDate,
            subtotal: subtotal,
            tax: tax,
            shipping: shipping,
            total: total,
            categoryKey: categoryKey,
            paymentMethod: paymentMethod,
            acquisitionPath: acquisitionPath,
            eligibilityResult: liveEligibility?.status,
            eligibilityReason: liveEligibility?.reasons.joined(separator: " ") ?? "",
            eligibilityReasonsList: liveEligibility?.reasons ?? [],
            matchedRuleKeys: liveEligibility?.matchedRuleKeys ?? [],
            eligibilityCheckedAt: .now,
            rulesetVersion: RulesetLoader.shared.engine?.ruleset.sourceVersion,
            requiresPreAuth: liveEligibility?.requiresPreAuth ?? false,
            notes: notes,
            student: student
        )
        // Initialize the readiness checklist with what we know.
        var checklist = ReadinessChecklist()
        checklist.itemizedReceipt = !lineItemDrafts.isEmpty
        checklist.studentNamePresent = false // parent confirms
        checklist.noHandwrittenAlterations = true
        if liveEligibility?.requiresProviderCredentials == true {
            checklist.providerCredentials = false
        }
        if liveEligibility?.requiresEducationalBenefitForm == true {
            checklist.educationalBenefitForm = false
        }
        if liveEligibility?.requiresPreAuth == true {
            checklist.preAuthIfRequired = false
        }
        expense.readinessChecklist = checklist

        // Attach all scanned page images as receipt attachments.
        for (idx, image) in scannedImages.enumerated() {
            if let data = image.jpegData(compressionQuality: 0.85) {
                let attachment = Attachment(
                    type: .receipt,
                    mimeType: "image/jpeg",
                    fileData: data,
                    ocrText: idx == 0 ? rawOCRText : ""
                )
                expense.attachments.append(attachment)
            }
        }

        // Line items.
        for draft in lineItemDrafts {
            let amount = DecimalParsing.parse(draft.amount) ?? 0
            guard !draft.description.trimmingCharacters(in: .whitespaces).isEmpty else { continue }
            expense.lineItems.append(LineItem(descriptionText: draft.description, unitPrice: amount, amount: amount))
        }

        modelContext.insert(expense)

        // Record device purchase if this is a device category.
        if categoryKey == "device" {
            let dp = DevicePurchase(
                deviceType: lineItemDrafts.first?.description ?? vendorName,
                purchaseDate: purchaseDate,
                amount: total,
                student: student,
                expense: expense
            )
            modelContext.insert(dp)
        }

        do {
            try modelContext.save()
            dismiss()
        } catch {
            saveError = "Couldn't save: \(error.localizedDescription)"
        }
    }
}

struct LineItemDraft: Identifiable {
    let id = UUID()
    var description: String = ""
    var amount: String = ""
}

private extension Decimal {
    func editingString() -> String {
        let n = NSDecimalNumber(decimal: self)
        let formatter = NumberFormatter()
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.usesGroupingSeparator = false
        return formatter.string(from: n) ?? ""
    }
}
