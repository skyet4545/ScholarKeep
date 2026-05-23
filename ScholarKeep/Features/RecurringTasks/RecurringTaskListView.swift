import SwiftUI
import SwiftData

struct RecurringTaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings
    @Query(sort: \RecurringTask.nextDueDate) private var allTasks: [RecurringTask]
    @Query(sort: \Student.createdAt) private var students: [Student]

    @State private var showingAdd = false
    @State private var showArchived = false

    private var activeStudent: Student? {
        guard let id = settings.activeStudentID else { return students.first }
        return students.first { $0.id == id }
    }

    private var visibleTasks: [RecurringTask] {
        let myTasks = activeStudent.map { s in
            allTasks.filter { $0.student?.id == s.id }
        } ?? allTasks
        return myTasks.filter { showArchived ? $0.isArchived : !$0.isArchived }
    }

    var body: some View {
        NavigationStack {
            List {
                if !visibleTasks.isEmpty {
                    Section {
                        Text(showArchived
                             ? "Completed and archived."
                             : "Annual evaluations, quarterly receipt bundles, renewals — anything you have to remember every school year.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                ForEach(visibleTasks) { task in
                    NavigationLink {
                        RecurringTaskFormView(task: task)
                    } label: {
                        RecurringTaskRow(task: task) {
                            complete(task)
                        }
                    }
                }
                .onDelete(perform: delete)
            }
            .overlay {
                if visibleTasks.isEmpty {
                    ContentUnavailableView {
                        Label(showArchived ? "Nothing archived" : "No recurring tasks", systemImage: "checklist")
                    } description: {
                        Text(showArchived
                             ? "Completed tasks appear here."
                             : "Add tasks that come around every school year — annual evaluations, quarterly receipts, renewals.")
                    } actions: {
                        if !showArchived {
                            Button("Add a task") { showingAdd = true }
                                .buttonStyle(.borderedProminent)
                                .disabled(activeStudent == nil)
                        }
                    }
                }
            }
            .navigationTitle("Recurring")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button { showingAdd = true } label: {
                        Label("Add task", systemImage: "plus")
                    }
                    .disabled(activeStudent == nil)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showArchived.toggle()
                    } label: {
                        Image(systemName: showArchived ? "archivebox.fill" : "archivebox")
                    }
                }
            }
            .sheet(isPresented: $showingAdd) {
                if let student = activeStudent {
                    NavigationStack {
                        RecurringTaskFormView(task: nil, parentStudent: student)
                    }
                }
            }
        }
    }

    private func complete(_ task: RecurringTask) {
        let wasArchived = task.isArchived
        task.markComplete()
        try? modelContext.save()
        Task {
            await NotificationsService.cancelRecurringTask(id: task.id)
            if !task.isArchived {
                await NotificationsService.scheduleRecurringTask(task)
            }
        }
        // Provide haptic-style feedback by briefly showing the completed state.
        _ = wasArchived
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            let task = visibleTasks[index]
            Task { await NotificationsService.cancelRecurringTask(id: task.id) }
            modelContext.delete(task)
        }
        try? modelContext.save()
    }
}

private struct RecurringTaskRow: View {
    let task: RecurringTask
    let onComplete: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(task.title).font(.headline)
                HStack(spacing: 8) {
                    Image(systemName: task.schedule == .oneTime ? "1.circle" : "arrow.clockwise")
                        .font(.caption2)
                    Text(task.schedule.displayName)
                    Text("·")
                    Text(dueLabel)
                        .foregroundStyle(task.isOverdue ? .red : .secondary)
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            Spacer()
            if !task.isArchived {
                Button {
                    onComplete()
                } label: {
                    Image(systemName: "checkmark.circle")
                        .font(.title3)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.vertical, 4)
    }

    private var dueLabel: String {
        let cal = Calendar.current
        let days = cal.dateComponents([.day], from: .now, to: task.nextDueDate).day ?? 0
        if task.isArchived { return "archived" }
        if days < 0       { return "overdue \(-days)d" }
        if days == 0      { return "due today" }
        if days == 1      { return "due tomorrow" }
        if days < 30      { return "in \(days)d" }
        return task.nextDueDate.formatted(date: .abbreviated, time: .omitted)
    }
}

struct RecurringTaskFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let editingTask: RecurringTask?
    let parentStudent: Student?

    @State private var title: String = ""
    @State private var notes: String = ""
    @State private var schedule: RecurringSchedule = .annually
    @State private var nextDueDate: Date = .now
    @State private var template: RecurringTaskTemplate = .custom

    init(task: RecurringTask?, parentStudent: Student? = nil) {
        self.editingTask = task
        self.parentStudent = parentStudent ?? task?.student
        if let t = task {
            _title = State(initialValue: t.title)
            _notes = State(initialValue: t.notes)
            _schedule = State(initialValue: t.schedule)
            _nextDueDate = State(initialValue: t.nextDueDate)
        }
    }

    var body: some View {
        Form {
            if editingTask == nil {
                Section("Start from a template") {
                    Picker("Template", selection: $template) {
                        ForEach(RecurringTaskTemplate.allCases) { t in
                            Label(t.title, systemImage: t.iconName).tag(t)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: template) { _, newValue in
                        if newValue != .custom {
                            title = newValue.title
                            schedule = newValue.defaultSchedule
                        }
                    }
                }
            }
            Section("Task") {
                TextField("Title", text: $title)
                Picker("Repeats", selection: $schedule) {
                    ForEach(RecurringSchedule.allCases) { Text($0.displayName).tag($0) }
                }
                DatePicker("Next due", selection: $nextDueDate, displayedComponents: .date)
            }
            Section("Notes") {
                TextField("Notes", text: $notes, axis: .vertical).lineLimit(2...5)
            }
            if let task = editingTask, !task.isArchived {
                Section {
                    Button("Mark complete now") {
                        task.markComplete()
                        try? modelContext.save()
                        Task {
                            await NotificationsService.cancelRecurringTask(id: task.id)
                            if !task.isArchived {
                                await NotificationsService.scheduleRecurringTask(task)
                            }
                        }
                        dismiss()
                    }
                }
            }
        }
        .navigationTitle(editingTask == nil ? "New task" : "Edit task")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Save", action: save)
                    .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            if editingTask == nil {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
    }

    private func save() {
        if let existing = editingTask {
            existing.title = title
            existing.notes = notes
            existing.schedule = schedule
            existing.nextDueDate = nextDueDate
        } else if let student = parentStudent {
            let task = RecurringTask(
                title: title,
                notes: notes,
                schedule: schedule,
                nextDueDate: nextDueDate,
                student: student
            )
            modelContext.insert(task)
        }
        try? modelContext.save()
        if let task = editingTask {
            Task { await NotificationsService.scheduleRecurringTask(task) }
        }
        dismiss()
    }
}
