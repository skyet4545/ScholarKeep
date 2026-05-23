import SwiftUI
import SwiftData
import PhotosUI
import UniformTypeIdentifiers
import UIKit

struct ExpenseDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var expense: Expense

    @State private var showAddProof = false
    @State private var showAddToClaim = false

    var body: some View {
        Form {
            headerSection
            eligibilitySection
            checklistSection
            attachmentsSection
            lineItemsSection
            claimSection
            metaSection
        }
        .navigationTitle(expense.vendorName.isEmpty ? "Expense" : expense.vendorName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { recheckEligibility() } label: { Label("Re-check eligibility", systemImage: "arrow.clockwise") }
                    if expense.claim == nil {
                        Button { showAddToClaim = true } label: { Label("Add to a claim", systemImage: "tray.and.arrow.up") }
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showAddToClaim) {
            AddToClaimSheet(expense: expense)
        }
    }

    private var headerSection: some View {
        Section("Receipt") {
            LabeledContent("Vendor", value: expense.vendorName.isEmpty ? "—" : expense.vendorName)
            LabeledContent("Date", value: expense.purchaseDate.formatted(date: .abbreviated, time: .omitted))
            LabeledContent("Total", value: expense.total.formatted(.currency(code: expense.currency)))
            LabeledContent("Subtotal", value: expense.subtotal.formatted(.currency(code: expense.currency)))
            LabeledContent("Tax", value: expense.tax.formatted(.currency(code: expense.currency)))
            if expense.shipping > 0 {
                LabeledContent("Shipping", value: expense.shipping.formatted(.currency(code: expense.currency)))
            }
            LabeledContent("Path", value: expense.acquisitionPath.displayName)
            LabeledContent("Payment", value: expense.paymentMethod.displayName)
        }
    }

    @ViewBuilder
    private var eligibilitySection: some View {
        Section("Eligibility") {
            if let status = expense.eligibilityResult {
                let reasons = expense.eligibilityReason
                    .split(separator: ".")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) + "." }
                    .filter { $0.count > 1 }
                let result = EligibilityResult(
                    status: status,
                    reasons: reasons,
                    matchedRuleKeys: expense.matchedRuleKeys,
                    requiresPreAuth: expense.requiresPreAuth,
                    requiresStudentName: false,
                    requiresProviderCredentials: false,
                    requiresEducationalBenefitForm: false,
                    citations: []
                )
                EligibilityBadgeView(result: result)
                if let v = expense.rulesetVersion {
                    Text("Ruleset \(v)").font(.caption2).foregroundStyle(.secondary)
                }
            } else {
                Text("No eligibility check yet.")
                Button("Run check now") { recheckEligibility() }
            }
            if expense.requiresPreAuth {
                TextField("Pre-authorization #", text: bindOptionalString(\.preAuthNumber))
            }
        }
    }

    @ViewBuilder
    private var checklistSection: some View {
        Section {
            CheckToggle(title: "Itemized receipt with line items and price breakdown",
                        binding: checklistBinding(\.itemizedReceipt))
            CheckToggle(title: "Proof of payment attached (separate from receipt)",
                        binding: checklistBinding(\.proofOfPayment))
            CheckToggle(title: "Student name on receipt (where required)",
                        binding: checklistBinding(\.studentNamePresent))
            if checklist.providerCredentials != nil {
                CheckToggle(title: "Provider license # + dates of service",
                            binding: optionalChecklistBinding(\.providerCredentials))
            }
            if checklist.educationalBenefitForm != nil {
                CheckToggle(title: "Educational Benefit Form attached",
                            binding: optionalChecklistBinding(\.educationalBenefitForm))
            }
            if checklist.preAuthIfRequired != nil {
                CheckToggle(title: "Pre-authorization number on file",
                            binding: optionalChecklistBinding(\.preAuthIfRequired))
            }
            CheckToggle(title: "No handwritten alterations",
                        binding: checklistBinding(\.noHandwrittenAlterations))
            ProgressView(value: Double(checklist.checkedCount),
                         total: Double(max(checklist.totalApplicable, 1)))
                .padding(.top, 4)
        } header: {
            Text("Documentation readiness")
        } footer: {
            Text(checklist.isComplete
                 ? "All required documentation is in place. You can mark this Ready to Submit from the claim screen."
                 : "Complete every applicable item before marking the claim Ready to Submit.")
        }
    }

    private var attachmentsSection: some View {
        Section("Attachments (\(expense.attachments.count))") {
            ForEach(expense.attachments) { attachment in
                AttachmentRow(attachment: attachment)
            }
            .onDelete { offsets in
                for index in offsets { modelContext.delete(expense.attachments[index]) }
                try? modelContext.save()
            }
            Button {
                showAddProof = true
            } label: {
                Label("Add proof of payment", systemImage: "doc.badge.plus")
            }
            .sheet(isPresented: $showAddProof) {
                ProofOfPaymentPickerSheet { data, mime, type in
                    let attachment = Attachment(type: type, mimeType: mime, fileData: data)
                    expense.attachments.append(attachment)
                    var cl = expense.readinessChecklist
                    if type == .proofOfPayment { cl.proofOfPayment = true }
                    if type == .educationalBenefitForm { cl.educationalBenefitForm = true }
                    expense.readinessChecklist = cl
                    try? modelContext.save()
                }
            }
        }
    }

    private var lineItemsSection: some View {
        Section("Line items (\(expense.lineItems.count))") {
            if expense.lineItems.isEmpty {
                Text("No line items extracted.").foregroundStyle(.secondary)
            } else {
                ForEach(expense.lineItems) { item in
                    HStack {
                        Text(item.descriptionText)
                        Spacer()
                        Text(item.amount.formatted(.currency(code: expense.currency)))
                            .monospacedDigit()
                    }
                }
            }
        }
    }

    private var claimSection: some View {
        Section("Claim") {
            if let claim = expense.claim {
                NavigationLink {
                    ClaimDetailView(claim: claim)
                } label: {
                    HStack {
                        Image(systemName: claim.status.systemImageName)
                            .foregroundStyle(.tint)
                        VStack(alignment: .leading) {
                            Text(claim.title).font(.headline)
                            Text(claim.status.displayName).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
            } else {
                Button("Create / add to claim") { showAddToClaim = true }
            }
        }
    }

    private var metaSection: some View {
        Section("Notes") {
            TextField("Notes", text: $expense.notes, axis: .vertical).lineLimit(2...5)
            TextField("Educational benefit", text: $expense.educationalBenefitNote, axis: .vertical).lineLimit(2...4)
        }
    }

    // MARK: helpers

    private var checklist: ReadinessChecklist { expense.readinessChecklist }

    private func checklistBinding(_ keyPath: WritableKeyPath<ReadinessChecklist, Bool>) -> Binding<Bool> {
        Binding(
            get: { expense.readinessChecklist[keyPath: keyPath] },
            set: { newValue in
                var cl = expense.readinessChecklist
                cl[keyPath: keyPath] = newValue
                expense.readinessChecklist = cl
                try? modelContext.save()
            }
        )
    }

    private func optionalChecklistBinding(_ keyPath: WritableKeyPath<ReadinessChecklist, Bool?>) -> Binding<Bool> {
        Binding(
            get: { expense.readinessChecklist[keyPath: keyPath] ?? false },
            set: { newValue in
                var cl = expense.readinessChecklist
                cl[keyPath: keyPath] = newValue
                expense.readinessChecklist = cl
                try? modelContext.save()
            }
        )
    }

    private func recheckEligibility() {
        guard let engine = RulesetLoader.shared.engine, let student = expense.student else { return }
        let withinWindow = DeviceWindowChecker.studentHasRecentDevice(
            student: student,
            within: engine.ruleset.globalRules.deviceReplacementYears,
            asOf: expense.purchaseDate
        )
        let input = EligibilityInput(
            categoryKey: expense.categoryKey,
            descriptionText: ([expense.vendorName] + expense.lineItems.map { $0.descriptionText } + [expense.notes]).joined(separator: " "),
            amount: expense.total,
            program: student.program,
            acquisitionPath: expense.acquisitionPath,
            studentHasDeviceWithinWindow: withinWindow
        )
        let result = engine.evaluate(input: input)
        expense.eligibilityResult = result.status
        expense.eligibilityReason = result.reasons.joined(separator: " ")
        expense.matchedRuleKeys = result.matchedRuleKeys
        expense.requiresPreAuth = result.requiresPreAuth
        expense.eligibilityCheckedAt = .now
        expense.rulesetVersion = engine.ruleset.sourceVersion
        try? modelContext.save()
    }

    private func bindOptionalString(_ keyPath: ReferenceWritableKeyPath<Expense, String?>) -> Binding<String> {
        Binding(
            get: { expense[keyPath: keyPath] ?? "" },
            set: { expense[keyPath: keyPath] = $0.isEmpty ? nil : $0 }
        )
    }
}

private struct CheckToggle: View {
    let title: String
    let binding: Binding<Bool>

    var body: some View {
        Toggle(isOn: binding) {
            Text(title)
        }
    }
}

struct ProofOfPaymentPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    /// (data, mime, attachmentType)
    let onPicked: (Data, String, AttachmentType) -> Void

    @State private var photoItem: PhotosPickerItem?
    @State private var showDocPicker = false
    @State private var selectedType: AttachmentType = .proofOfPayment

    var body: some View {
        NavigationStack {
            Form {
                Picker("Attachment type", selection: $selectedType) {
                    Text(AttachmentType.proofOfPayment.displayName).tag(AttachmentType.proofOfPayment)
                    Text(AttachmentType.educationalBenefitForm.displayName).tag(AttachmentType.educationalBenefitForm)
                    Text(AttachmentType.credential.displayName).tag(AttachmentType.credential)
                    Text(AttachmentType.other.displayName).tag(AttachmentType.other)
                }
                Section {
                    PhotosPicker(selection: $photoItem, matching: .images) {
                        Label("From photo library", systemImage: "photo.on.rectangle")
                    }
                    Button {
                        showDocPicker = true
                    } label: {
                        Label("From files (PDF, image)", systemImage: "doc.badge.plus")
                    }
                }
            }
            .navigationTitle("Add attachment")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: photoItem) { _, newItem in
                guard let newItem else { return }
                Task {
                    if let data = try? await newItem.loadTransferable(type: Data.self) {
                        await MainActor.run {
                            onPicked(data, "image/jpeg", selectedType)
                            dismiss()
                        }
                    }
                }
            }
            .sheet(isPresented: $showDocPicker) {
                DocumentPicker { url in
                    if let data = try? Data(contentsOf: url) {
                        let mime = url.pathExtension.lowercased() == "pdf" ? "application/pdf" : "image/jpeg"
                        onPicked(data, mime, selectedType)
                        dismiss()
                    }
                }
            }
        }
    }
}

