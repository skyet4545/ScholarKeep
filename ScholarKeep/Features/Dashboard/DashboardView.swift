import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(AppSettings.self) private var settings
    @Query(sort: \Student.createdAt) private var students: [Student]
    @Query(sort: \Expense.purchaseDate, order: .reverse) private var expenses: [Expense]
    @Query(sort: \Claim.createdAt, order: .reverse) private var claims: [Claim]
    @Query(sort: \BalanceEntry.date) private var balanceEntries: [BalanceEntry]

    @State private var showCapture = false
    @State private var capturingSource: CaptureFlowView.Source = .scanner

    private var activeStudent: Student? {
        guard let id = settings.activeStudentID else { return students.first }
        return students.first { $0.id == id }
    }

    private var myExpenses: [Expense] {
        guard let s = activeStudent else { return [] }
        return expenses.filter { $0.student?.id == s.id }
    }

    private var myClaims: [Claim] {
        guard let s = activeStudent else { return [] }
        return claims.filter { $0.student?.id == s.id }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    activeStudentCard
                    scanCTA
                    balanceCard
                    needsAttentionCard
                    deadlineCard
                    claimsSummaryCard
                    disclaimerCard
                }
                .padding(20)
            }
            .navigationTitle("Home")
            .toolbar {
                if !students.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            ForEach(students) { s in
                                Button {
                                    settings.activeStudentID = s.id
                                } label: {
                                    HStack {
                                        Text(s.displayName)
                                        if settings.activeStudentID == s.id {
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
            .sheet(isPresented: $showCapture) {
                if let student = activeStudent {
                    CaptureFlowView(student: student, source: capturingSource)
                }
            }
        }
    }

    private var activeStudentCard: some View {
        Group {
            if let s = activeStudent {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Active student").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                    Text(s.displayName).font(.title.bold())
                    HStack(spacing: 6) {
                        Pill(text: s.program.shortName)
                        Pill(text: s.sfo.portalName)
                        Pill(text: s.schoolYear)
                    }
                    if let award = s.awardAmount {
                        let total = myExpenses.reduce(Decimal(0)) { $0 + $1.total }
                        let nsAward = NSDecimalNumber(decimal: award).doubleValue
                        let nsTotal = NSDecimalNumber(decimal: total).doubleValue
                        ProgressView(value: min(nsTotal, nsAward), total: max(nsAward, 1))
                        Text("\(total.formatted(.currency(code: "USD"))) of \(award.formatted(.currency(code: "USD"))) tracked")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.accentColor.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    Text("No active student").font(.headline)
                    Text("Add a student from the Students tab to begin.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.secondary.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var scanCTA: some View {
        Group {
            if activeStudent != nil {
                Menu {
                    Button { capturingSource = .scanner; showCapture = true } label: {
                        Label("Scan with camera", systemImage: "doc.text.viewfinder")
                    }
                    Button { capturingSource = .photoLibrary; showCapture = true } label: {
                        Label("Pick from library", systemImage: "photo.on.rectangle")
                    }
                } label: {
                    HStack {
                        Image(systemName: "doc.text.viewfinder")
                        Text("Scan receipt").bold()
                        Spacer()
                        Image(systemName: "chevron.right")
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 14))
                    .foregroundStyle(.white)
                }
            }
        }
    }

    private var balanceCard: some View {
        let myEntries = balanceEntries.filter { $0.student?.id == activeStudent?.id }
        let summary = BalanceLedger.summarize(entries: myEntries)
        return Group {
            if !myEntries.isEmpty {
                NavigationLink {
                    BalanceLedgerView()
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Available now").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
                            Spacer()
                            Image(systemName: "chevron.right").font(.caption2).foregroundStyle(.secondary)
                        }
                        Text(summary.availableBalance.formatted(.currency(code: "USD")))
                            .font(.title.bold().monospacedDigit())
                            .foregroundStyle(summary.availableBalance < 0 ? .red : .primary)
                        if summary.pendingClaims > 0 {
                            Text("\(summary.pendingClaims.formatted(.currency(code: "USD"))) in pending claims")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(Color.accentColor.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
                }
                .buttonStyle(.plain)
            }
        }
    }

    private var needsAttentionCard: some View {
        let onHold = myClaims.filter { $0.status == .onHold }
        let incomplete = myExpenses.filter { e in !e.readinessChecklist.isComplete && e.claim != nil && (e.claim?.status == .draft || e.claim?.status == .readyToSubmit) }
        return Group {
            if !onHold.isEmpty || !incomplete.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Needs attention").font(.headline)
                    ForEach(onHold) { claim in
                        Label("\(claim.title) is on hold", systemImage: "exclamationmark.circle")
                            .font(.subheadline)
                    }
                    if !incomplete.isEmpty {
                        Label("\(incomplete.count) expense(s) with incomplete checklist", systemImage: "checklist")
                            .font(.subheadline)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
            }
        }
    }

    private var deadlineCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Key dates this year").font(.caption.weight(.semibold)).foregroundStyle(.secondary)
            ForEach(deadlines(), id: \.label) { item in
                HStack {
                    Image(systemName: item.icon)
                        .foregroundStyle(item.tint)
                    VStack(alignment: .leading, spacing: 0) {
                        Text(item.label).font(.subheadline)
                        Text(item.subline)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(item.daysAway)d")
                        .font(.caption.bold().monospacedDigit())
                        .foregroundStyle(item.tint)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }

    private struct DeadlineItem {
        let label: String
        let subline: String
        let icon: String
        let tint: Color
        let daysAway: Int
    }

    private func deadlines() -> [DeadlineItem] {
        let label = RulesetLoader.shared.schoolYearLabel
        let parts = label.split(separator: "-")
        guard parts.count == 2, let start = Int(parts[0]) else { return [] }
        let endYear = start + 1
        func make(_ m: Int, _ d: Int, _ label: String, _ subline: String, _ icon: String) -> DeadlineItem? {
            var c = DateComponents(); c.year = endYear; c.month = m; c.day = d
            guard let date = Calendar.current.date(from: c), date >= .now else { return nil }
            let days = Calendar.current.dateComponents([.day], from: .now, to: date).day ?? 0
            let tint: Color
            switch days {
            case ..<7:  tint = .red
            case ..<30: tint = .orange
            default:    tint = .primary
            }
            return DeadlineItem(label: label, subline: subline, icon: icon, tint: tint, daysAway: days)
        }
        return [
            make(5, 29, "Pre-auth cutoff", "May 29 — last day to submit pre-auth requests", "checkmark.shield"),
            make(6, 30, "Spend cliff", "June 30 — purchases must occur by this date", "calendar.badge.exclamationmark"),
            make(7, 31, "Submission cliff", "July 31 — reimbursement deadline, no extensions", "tray.and.arrow.up.fill")
        ].compactMap { $0 }
    }

    private var claimsSummaryCard: some View {
        let grouped = Dictionary(grouping: myClaims, by: { $0.status })
        return VStack(alignment: .leading, spacing: 8) {
            Text("Claims at a glance").font(.headline)
            HStack(spacing: 12) {
                summaryStat("Draft", grouped[.draft]?.count ?? 0)
                summaryStat("Submitted", grouped[.submitted]?.count ?? 0)
                summaryStat("On hold", grouped[.onHold]?.count ?? 0)
                summaryStat("Paid", grouped[.paidReimbursed]?.count ?? 0)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 16))
    }

    private func summaryStat(_ label: String, _ count: Int) -> some View {
        VStack {
            Text("\(count)").font(.title2.bold())
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    private var disclaimerCard: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("Heads up", systemImage: "info.circle")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
            Text(DisclaimerCopy.short).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color.secondary.opacity(0.06), in: RoundedRectangle(cornerRadius: 12))
    }

    private func nextSubmissionDeadline() -> Date? {
        let label = RulesetLoader.shared.schoolYearLabel
        let parts = label.split(separator: "-")
        guard parts.count == 2, let start = Int(parts[0]) else { return nil }
        var comps = DateComponents()
        comps.year = start + 1
        comps.month = 7
        comps.day = 31
        return Calendar.current.date(from: comps)
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
