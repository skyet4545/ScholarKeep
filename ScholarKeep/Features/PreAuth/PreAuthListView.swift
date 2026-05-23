import SwiftUI
import SwiftData

struct PreAuthListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings
    @Query(sort: \PreAuthorization.createdAt, order: .reverse) private var allPreAuths: [PreAuthorization]
    @Query(sort: \Student.createdAt) private var students: [Student]

    @State private var showingAdd = false

    private var activeStudent: Student? {
        guard let id = settings.activeStudentID else { return students.first }
        return students.first { $0.id == id }
    }

    private var visiblePreAuths: [PreAuthorization] {
        guard let s = activeStudent else { return [] }
        return allPreAuths.filter { $0.student?.id == s.id }
    }

    var body: some View {
        NavigationStack {
            List {
                if !visiblePreAuths.isEmpty {
                    Section {
                        Text("Pre-authorization deadline this year: May 29")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                ForEach(visiblePreAuths) { preAuth in
                    NavigationLink {
                        PreAuthFormView(preAuth: preAuth)
                    } label: {
                        PreAuthRow(preAuth: preAuth)
                    }
                }
                .onDelete(perform: delete)
            }
            .overlay {
                if visiblePreAuths.isEmpty {
                    ContentUnavailableView {
                        Label("No pre-authorizations yet", systemImage: "checkmark.shield")
                    } description: {
                        Text("Track pre-auth requests for theme park admissions, devices within the 2-year window, items not enumerated in the Purchasing Guide, and out-of-state activities.")
                    } actions: {
                        Button("New pre-auth request") { showingAdd = true }
                            .buttonStyle(.borderedProminent)
                            .disabled(activeStudent == nil)
                    }
                }
            }
            .navigationTitle("Pre-auth")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAdd = true } label: {
                        Label("New pre-auth", systemImage: "plus")
                    }
                    .disabled(activeStudent == nil)
                }
            }
            .sheet(isPresented: $showingAdd) {
                if let student = activeStudent {
                    NavigationStack {
                        PreAuthFormView(preAuth: nil, parentStudent: student)
                    }
                }
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets { modelContext.delete(visiblePreAuths[index]) }
        try? modelContext.save()
    }
}

private struct PreAuthRow: View {
    let preAuth: PreAuthorization

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: preAuth.status.systemImageName)
                    .foregroundStyle(tint)
                Text(preAuth.itemDescription.isEmpty ? "—" : preAuth.itemDescription)
                    .font(.headline)
                Spacer()
                Text(preAuth.status.displayName)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(tint.opacity(0.15), in: Capsule())
                    .foregroundStyle(tint)
            }
            HStack(spacing: 12) {
                if let amount = preAuth.estimatedAmount, amount > 0 {
                    Label(amount.formatted(.currency(code: "USD")), systemImage: "dollarsign")
                }
                if let approvedDate = preAuth.approvedDate {
                    Label("approved \(approvedDate.formatted(date: .abbreviated, time: .omitted))", systemImage: "checkmark.seal")
                } else if let requestedDate = preAuth.requestedDate {
                    Label("requested \(requestedDate.formatted(date: .abbreviated, time: .omitted))", systemImage: "paperplane")
                }
                if !preAuth.approvedNumber.isEmpty {
                    Label(preAuth.approvedNumber, systemImage: "number")
                }
            }
            .font(.caption2)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private var tint: Color {
        switch preAuth.status {
        case .draft, .requested: return .orange
        case .approved:          return .green
        case .denied, .expired:  return .red
        }
    }
}

