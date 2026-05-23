import SwiftUI
import SwiftData

struct ClaimDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var claim: Claim

    @State private var showAdvance = false
    @State private var advanceError: String?
    @State private var showExportSheet = false

    var body: some View {
        Form {
            statusSection
            expensesSection
            timelineSection
            payoutSection
            if claim.status == .onHold || claim.status == .denied {
                denialSection
            }
            metaSection
            if let advanceError {
                Section { Text(advanceError).foregroundStyle(.red) }
            }
        }
        .navigationTitle(claim.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button { showAdvance = true } label: { Label("Update status", systemImage: "arrow.triangle.swap") }
                    Button { showExportSheet = true } label: { Label("Export submission package", systemImage: "square.and.arrow.up") }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showAdvance) {
            AdvanceClaimSheet(claim: claim) { error in
                advanceError = error
            }
        }
        .sheet(isPresented: $showExportSheet) {
            ExportClaimSheet(claim: claim)
        }
    }

    private var statusSection: some View {
        Section {
            HStack(spacing: 12) {
                Image(systemName: claim.status.systemImageName)
                    .font(.title2)
                    .foregroundStyle(.tint)
                VStack(alignment: .leading, spacing: 2) {
                    Text(claim.status.displayName).font(.headline)
                    if let onHoldStarted = claim.onHoldStartedAt, claim.status == .onHold {
                        let due = Calendar.current.date(byAdding: .day, value: 30, to: onHoldStarted) ?? onHoldStarted
                        let days = Calendar.current.dateComponents([.day], from: .now, to: due).day ?? 0
                        Text(days >= 0
                             ? "On-hold clock: \(days) day(s) left to supply missing docs."
                             : "On-hold clock expired \(-days) day(s) ago.")
                            .font(.caption)
                            .foregroundStyle(days < 5 ? .red : .orange)
                    } else if let submitted = claim.submittedDate {
                        Text("Submitted \(submitted.formatted(date: .abbreviated, time: .omitted))")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            Button("Update status") { showAdvance = true }
        }
    }

    private var expensesSection: some View {
        Section("Expenses (\(claim.expenses.count))") {
            ForEach(claim.expenses) { expense in
                NavigationLink {
                    ExpenseDetailView(expense: expense)
                } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(expense.vendorName.isEmpty ? "—" : expense.vendorName).font(.subheadline)
                            HStack(spacing: 4) {
                                Text(expense.purchaseDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                if !expense.readinessChecklist.isComplete {
                                    Text("Checklist incomplete")
                                        .font(.caption2.bold())
                                        .padding(.horizontal, 5)
                                        .padding(.vertical, 1)
                                        .background(Color.orange.opacity(0.2), in: Capsule())
                                        .foregroundStyle(.orange)
                                }
                            }
                        }
                        Spacer()
                        Text(expense.total.formatted(.currency(code: expense.currency)))
                            .font(.subheadline.monospacedDigit())
                    }
                }
            }
            HStack {
                Text("Total")
                Spacer()
                Text(totalAmount.formatted(.currency(code: "USD")))
                    .bold()
                    .monospacedDigit()
            }
        }
    }

    private var timelineSection: some View {
        Section("Timeline") {
            if claim.statusEvents.isEmpty {
                Text("No status events yet.").foregroundStyle(.secondary)
            } else {
                ForEach(claim.statusEvents.sorted(by: { $0.date < $1.date })) { event in
                    HStack(alignment: .top, spacing: 10) {
                        Image(systemName: event.status.systemImageName)
                            .foregroundStyle(.tint)
                            .frame(width: 18)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(event.status.displayName).font(.subheadline.bold())
                            Text(event.date.formatted(date: .abbreviated, time: .shortened))
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                            if !event.note.isEmpty {
                                Text(event.note).font(.caption).foregroundStyle(.primary)
                            }
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
    }

    private var payoutSection: some View {
        Section("Reimbursement") {
            Picker("Method", selection: Binding(
                get: { claim.reimbursementMethod ?? .ach },
                set: { claim.reimbursementMethod = $0; try? modelContext.save() }
            )) {
                ForEach(ReimbursementMethod.allCases) { Text($0.displayName).tag($0) }
            }
            decimalField("Expected payout", binding: optionalDecimalBinding(\.expectedPayout))
            decimalField("Actual payout", binding: optionalDecimalBinding(\.actualPayout))
        }
    }

    @ViewBuilder
    private var denialSection: some View {
        Section("Reason + fix") {
            Picker("Reason", selection: Binding(
                get: { claim.denialReason ?? .other },
                set: { claim.denialReason = $0; applyDenialFix($0); try? modelContext.save() }
            )) {
                ForEach(DenialReason.allCases) { Text($0.displayName).tag($0) }
            }
            if let reason = claim.denialReason {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Suggested fix").font(.caption.bold()).foregroundStyle(.secondary)
                    Text(reason.suggestedFix).font(.callout)
                }
            }
            TextField("Notes from SFO / portal", text: $claim.denialNote, axis: .vertical)
                .lineLimit(2...5)
            if claim.status == .denied {
                TextField("Appeal notes", text: $claim.appealNote, axis: .vertical)
                    .lineLimit(2...5)
            }
        }
    }

    private var metaSection: some View {
        Section("Meta") {
            LabeledContent("Created", value: claim.createdAt.formatted(date: .abbreviated, time: .omitted))
            if let s = claim.submittedDate { LabeledContent("Submitted", value: s.formatted(date: .abbreviated, time: .omitted)) }
            if let d = claim.decisionDate { LabeledContent("Decision", value: d.formatted(date: .abbreviated, time: .omitted)) }
            if let p = claim.paidDate { LabeledContent("Paid", value: p.formatted(date: .abbreviated, time: .omitted)) }
            if let s = claim.student { LabeledContent("Student", value: s.displayName) }
        }
    }

    private var totalAmount: Decimal {
        claim.expenses.reduce(Decimal(0)) { $0 + $1.total }
    }

    private func decimalField(_ label: String, binding: Binding<String>) -> some View {
        HStack {
            Text(label)
            Spacer()
            TextField("0.00", text: binding)
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .frame(width: 120)
        }
    }

    private func optionalDecimalBinding(_ keyPath: ReferenceWritableKeyPath<Claim, Decimal?>) -> Binding<String> {
        Binding(
            get: {
                guard let v = claim[keyPath: keyPath] else { return "" }
                return NSDecimalNumber(decimal: v).stringValue
            },
            set: { newValue in
                let trimmed = newValue.trimmingCharacters(in: .whitespaces)
                claim[keyPath: keyPath] = trimmed.isEmpty ? nil : Decimal(string: trimmed)
                try? modelContext.save()
            }
        )
    }

    /// Mirror denial reasons onto the readiness checklist so the parent sees exactly what to fix.
    private func applyDenialFix(_ reason: DenialReason) {
        guard let field = reason.checklistKey else { return }
        for expense in claim.expenses {
            var cl = expense.readinessChecklist
            switch field {
            case .itemizedReceipt:           cl.itemizedReceipt = false
            case .proofOfPayment:            cl.proofOfPayment = false
            case .studentNamePresent:        cl.studentNamePresent = false
            case .providerCredentials:      cl.providerCredentials = false
            case .educationalBenefitForm:    cl.educationalBenefitForm = false
            case .preAuthIfRequired:         cl.preAuthIfRequired = false
            case .noHandwrittenAlterations:  cl.noHandwrittenAlterations = false
            }
            expense.readinessChecklist = cl
        }
    }
}

struct AdvanceClaimSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Bindable var claim: Claim
    var onError: (String?) -> Void

    @State private var selectedStatus: ClaimStatus
    @State private var note: String = ""
    @State private var date: Date = .now
    @State private var error: String?

    init(claim: Claim, onError: @escaping (String?) -> Void) {
        self.claim = claim
        self.onError = onError
        let allowed = ClaimStateMachine.allowedNextStates(from: claim.status)
        _selectedStatus = State(initialValue: allowed.first ?? claim.status)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Move to") {
                    Picker("New status", selection: $selectedStatus) {
                        ForEach(ClaimStateMachine.allowedNextStates(from: claim.status)) { status in
                            Text(status.displayName).tag(status)
                        }
                    }
                    DatePicker("When", selection: $date)
                    TextField("Note (optional)", text: $note, axis: .vertical).lineLimit(2...5)
                }
                if let error {
                    Section { Text(error).foregroundStyle(.red) }
                }
            }
            .navigationTitle("Update status")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        do {
                            _ = try ClaimStateMachine.transition(claim, to: selectedStatus, note: note, date: date)
                            try modelContext.save()
                            onError(nil)
                            dismiss()
                        } catch {
                            self.error = error.localizedDescription
                            onError(error.localizedDescription)
                        }
                    }
                }
            }
        }
    }
}

/// Placeholder until M5 export sheet is wired in fully.
struct ExportClaimSheet: View {
    @Environment(\.dismiss) private var dismiss
    let claim: Claim
    @State private var resultURL: URL?
    @State private var error: String?

    var body: some View {
        NavigationStack {
            Group {
                if let resultURL {
                    ShareLink(item: resultURL) {
                        Label("Share submission package PDF", systemImage: "square.and.arrow.up")
                    }
                    .padding()
                } else if let error {
                    Text(error).foregroundStyle(.red).padding()
                } else {
                    ProgressView("Generating…")
                }
            }
            .navigationTitle("Export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Done") { dismiss() } }
            }
            .task { generate() }
        }
    }

    private func generate() {
        do {
            let url = try PDFExportService.exportClaim(claim)
            self.resultURL = url
        } catch {
            self.error = "Couldn't generate PDF: \(error.localizedDescription)"
        }
    }
}
