import SwiftUI
import SwiftData

/// Persistent "whose data am I looking at?" header. Tap to switch students,
/// long-tap target to open Student detail. Used on Home, Check, Claims, More.
struct StudentStripView: View {
    @Environment(AppSettings.self) private var settings
    @Query(sort: \Student.createdAt) private var students: [Student]
    @State private var showSwitcher = false

    private var active: Student? {
        if let id = settings.activeStudentID { return students.first { $0.id == id } }
        return students.first
    }

    var body: some View {
        if let s = active {
            Button {
                if students.count > 1 { showSwitcher = true }
            } label: {
                HStack(spacing: 10) {
                    initialsBadge(for: s)
                    Text(s.displayName)
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("\(s.program.shortName) · \(s.schoolYear)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 0)
                    if students.count > 1 {
                        Image(systemName: "chevron.down")
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(DS.grouped, in: RoundedRectangle(cornerRadius: 14))
            }
            .buttonStyle(.plain)
            .padding(.horizontal, DS.base)
            .padding(.top, DS.sm)
            .confirmationDialog("Switch student", isPresented: $showSwitcher, titleVisibility: .visible) {
                ForEach(students) { st in
                    Button {
                        settings.activeStudentID = st.id
                    } label: {
                        Text("\(st.displayName) — \(st.program.shortName)")
                    }
                }
                Button("Cancel", role: .cancel) { }
            }
        }
    }

    private func initialsBadge(for s: Student) -> some View {
        Text(String(s.displayName.prefix(1)).uppercased())
            .font(.footnote.weight(.bold))
            .foregroundStyle(DS.accent)
            .frame(width: 26, height: 26)
            .background(DS.accentSoft, in: RoundedRectangle(cornerRadius: 8))
    }
}