struct PreAuthFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let editingPreAuth: PreAuthorization?
    let parentStudent: Student?

    @State private var status: PreAuthStatus = .draft
    @State private var itemDescription: String = ""
    @State private var estimatedAmountText: String = ""
    @State private var categoryKey: String?
    @State private var requestedDate: Date = .now
    @State private var hasRequested: Bool = false
    @State private var approvedDate: Date = .now
    @State private var hasApproved: Bool = false
    @State private var approvedNumber: String = ""
    @State private var expirationDate: Date = .now
    @State private var hasExpiration: Bool = false
    @State private var notes: String = ""
    @State private var sfoResponseNote: String = ""

    init(preAuth: PreAuthorization?, parentStudent: Student? = nil) {
        self.editingPreAuth = preAuth
        self.parentStudent = parentStudent ?? preAuth?.student
        if let pa = preAuth {
            _status = State(initialValue: pa.status)
            _itemDescription = State(initialValue: pa.itemDescription)
            _estimatedAmountText = State(initialValue: pa.estimatedAmount.map { NSDecimalNumber(decimal: $0).stringValue } ?? "")
            _categoryKey = State(initialValue: pa.categoryKey)
            _hasRequested = State(initialValue: pa.requestedDate != nil)
            _requestedDate = State(initialValue: pa.requestedDate ?? .now)
            _hasApproved = State(initialValue: pa.approvedDate != nil)
            _approvedDate = State(initialValue: pa.approvedDate ?? .now)
            _approvedNumber = State(initialValue: pa.approvedNumber)
            _hasExpiration = State(initialValue: pa.expirationDate != nil)
            _expirationDate = State(initialValue: pa.expirationDate ?? .now)
            _notes = State(initialValue: pa.notes)
            _sfoResponseNote = State(initialValue: pa.sfoResponseNote)
        }
    }

    var body: some View {
        Form {
            Section("Item") {
                TextField("Describe what you plan to buy", text: $itemDescription, axis: .vertical)
                    .lineLimit(2...4)
                HStack {
                    Text("Estimated amount")
                    Spacer()
                    TextField("0.00", text: $estimatedAmountText)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 120)
                }
                if let student = parentStudent {
                    CategoryPickerView(selection: $categoryKey, student: student)
                }
            }
            Section("Status") {
                Picker("Status", selection: $status) {
                    ForEach(PreAuthStatus.allCases) { Text($0.displayName).tag($0) }
                }
                Toggle("Submitted on", isOn: $hasRequested)
                if hasRequested {
                    DatePicker("Submitted", selection: $requestedDate, displayedComponents: .date)
                }
                Toggle("Approved on", isOn: $hasApproved)
                if hasApproved {
                    DatePicker("Approved", selection: $approvedDate, displayedComponents: .date)
                    TextField("Approval / authorization number", text: $approvedNumber)
                }
                Toggle("Expires on", isOn: $hasExpiration)
                if hasExpiration {
                    DatePicker("Expires", selection: $expirationDate, displayedComponents: .date)
                }
            }
            Section("Notes") {
                TextField("My notes", text: $notes, axis: .vertical).lineLimit(2...5)
                TextField("SFO response / additional info requested", text: $sfoResponseNote, axis: .vertical).lineLimit(2...5)
            }
        }
        .navigationTitle(editingPreAuth == nil ? "New pre-auth" : "Edit pre-auth")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
                    .disabled(itemDescription.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            if editingPreAuth == nil {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() {
        let amount = DecimalParsing.parse(estimatedAmountText)
        if let existing = editingPreAuth {
            existing.status = status
            existing.itemDescription = itemDescription
            existing.estimatedAmount = amount
            existing.categoryKey = categoryKey
            existing.requestedDate = hasRequested ? requestedDate : nil
            existing.approvedDate = hasApproved ? approvedDate : nil
            existing.approvedNumber = approvedNumber
            existing.expirationDate = hasExpiration ? expirationDate : nil
            existing.notes = notes
            existing.sfoResponseNote = sfoResponseNote
        } else if let student = parentStudent {
            let pa = PreAuthorization(
                status: status,
                requestedDate: hasRequested ? requestedDate : nil,
                approvedDate: hasApproved ? approvedDate : nil,
                approvedNumber: approvedNumber,
                expirationDate: hasExpiration ? expirationDate : nil,
                itemDescription: itemDescription,
                estimatedAmount: amount,
                categoryKey: categoryKey,
                notes: notes,
                sfoResponseNote: sfoResponseNote,
                student: student
            )
            modelContext.insert(pa)
        }
        try? modelContext.save()
        dismiss()
    }
}