struct DocumentPicker: UIViewControllerRepresentable {
    let onPicked: (URL) -> Void

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let vc = UIDocumentPickerViewController(forOpeningContentTypes: [.pdf, .image])
        vc.allowsMultipleSelection = false
        vc.delegate = context.coordinator
        return vc
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(onPicked: onPicked) }

    final class Coordinator: NSObject, UIDocumentPickerDelegate {
        let onPicked: (URL) -> Void
        init(onPicked: @escaping (URL) -> Void) { self.onPicked = onPicked }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            guard let url = urls.first else { return }
            let needsAccess = url.startAccessingSecurityScopedResource()
            defer { if needsAccess { url.stopAccessingSecurityScopedResource() } }
            onPicked(url)
        }
    }
}

private struct AttachmentRow: View {
    let attachment: Attachment

    var body: some View {
        HStack {
            Image(systemName: iconName)
                .foregroundStyle(.tint)
            VStack(alignment: .leading) {
                Text(attachment.type.displayName).font(.subheadline)
                Text(attachment.createdAt.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption2).foregroundStyle(.secondary)
            }
            Spacer()
            if let data = attachment.fileData, attachment.mimeType.hasPrefix("image"),
               let image = UIImage(data: data) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 4))
            }
        }
    }

    private var iconName: String {
        switch attachment.type {
        case .receipt:                return "doc.text"
        case .proofOfPayment:         return "creditcard"
        case .educationalBenefitForm: return "doc.badge.gearshape"
        case .credential:             return "person.text.rectangle"
        case .other:                  return "paperclip"
        }
    }
}
