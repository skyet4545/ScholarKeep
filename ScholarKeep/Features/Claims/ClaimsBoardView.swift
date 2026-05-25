import SwiftUI
import SwiftData

struct ClaimsBoardView: View {
    @Environment(AppSettings.self) private var settings
    @Query(sort: \Claim.createdAt, order: .reverse) private var allClaims: [Claim]
    @Query(sort: \Student.createdAt) private var students: [Student]

    @State private var statusFilter: ClaimStatus? = nil

    private var activeStudent: Student? {
        guard let id = settings.activeStudentID else { return students.first }
        return students.first { $0.id == id }
    }

    private var visibleClaims: [Claim] {
        var list = allClaims
        if let s = activeStudent {
            list = list.filter { $0.student?.id == s.id }
        }
        if let filter = statusFilter {
            list = list.filter { $0.status == filter }
        }
        return list
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                statusFilterBar
                List {
                    ForEach(visibleClaims) { claim in
                        NavigationLink {
                            ClaimDetailView(claim: claim)
                        } label: {
                            ClaimRow(claim: claim)
                        }
                    }
                }
                .overlay {
                    if visibleClaims.isEmpty {
                        ContentUnavailableView(
                            "No claims",
                            systemImage: "tray",
                            description: Text("Create a claim from any expense to start tracking its lifecycle.")
                        )
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(DS.canvas)
            .navigationTitle("Claims")
        }
    }

    private var statusFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                FilterChip(title: "All", count: allClaimsForStudent.count, isSelected: statusFilter == nil) {
                    statusFilter = nil
                }
                ForEach(ClaimStatus.boardColumns) { status in
                    let count = allClaimsForStudent.filter { $0.status == status }.count
                    if count > 0 {
                        FilterChip(title: status.displayName, count: count, isSelected: statusFilter == status) {
                            statusFilter = (statusFilter == status) ? nil : status
                        }
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private var allClaimsForStudent: [Claim] {
        guard let s = activeStudent else { return allClaims }
        return allClaims.filter { $0.student?.id == s.id }
    }
}

private struct FilterChip: View {
    let title: String
    let count: Int
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 4) {
                Text(title)
                Text("\(count)")
                    .font(.caption2.bold())
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(isSelected ? Color.accentColor : Color.secondary.opacity(0.15), in: Capsule())
            .foregroundStyle(isSelected ? .white : .primary)
        }
        .buttonStyle(.plain)
    }
}

private struct ClaimRow: View {
    let claim: Claim

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: claim.status.systemImageName)
                    .foregroundStyle(.tint)
                Text(claim.title).font(.headline)
                Spacer()
                Text(claim.status.displayName)
                    .font(.caption.bold())
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.accentColor.opacity(0.15), in: Capsule())
                    .foregroundStyle(Color.accentColor)
            }
            HStack(spacing: 12) {
                Label("\(claim.expenses.count)", systemImage: "doc.text")
                Label(totalAmount.formatted(.currency(code: "USD")), systemImage: "dollarsign")
                if let submitted = claim.submittedDate {
                    Label(submitted.formatted(date: .abbreviated, time: .omitted), systemImage: "paperplane")
                }
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.vertical, 3)
    }

    private var totalAmount: Decimal {
        claim.expenses.reduce(Decimal(0)) { $0 + $1.total }
    }
}
