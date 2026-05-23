import SwiftUI
import SwiftData

struct BalanceLedgerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings
    @Query(sort: \BalanceEntry.date, order: .reverse) private var allEntries: [BalanceEntry]
    @Query(sort: \Student.createdAt) private var students: [Student]

    @State private var showingAdd = false

    private var activeStudent: Student? {
        guard let id = settings.activeStudentID else { return students.first }
        return students.first { $0.id == id }
    }

    private var visibleEntries: [BalanceEntry] {
        guard let s = activeStudent else { return [] }
        return allEntries.filter { $0.student?.id == s.id }
    }

    private var summary: BalanceLedger.Summary {
        BalanceLedger.summarize(entries: visibleEntries.sorted(by: { $0.date < $1.date }))
    }

    var body: some View {
        NavigationStack {
            List {
                summarySection
                Section("Entries") {
                    ForEach(visibleEntries) { entry in
                        BalanceEntryRow(entry: entry)
                    }
                    .onDelete(perform: delete)
                }
            }
            .navigationTitle("Balance")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAdd = true } label: {
                        Label("Add entry", systemImage: "plus")
                    }
                    .disabled(activeStudent == nil)
                }
            }
            .sheet(isPresented: $showingAdd) {
                if let student = activeStudent {
                    NavigationStack {
                        BalanceEntryFormView(entry: nil, parentStudent: student)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var summarySection: some View {
        Section {
            if visibleEntries.isEmpty {
                ContentUnavailableView {
                    Label("Track your balance", systemImage: "dollarsign.circle")
                } description: {
                    Text("Add your initial award and each disbursement so the app can show what's actually available to spend vs. tied up in pending claims.")
                } actions: {
                    Button("Add initial award") { showingAdd = true }
                        .buttonStyle(.borderedProminent)
                }
            } else {
                LabeledContent("Available now") {
                    Text(summary.availableBalance.formatted(.currency(code: "USD")))
                        .font(.title3.bold().monospacedDigit())
                        .foregroundStyle(summary.availableBalance < 0 ? .red : .primary)
                }
                LabeledContent("Pending claims") {
                    Text(summary.pendingClaims.formatted(.currency(code: "USD")))
                        .monospacedDigit()
                        .foregroundStyle(.orange)
                }
                LabeledContent("Paid this year") {
                    Text(summary.paidClaims.formatted(.currency(code: "USD")))
                        .monospacedDigit()
                }
                LabeledContent("Total disbursed") {
                    Text(summary.totalDisbursed.formatted(.currency(code: "USD")))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets { modelContext.delete(visibleEntries[index]) }
        try? modelContext.save()
    }
}

private struct BalanceEntryRow: View {
    let entry: BalanceEntry

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(entry.type.displayName).font(.subheadline)
                HStack(spacing: 8) {
                    Text(entry.date.formatted(date: .abbreviated, time: .omitted))
                    if !entry.note.isEmpty {
                        Text("· \(entry.note)").lineLimit(1)
                    }
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
            Spacer()
            Text(entry.signedAmount.formatted(.currency(code: "USD")))
                .monospacedDigit()
                .foregroundStyle(entry.type.increasesBalance ? .green : .red)
        }
    }
}

struct BalanceEntryFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let editingEntry: BalanceEntry?
    let parentStudent: Student?

    @State private var type: BalanceEntryType = .disbursement
    @State private var amountText: String = ""
    @State private var date: Date = .now
    @State private var note: String = ""

    init(entry: BalanceEntry?, parentStudent: Student? = nil) {
        self.editingEntry = entry
        self.parentStudent = parentStudent ?? entry?.student
        if let e = entry {
            _type = State(initialValue: e.type)
            _amountText = State(initialValue: NSDecimalNumber(decimal: e.amount).stringValue)
            _date = State(initialValue: e.date)
            _note = State(initialValue: e.note)
        }
    }

    var body: some View {
        Form {
            Section {
                Picker("Type", selection: $type) {
                    ForEach(BalanceEntryType.allCases) { Text($0.displayName).tag($0) }
                }
                HStack {
                    Text("Amount")
                    Spacer()
                    TextField("0.00", text: $amountText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 140)
                }
                DatePicker("Date", selection: $date, displayedComponents: .date)
                TextField("Note (optional)", text: $note, axis: .vertical).lineLimit(2...4)
            } footer: {
                Text("Reconcile with what you see in EMA/SMP. ScholarKeep doesn't connect to the portal.")
            }
        }
        .navigationTitle(editingEntry == nil ? "New entry" : "Edit entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
                    .disabled(DecimalParsing.parse(amountText) == nil)
            }
            if editingEntry == nil {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() {
        let amount = DecimalParsing.parse(amountText) ?? 0
        if let existing = editingEntry {
            existing.type = type
            existing.amount = amount
            existing.date = date
            existing.note = note
        } else if let student = parentStudent {
            let entry = BalanceEntry(type: type, amount: amount, date: date, note: note, student: student)
            modelContext.insert(entry)
        }
        try? modelContext.save()
        dismiss()
    }
}
