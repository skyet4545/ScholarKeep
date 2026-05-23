import SwiftUI
import SwiftData

struct ProviderListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings
    @Query(sort: \Provider.createdAt) private var allProviders: [Provider]
    @Query(sort: \Student.createdAt) private var students: [Student]

    @State private var showingAdd = false

    private var activeStudent: Student? {
        guard let id = settings.activeStudentID else { return students.first }
        return students.first { $0.id == id }
    }

    private var visibleProviders: [Provider] {
        guard let s = activeStudent else { return [] }
        return allProviders.filter { $0.student?.id == s.id }
    }

    var body: some View {
        NavigationStack {
            List {
                if let s = activeStudent {
                    Section {
                        Text("Providers for \(s.displayName)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                ForEach(visibleProviders) { provider in
                    NavigationLink {
                        ProviderFormView(provider: provider)
                    } label: {
                        ProviderRow(provider: provider)
                    }
                }
                .onDelete(perform: delete)
            }
            .overlay {
                if visibleProviders.isEmpty {
                    ContentUnavailableView {
                        Label("No providers yet", systemImage: "person.text.rectangle")
                    } description: {
                        Text("Add tutors, therapists, and other providers here so the app can validate their credentials on every receipt.")
                    } actions: {
                        Button("Add provider") { showingAdd = true }
                            .buttonStyle(.borderedProminent)
                            .disabled(activeStudent == nil)
                    }
                }
            }
            .navigationTitle("Providers")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAdd = true } label: {
                        Label("Add provider", systemImage: "plus")
                    }
                    .disabled(activeStudent == nil)
                }
            }
            .sheet(isPresented: $showingAdd) {
                if let student = activeStudent {
                    NavigationStack {
                        ProviderFormView(provider: nil, parentStudent: student)
                    }
                }
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets { modelContext.delete(visibleProviders[index]) }
        try? modelContext.save()
    }
}

private struct ProviderRow: View {
    let provider: Provider

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(provider.name).font(.headline)
                Spacer()
                Text(provider.type.displayName)
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Color.accentColor.opacity(0.15), in: Capsule())
                    .foregroundStyle(Color.accentColor)
            }
            if !provider.licenseNumber.isEmpty {
                Text("\(provider.licenseType.isEmpty ? "License" : provider.licenseType): \(provider.licenseNumber) (\(provider.licenseState))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Label("No license number on file", systemImage: "exclamationmark.triangle")
                    .font(.caption)
                    .foregroundStyle(.orange)
            }
            if provider.isFloridaCertifiedTeacher {
                Label("Florida-certified teacher", systemImage: "checkmark.seal")
                    .font(.caption2)
                    .foregroundStyle(.green)
            }
        }
        .padding(.vertical, 2)
    }
}

struct ProviderFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let editingProvider: Provider?
    let parentStudent: Student?

    @State private var name: String = ""
    @State private var type: ProviderType = .partTimeTutor
    @State private var licenseNumber: String = ""
    @State private var licenseType: String = ""
    @State private var licenseState: String = "FL"
    @State private var isFloridaCertifiedTeacher: Bool = false
    @State private var deliversVirtually: Bool = false
    @State private var notes: String = ""

    init(provider: Provider?, parentStudent: Student? = nil) {
        self.editingProvider = provider
        self.parentStudent = parentStudent ?? provider?.student
        if let p = provider {
            _name = State(initialValue: p.name)
            _type = State(initialValue: p.type)
            _licenseNumber = State(initialValue: p.licenseNumber)
            _licenseType = State(initialValue: p.licenseType)
            _licenseState = State(initialValue: p.licenseState)
            _isFloridaCertifiedTeacher = State(initialValue: p.isFloridaCertifiedTeacher)
            _deliversVirtually = State(initialValue: p.deliversVirtually)
            _notes = State(initialValue: p.notes)
        }
    }

    var body: some View {
        Form {
            Section("Provider") {
                TextField("Name (as on invoice)", text: $name)
                    .textContentType(.name)
                Picker("Type", selection: $type) {
                    ForEach(ProviderType.allCases) { Text($0.displayName).tag($0) }
                }
            }
            Section {
                TextField("License number", text: $licenseNumber)
                TextField("License type (e.g. BCBA, SLP, Florida Educator's Certificate)", text: $licenseType)
                TextField("State", text: $licenseState)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.characters)
                Toggle("Holds a valid Florida teaching certificate", isOn: $isFloridaCertifiedTeacher)
                Toggle("Delivers services virtually (out-of-state OK if credentialed)", isOn: $deliversVirtually)
            } header: {
                Text("Credentials")
            } footer: {
                Text("Florida Department of Health, Agency for Persons with Disabilities (APD), Specialized Instructional Services (SIS), Behavior Analyst Certification Board (BACB / BCBA), or Florida Educator's Certificate.")
            }
            Section("Notes") {
                TextField("Notes", text: $notes, axis: .vertical).lineLimit(2...5)
            }
        }
        .navigationTitle(editingProvider == nil ? "Add provider" : "Edit provider")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            if editingProvider == nil {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() {
        if let existing = editingProvider {
            existing.name = name.trimmingCharacters(in: .whitespaces)
            existing.type = type
            existing.licenseNumber = licenseNumber.trimmingCharacters(in: .whitespaces)
            existing.licenseType = licenseType.trimmingCharacters(in: .whitespaces)
            existing.licenseState = licenseState.trimmingCharacters(in: .whitespaces).uppercased()
            existing.isFloridaCertifiedTeacher = isFloridaCertifiedTeacher
            existing.deliversVirtually = deliversVirtually
            existing.notes = notes
        } else if let student = parentStudent {
            let p = Provider(
                name: name.trimmingCharacters(in: .whitespaces),
                type: type,
                licenseNumber: licenseNumber.trimmingCharacters(in: .whitespaces),
                licenseType: licenseType.trimmingCharacters(in: .whitespaces),
                licenseState: licenseState.trimmingCharacters(in: .whitespaces).uppercased(),
                isFloridaCertifiedTeacher: isFloridaCertifiedTeacher,
                deliversVirtually: deliversVirtually,
                notes: notes,
                student: student
            )
            modelContext.insert(p)
        }
        try? modelContext.save()
        dismiss()
    }
}
