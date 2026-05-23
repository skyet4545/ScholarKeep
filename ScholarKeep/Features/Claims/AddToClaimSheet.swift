import SwiftUI
import SwiftData

struct AddToClaimSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let expense: Expense

    @Query private var allClaims: [Claim]
    @State private var newClaimTitle: String = ""
    @State private var error: String?

    private var sameStudentClaims: [Claim] {
        guard let s = expense.student else { return [] }
        return allClaims.filter { $0.student?.id == s.id && $0.status == .draft }
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Create new claim") {
                    TextField("Claim title (e.g. ABC Tutoring — Apr 2026)", text: $newClaimTitle)
                    Button("Create and add") { createNewClaim() }
                        .disabled(newClaimTitle.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                if !sameStudentClaims.isEmpty {
                    Section("Add to existing draft claim") {
                        ForEach(sameStudentClaims) { claim in
                            Button {
                                addTo(claim: claim)
                            } label: {
                                VStack(alignment: .leading) {
                                    Text(claim.title).font(.headline)
                                    Text("\(claim.expenses.count) expense(s)")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
                if let error {
                    Section { Text(error).foregroundStyle(.red) }
                }
                Section {
                    Text("ESA rules require one provider/service per claim. The app warns if you add expenses from different vendors to the same claim.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Add to claim")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onAppear {
                if newClaimTitle.isEmpty {
                    newClaimTitle = expense.vendorName.isEmpty
                        ? "Reimbursement claim"
                        : "\(expense.vendorName) — \(expense.purchaseDate.formatted(.dateTime.month(.abbreviated).year()))"
                }
            }
        }
    }

    private func createNewClaim() {
        let claim = Claim(title: newClaimTitle, student: expense.student)
        modelContext.insert(claim)
        addTo(claim: claim)
    }

    private func addTo(claim: Claim) {
        let vendors = Set((claim.expenses + [expense]).map { $0.vendorName.lowercased() }.filter { !$0.isEmpty })
        let mixesVendors = vendors.count > 1

        expense.claim = claim
        if !claim.expenses.contains(where: { $0.id == expense.id }) {
            claim.expenses.append(expense)
        }
        if claim.statusEvents.isEmpty {
            let event = StatusEvent(status: .draft, date: .now, note: "Created from expense.", claim: claim)
            claim.statusEvents.append(event)
        }
        // If we mixed vendors, leave a status note on the claim so it's visible later.
        if mixesVendors {
            let warning = "Heads up: this claim now mixes vendors (\(vendors.joined(separator: ", "))). The portal requires one provider per claim — consider splitting."
            let event = StatusEvent(status: claim.status, date: .now, note: warning, claim: claim)
            claim.statusEvents.append(event)
        }
        do {
            try modelContext.save()
            dismiss()
        } catch {
            self.error = "Couldn't save: \(error.localizedDescription)"
        }
    }
}
