import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(AppSettings.self) private var settings
    @Query(sort: \Student.createdAt) private var students: [Student]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    activeStudentCard
                    comingSoonCard
                    disclaimerCard
                }
                .padding(20)
            }
            .navigationTitle("Home")
            .toolbar {
                if !students.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            ForEach(students) { student in
                                Button {
                                    settings.activeStudentID = student.id
                                } label: {
                                    HStack {
                                        Text(student.displayName)
                                        if settings.activeStudentID == student.id {
                                            Image(systemName: "checkmark")
                                        }
                                    }
                                }
                            }
                        } label: {
                            Label("Switch", systemImage: "person.2.crop.square.stack")
                        }
                    }
                }
            }
        }
    }

    private var activeStudent: Student? {
        guard let id = settings.activeStudentID else { return students.first }
        return students.first { $0.id == id }
    }

    private var activeStudentCard: some View {
        Group {
            if let student = activeStudent {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Active student")
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    Text(student.displayName)
                        .font(.title.bold())
                    HStack(spacing: 6) {
                        Pill(text: student.program.shortName)
                        Pill(text: student.sfo.portalName)
                        Pill(text: student.schoolYear)
                    }
                    if let award = student.awardAmount {
                        Text("Expected award: \(award.formatted(.currency(code: "USD")))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("No active student")
                        .font(.headline)
                    Text("Add a student from the Students tab to begin.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var comingSoonCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Coming next")
                .font(.headline)
            Label("Scan receipts (Milestone 2)", systemImage: "doc.text.viewfinder")
            Label("Eligibility checker (Milestone 3)", systemImage: "checkmark.seal")
            Label("Claims lifecycle (Milestone 4)", systemImage: "list.bullet.rectangle")
            Label("Reports & export (Milestone 5)", systemImage: "chart.bar.doc.horizontal")
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }

    private var disclaimerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Heads up", systemImage: "info.circle")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(DisclaimerCopy.short)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct Pill: View {
    let text: String
    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Color.accentColor.opacity(0.18), in: Capsule())
            .foregroundStyle(Color.accentColor)
    }
}
