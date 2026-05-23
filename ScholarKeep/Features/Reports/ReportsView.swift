import SwiftUI
import SwiftData
import Charts

struct ReportsView: View {
    @Environment(AppSettings.self) private var settings
    @Query(sort: \Expense.purchaseDate) private var allExpenses: [Expense]
    @Query(sort: \Student.createdAt) private var students: [Student]
    @Query(sort: \Claim.createdAt) private var allClaims: [Claim]

    @State private var selectedStudentID: UUID? = nil
    @State private var selectedCategory: String? = nil
    @State private var selectedStatus: ClaimStatus? = nil
    @State private var schoolYearFilter: String? = nil
    @State private var exportURL: URL?
    @State private var exportError: String?

    private var visibleExpenses: [Expense] {
        var list = allExpenses
        if let id = selectedStudentID ?? settings.activeStudentID {
            list = list.filter { $0.student?.id == id }
        }
        if let category = selectedCategory {
            list = list.filter { $0.categoryKey == category }
        }
        if let status = selectedStatus {
            list = list.filter { $0.claim?.status == status }
        }
        if let year = schoolYearFilter {
            list = list.filter { $0.student?.schoolYear == year }
        }
        return list
    }

    private var totalSpent: Decimal {
        visibleExpenses.reduce(Decimal(0)) { $0 + $1.total }
    }

    private var activeStudent: Student? {
        guard let id = selectedStudentID ?? settings.activeStudentID else { return students.first }
        return students.first { $0.id == id }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    filtersCard
                    progressCard
                    chartCard
                    statusBreakdownCard
                    exportCard
                }
                .padding(20)
            }
            .navigationTitle("Reports")
        }
    }

    private var filtersCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Filters").font(.caption.bold()).foregroundStyle(.secondary)
            Picker("Student", selection: $selectedStudentID) {
                Text("Active").tag(UUID?.none)
                ForEach(students) { Text($0.displayName).tag(UUID?.some($0.id)) }
            }
            Picker("Category", selection: $selectedCategory) {
                Text("All").tag(String?.none)
                if let cats = RulesetLoader.shared.ruleset?.categories {
                    ForEach(cats) { c in Text(c.displayName).tag(String?.some(c.key)) }
                }
            }
            Picker("Claim status", selection: $selectedStatus) {
                Text("Any").tag(ClaimStatus?.none)
                ForEach(ClaimStatus.allCases) { Text($0.displayName).tag(ClaimStatus?.some($0)) }
            }
        }
        .padding(16)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
    }

    private var progressCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Spent vs. expected award").font(.caption.bold()).foregroundStyle(.secondary)
            if let student = activeStudent, let award = student.awardAmount, award > 0 {
                let nsTotal = NSDecimalNumber(decimal: totalSpent).doubleValue
                let nsAward = NSDecimalNumber(decimal: award).doubleValue
                ProgressView(value: min(nsTotal, nsAward), total: nsAward)
                Text("\(totalSpent.formatted(.currency(code: "USD"))) of \(award.formatted(.currency(code: "USD")))")
                    .font(.subheadline)
            } else {
                Text(totalSpent.formatted(.currency(code: "USD")))
                    .font(.title.bold())
                Text("Add an award amount in Students to see progress.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
    }

    private var chartCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Spend by category").font(.caption.bold()).foregroundStyle(.secondary)
            let grouped = Dictionary(grouping: visibleExpenses, by: { $0.categoryKey ?? "uncategorized" })
                .map { (key, items) in
                    SpendBucket(category: displayName(for: key),
                                amount: items.reduce(Decimal(0)) { $0 + $1.total })
                }
                .sorted(by: { $0.amount > $1.amount })
            if grouped.isEmpty {
                Text("No data yet.").foregroundStyle(.secondary)
            } else {
                Chart(grouped, id: \.category) { bucket in
                    BarMark(
                        x: .value("Amount", NSDecimalNumber(decimal: bucket.amount).doubleValue),
                        y: .value("Category", bucket.category)
                    )
                    .foregroundStyle(Color.accentColor)
                }
                .frame(height: CGFloat(grouped.count * 32 + 40))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
    }

    private var statusBreakdownCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Claims by status").font(.caption.bold()).foregroundStyle(.secondary)
            let claims = allClaims.filter { c in
                (selectedStudentID ?? settings.activeStudentID).map { c.student?.id == $0 } ?? true
            }
            let grouped = Dictionary(grouping: claims, by: { $0.status })
                .map { (status, items) in StatusBucket(status: status, count: items.count) }
                .sorted(by: { ClaimStatus.boardColumns.firstIndex(of: $0.status) ?? 0 < ClaimStatus.boardColumns.firstIndex(of: $1.status) ?? 0 })
            if grouped.isEmpty {
                Text("No claims yet.").foregroundStyle(.secondary)
            } else {
                Chart(grouped, id: \.status) { bucket in
                    BarMark(
                        x: .value("Status", bucket.status.displayName),
                        y: .value("Count", bucket.count)
                    )
                    .foregroundStyle(by: .value("Status", bucket.status.displayName))
                }
                .frame(height: 200)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
    }

    private var exportCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Export").font(.caption.bold()).foregroundStyle(.secondary)
            Button {
                exportCSV()
            } label: {
                Label("Export filtered as CSV", systemImage: "tablecells")
            }
            .buttonStyle(.borderedProminent)
            if let exportURL {
                ShareLink(item: exportURL) {
                    Label("Share \(exportURL.lastPathComponent)", systemImage: "square.and.arrow.up")
                }
            }
            if let exportError {
                Text(exportError).foregroundStyle(.red).font(.caption)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
    }

    private func exportCSV() {
        do {
            exportURL = try CSVExportService.exportExpenses(visibleExpenses)
            exportError = nil
        } catch {
            exportError = "Couldn't export: \(error.localizedDescription)"
        }
    }

    private func displayName(for key: String) -> String {
        guard let cats = RulesetLoader.shared.ruleset?.categories else { return key }
        return cats.first(where: { $0.key == key })?.displayName ?? key.capitalized
    }
}

private struct SpendBucket: Hashable {
    let category: String
    let amount: Decimal
}

private struct StatusBucket: Hashable {
    let status: ClaimStatus
    let count: Int
}
