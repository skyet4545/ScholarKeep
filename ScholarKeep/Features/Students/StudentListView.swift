import SwiftUI
import SwiftData

struct StudentListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings
    @Query(sort: \Student.createdAt, order: .forward) private var students: [Student]

    @State private var showingAdd = false
    @State private var editingStudent: Student?

    var body: some View {
        NavigationStack {
            List {
                ForEach(students) { student in
                    Button {
                        editingStudent = student
                    } label: {
                        StudentRow(
                            student: student,
                            isActive: settings.activeStudentID == student.id,
                            onSetActive: { settings.activeStudentID = student.id }
                        )
                    }
                    .buttonStyle(.plain)
                }
                .onDelete(perform: delete)
            }
            .overlay {
                if students.isEmpty {
                    ContentUnavailableView(
                        "No students yet",
                        systemImage: "person.crop.circle.badge.plus",
                        description: Text("Add a student to start tracking expenses.")
                    )
                }
            }
            .navigationTitle("Students")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAdd = true } label: {
                        Label("Add student", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                AddOrEditStudentSheet(mode: .add) { newStudent in
                    if settings.activeStudentID == nil {
                        settings.activeStudentID = newStudent.id
                    }
                }
            }
            .sheet(item: $editingStudent) { student in
                AddOrEditStudentSheet(mode: .edit(student))
            }
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let student = students[index]
            if settings.activeStudentID == student.id {
                settings.activeStudentID = nil
            }
            modelContext.delete(student)
        }
        try? modelContext.save()
    }
}

private struct StudentRow: View {
    let student: Student
    let isActive: Bool
    let onSetActive: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 8) {
                    Text(student.displayName)
                        .font(.headline)
                    if isActive {
                        Text("Active")
                            .font(.caption2.weight(.semibold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.15), in: Capsule())
                            .foregroundStyle(Color.accentColor)
                    }
                }
                Text("\(student.program.shortName) · \(student.sfo.portalName) · \(student.schoolYear)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !student.gradeLevel.isEmpty || !student.county.isEmpty {
                    Text([student.gradeLevel, student.county].filter { !$0.isEmpty }.joined(separator: " · "))
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer()
            if !isActive {
                Button("Set active", action: onSetActive)
                    .font(.caption.weight(.semibold))
                    .buttonStyle(.bordered)
                    .controlSize(.mini)
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}

struct AddOrEditStudentSheet: View {
    enum Mode {
        case add
        case edit(Student)
    }

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext

    let mode: Mode
    var onSaved: ((Student) -> Void)? = nil

    @State private var draft: StudentFormDraft
    @State private var saveError: String?

    init(mode: Mode, onSaved: ((Student) -> Void)? = nil) {
        self.mode = mode
        self.onSaved = onSaved
        switch mode {
        case .add:
            _draft = State(initialValue: StudentFormDraft())
        case .edit(let student):
            _draft = State(initialValue: StudentFormDraft(student: student))
        }
    }

    var body: some View {
        NavigationStack {
            VStack {
                StudentFormView(
                    displayName: $draft.displayName,
                    program: $draft.program,
                    sfo: $draft.sfo,
                    gradeLevel: $draft.gradeLevel,
                    county: $draft.county,
                    schoolYear: $draft.schoolYear,
                    awardAmountText: $draft.awardAmountText,
                    notes: $draft.notes,
                    slpApprovedDate: $draft.slpApprovedDate
                )
                if let saveError {
                    Text(saveError)
                        .font(.footnote)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }
            }
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!draft.isValid)
                }
            }
        }
    }

    private var title: String {
        switch mode {
        case .add:  return "Add student"
        case .edit: return "Edit student"
        }
    }

    private func save() {
        do {
            switch mode {
            case .add:
                let student = draft.newStudent()
                modelContext.insert(student)
                try modelContext.save()
                onSaved?(student)
            case .edit(let student):
                draft.apply(to: student)
                try modelContext.save()
                onSaved?(student)
            }
            dismiss()
        } catch {
            saveError = "Couldn't save: \(error.localizedDescription)"
        }
    }
}
