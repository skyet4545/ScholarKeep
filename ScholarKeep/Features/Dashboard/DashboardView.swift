import SwiftUI
import SwiftData

/// v0.5.0 dashboard — Jony Ive remix:
/// clean white hero with one giant ink number, three muted quick stats,
/// recent activity feed, and key dates. Scan lives as a top-right nav action,
/// Apple Reminders-style — no FAB.
struct DashboardView: View {
    @Environment(AppSettings.self) private var settings
    @Query(sort: \Student.createdAt) private var students: [Student]
    @Query(sort: \Expense.purchaseDate, order: .reverse) private var expenses: [Expense]
    @Query(sort: \Claim.createdAt, order: .reverse) private var claims: [Claim]
    @Query(sort: \BalanceEntry.date) private var balanceEntries: [BalanceEntry]
    @Query(sort: \RecurringTask.nextDueDate) private var recurringTasks: [RecurringTask]
    @Environment(\.modelContext) private var modelContext

    @State private var showCapture = false
    @State private var capturingSource: CaptureFlowView.Source = .scanner
    @State private var showGroupedClaimConfirm = false

    // MARK: Derived

    private var activeStudent: Student? {
        if let id = settings.activeStudentID { return students.first { $0.id == id } }
        return students.first
    }
    private var myExpenses: [Expense] { activeStudent.map { s in expenses.filter { $0.student?.id == s.id } } ?? [] }
    private var myClaims: [Claim]     { activeStudent.map { s in claims.filter { $0.student?.id == s.id } } ?? [] }
    private var myEntries: [BalanceEntry] { activeStudent.map { s in balanceEntries.filter { $0.student?.id == s.id } } ?? [] }
    private var balanceSummary: BalanceLedger.Summary { BalanceLedger.summarize(entries: myEntries) }
    private var unclaimedExpenses: [Expense] { myExpenses.filter { $0.claim == nil } }
    private var unclaimedTotal: Decimal { unclaimedExpenses.reduce(Decimal(0)) { $0 + $1.total } }
    private var myUpcomingTasks: [RecurringTask] {
        guard let s = activeStudent else { return [] }
        let cutoff = Calendar.current.date(byAdding: .day, value: 60, to: .now) ?? .now
        return recurringTasks
            .filter { $0.student?.id == s.id && !$0.isArchived && $0.nextDueDate <= cutoff }
            .sorted { $0.nextDueDate < $1.nextDueDate }
            .prefix(3)
            .map { $0 }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.lg) {
                    StudentStripView()
                    if activeStudent != nil {
                        heroBalance
                        quickStatGrid
                        unclaimedReceiptsCard
                        upcomingRemindersCard
                        recentActivitySection
                        keyDatesSection
                    } else {
                        emptyState
                    }
                }
                .padding(.bottom, DS.xxl)
            }
            .background(DS.canvas.ignoresSafeArea())
            .navigationTitle("Home")
            .toolbar { scanToolbar }
            .sheet(isPresented: $showCapture) {
                if let student = activeStudent {
                    CaptureFlowView(student: student, source: capturingSource)
                }
            }
        }
    }

    // MARK: Toolbar — Apple Reminders-style "+" pattern, no FAB

    @ToolbarContentBuilder
    private var scanToolbar: some ToolbarContent {
        if activeStudent != nil {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        capturingSource = .scanner; showCapture = true
                    } label: {
                        Label("Scan with camera", systemImage: "doc.text.viewfinder")
                    }
                    Button {
                        capturingSource = .photoLibrary; showCapture = true
                    } label: {
                        Label("Pick from library", systemImage: "photo.on.rectangle")
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.title3.weight(.semibold))
                }
                .accessibilityLabel("Add receipt")
                .accessibilityHint("Scan with camera or pick from your photo library")
            }
        }
    }

    // MARK: Hero — single ink number, clean white card, hairline progress

    private var heroBalance: some View {
        let available = balanceSummary.availableBalance
        let award = activeStudent?.awardAmount ?? balanceSummary.totalDisbursed
        let progress: Double = {
            guard award > 0 else { return 0 }
            let n = NSDecimalNumber(decimal: available).doubleValue
            let d = NSDecimalNumber(decimal: award).doubleValue
            return max(0, min(1, 1 - (n / d)))
        }()
        return VStack(alignment: .leading, spacing: DS.sm) {
            Text("Available")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Text(available.formatted(.currency(code: "USD")))
                .font(.system(size: 44, weight: .bold, design: .default))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .padding(.top, 2)
            if award > 0 {
                ProgressView(value: progress)
                    .tint(DS.accent)
                    .padding(.top, 6)
                HStack {
                    Text("of \(award.formatted(.currency(code: "USD"))) award")
                        .font(.footnote).foregroundStyle(.secondary)
                    Spacer()
                    if balanceSummary.pendingClaims > 0 {
                        Text("\(balanceSummary.pendingClaims.formatted(.currency(code: "USD"))) pending")
                            .font(.footnote).foregroundStyle(DS.statusWarn)
                    }
                }
            }
        }
        .dsCard(padding: DS.xl)
        .padding(.horizontal, DS.base)
    }

    // MARK: Three quick stats — muted, no color blocks

    private var quickStatGrid: some View {
        let draftCount = myClaims.filter { $0.status == .draft }.count
        let onHoldCount = myClaims.filter { $0.status == .onHold }.count
        let nextDeadline = nextDeadlineDays()
        return HStack(spacing: DS.sm) {
            quickStat(title: "Claims",
                      number: "\(myClaims.count)",
                      sub: onHoldCount > 0 ? "\(onHoldCount) on hold" : (draftCount > 0 ? "\(draftCount) draft" : "all clear"),
                      subTint: onHoldCount > 0 ? DS.statusWarn : .secondary)
            quickStat(title: "Receipts",
                      number: "\(myExpenses.count)",
                      sub: "tracked",
                      subTint: .secondary)
            quickStat(title: "Next cliff",
                      number: nextDeadline.map { "\($0)d" } ?? "—",
                      sub: nextDeadline.map { $0 < 30 ? "approaching" : "in the clear" } ?? "—",
                      subTint: (nextDeadline ?? 99) < 7 ? DS.statusBad : (nextDeadline ?? 99) < 30 ? DS.statusWarn : .secondary)
        }
        .padding(.horizontal, DS.base)
    }

    private func quickStat(title: String, number: String, sub: String, subTint: Color) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(number)
                .font(.title2.weight(.bold))
                .monospacedDigit()
                .foregroundStyle(.primary)
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.primary)
                .padding(.top, 4)
            Text(sub)
                .font(.caption)
                .foregroundStyle(subTint)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.base)
        .background(DS.grouped, in: RoundedRectangle(cornerRadius: DS.cardRadius))
    }

    // MARK: Unclaimed receipts — one-tap auto-group into a claim

    @ViewBuilder
    private var unclaimedReceiptsCard: some View {
        if unclaimedExpenses.count >= 2 {
            VStack(alignment: .leading, spacing: DS.sm) {
                sectionHeader(title: "Submission helper")
                Button {
                    showGroupedClaimConfirm = true
                } label: {
                    HStack(spacing: DS.base) {
                        Image(systemName: "tray.and.arrow.up.fill")
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(DS.accent)
                            .frame(width: 44, height: 44)
                            .background(DS.accentSoft, in: RoundedRectangle(cornerRadius: 12))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("\(unclaimedExpenses.count) receipts ready to submit")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.primary)
                            Text("\(unclaimedTotal.formatted(.currency(code: "USD"))) · tap to group into one claim")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.tertiary)
                    }
                    .padding(DS.base)
                    .background(DS.grouped, in: RoundedRectangle(cornerRadius: DS.cardRadius))
                    .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, DS.lg)
                .confirmationDialog(
                    "Group \(unclaimedExpenses.count) receipts into a new claim?",
                    isPresented: $showGroupedClaimConfirm,
                    titleVisibility: .visible
                ) {
                    Button("Create draft claim") { groupUnclaimedReceipts() }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text("Total \(unclaimedTotal.formatted(.currency(code: "USD"))). You can review and edit before submitting.")
                }
            }
        }
    }

    private func groupUnclaimedReceipts() {
        guard let student = activeStudent else { return }
        let title = "Claim · \(Date.now.formatted(.dateTime.month(.abbreviated).day().year()))"
        let claim = Claim(title: title,
                          status: .draft,
                          createdAt: .now,
                          student: student,
                          expenses: unclaimedExpenses)
        modelContext.insert(claim)
        for expense in unclaimedExpenses {
            expense.claim = claim
        }
        try? modelContext.save()
    }

    // MARK: Upcoming reminders — what was the Recurring Tasks tab, now contextual

    @ViewBuilder
    private var upcomingRemindersCard: some View {
        if !myUpcomingTasks.isEmpty {
            VStack(alignment: .leading, spacing: DS.sm) {
                sectionHeader(title: "Upcoming") {
                    NavigationLink("All") { RecurringTaskListView() }
                        .font(.footnote)
                }
                VStack(spacing: 0) {
                    ForEach(myUpcomingTasks) { task in
                        HStack(spacing: DS.md) {
                            Image(systemName: "bell.badge.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(DS.accent)
                                .frame(width: 32, height: 32)
                                .background(DS.accentSoft, in: RoundedRectangle(cornerRadius: 10))
                            VStack(alignment: .leading, spacing: 1) {
                                Text(task.title).font(.subheadline)
                                Text(task.nextDueDate.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            let days = Calendar.current.dateComponents([.day], from: .now, to: task.nextDueDate).day ?? 0
                            Text("\(days)d")
                                .font(.footnote.weight(.semibold))
                                .monospacedDigit()
                                .foregroundStyle(days < 7 ? DS.statusBad : days < 30 ? DS.statusWarn : .secondary)
                        }
                        .padding(.horizontal, DS.base)
                        .padding(.vertical, DS.md)
                        if task.id != myUpcomingTasks.last?.id {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
                .background(DS.grouped, in: RoundedRectangle(cornerRadius: DS.cardRadius))
                .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
                .padding(.horizontal, DS.lg)
            }
        }
    }

    // MARK: Recent activity — claims + receipts merged

    private var recentActivitySection: some View {
        let combined: [ActivityItem] =
            (myClaims.prefix(3).map { ActivityItem(claim: $0) } +
             myExpenses.prefix(3).map { ActivityItem(expense: $0) })
            .sorted(by: { $0.date > $1.date })
            .prefix(5)
            .map { $0 }

        return VStack(alignment: .leading, spacing: DS.sm) {
            sectionHeader(title: "Recent activity") {
                NavigationLink("See all") { ClaimsBoardView() }
                    .font(.footnote)
            }
            if combined.isEmpty {
                VStack(spacing: DS.sm) {
                    Image(systemName: "tray")
                        .font(.title2)
                        .foregroundStyle(.tertiary)
                    Text("Nothing yet")
                        .font(.subheadline.weight(.semibold))
                    Text("Tap + to scan your first receipt.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, DS.xl)
                .background(DS.grouped, in: RoundedRectangle(cornerRadius: DS.cardRadius))
                .padding(.horizontal, DS.base)
            } else {
                VStack(spacing: 0) {
                    ForEach(combined) { item in
                        activityRow(item)
                        if item.id != combined.last?.id {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
                .background(DS.grouped, in: RoundedRectangle(cornerRadius: DS.cardRadius))
                .padding(.horizontal, DS.base)
            }
        }
    }

    private func activityRow(_ item: ActivityItem) -> some View {
        HStack(spacing: DS.md) {
            Image(systemName: item.symbol)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(item.tint)
                .frame(width: 32, height: 32)
                .background(item.tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 1) {
                Text(item.title).font(.subheadline)
                Text(item.subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, DS.base)
        .padding(.vertical, DS.md)
    }

    // MARK: Key dates

    private var keyDatesSection: some View {
        let items = deadlines()
        guard !items.isEmpty else { return AnyView(EmptyView()) }
        return AnyView(
            VStack(alignment: .leading, spacing: DS.sm) {
                sectionHeader(title: "Key dates", trailing: { EmptyView() })
                VStack(spacing: 0) {
                    ForEach(items, id: \.label) { item in
                        HStack(spacing: DS.md) {
                            Circle()
                                .fill(item.tint)
                                .frame(width: 8, height: 8)
                            VStack(alignment: .leading, spacing: 0) {
                                Text(item.label).font(.subheadline)
                                Text(item.subline).font(.caption).foregroundStyle(.secondary)
                            }
                            Spacer()
                            Text("\(item.daysAway)d")
                                .font(.footnote.weight(.semibold))
                                .monospacedDigit()
                                .foregroundStyle(item.tint)
                        }
                        .padding(.horizontal, DS.base)
                        .padding(.vertical, DS.md)
                        if item.label != items.last?.label {
                            Divider().padding(.leading, DS.base + 8 + DS.md)
                        }
                    }
                }
                .background(DS.grouped, in: RoundedRectangle(cornerRadius: DS.cardRadius))
                .padding(.horizontal, DS.base)
            }
        )
    }

    private var emptyState: some View {
        VStack(spacing: DS.md) {
            Image(systemName: "person.crop.circle.badge.plus")
                .font(.system(size: 44))
                .foregroundStyle(.tertiary)
            Text("Add a student to begin")
                .font(.headline)
            Text("Open Students from the More tab to add your first child.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DS.xl)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.xxxl)
    }

    private func sectionHeader<Trailing: View>(title: String, @ViewBuilder trailing: () -> Trailing = { EmptyView() }) -> some View {
        HStack {
            Text(title)
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .textCase(.uppercase)
            Spacer()
            trailing()
        }
        .padding(.horizontal, DS.base + DS.xs)
        .padding(.top, DS.md)
    }

    // MARK: Deadline math

    private struct DeadlineItem { let label: String; let subline: String; let tint: Color; let daysAway: Int }

    private func deadlines() -> [DeadlineItem] {
        let label = RulesetLoader.shared.schoolYearLabel
        let parts = label.split(separator: "-")
        guard parts.count == 2, let start = Int(parts[0]) else { return [] }
        let endYear = start + 1
        func make(_ m: Int, _ d: Int, _ label: String, _ subline: String) -> DeadlineItem? {
            var c = DateComponents(); c.year = endYear; c.month = m; c.day = d
            guard let date = Calendar.current.date(from: c), date >= .now else { return nil }
            let days = Calendar.current.dateComponents([.day], from: .now, to: date).day ?? 0
            let tint: Color
            switch days {
            case ..<7:  tint = DS.statusBad
            case ..<30: tint = DS.statusWarn
            default:    tint = .secondary
            }
            return DeadlineItem(label: label, subline: subline, tint: tint, daysAway: days)
        }
        return [
            make(5, 29, "Pre-auth cutoff", "May 29 — last day to submit"),
            make(6, 30, "Spend cliff", "June 30 — purchase by"),
            make(7, 31, "Submission cliff", "July 31 — reimbursement deadline")
        ].compactMap { $0 }
    }

    private func nextDeadlineDays() -> Int? {
        deadlines().first?.daysAway
    }
}

// MARK: - Merged activity item

private struct ActivityItem: Identifiable {
    let id: UUID
    let date: Date
    let title: String
    let subtitle: String
    let symbol: String
    let tint: Color

    init(claim: Claim) {
        self.id = claim.id
        self.date = claim.paidDate ?? claim.submittedDate ?? claim.createdAt
        self.title = claim.title.isEmpty ? "Claim" : claim.title
        let total = claim.expenses.reduce(Decimal(0)) { $0 + $1.total }
        let amount = total.formatted(.currency(code: "USD"))
        switch claim.status {
        case .draft:
            self.subtitle = "Draft · \(amount)"
            self.symbol = "tray"
            self.tint = .secondary
        case .readyToSubmit:
            self.subtitle = "Ready to submit · \(amount)"
            self.symbol = "tray.full"
            self.tint = .blue
        case .submitted:
            self.subtitle = "Submitted · \(amount)"
            self.symbol = "paperplane.fill"
            self.tint = DS.accent
        case .onHold:
            self.subtitle = "On hold · \(amount)"
            self.symbol = "exclamationmark.triangle.fill"
            self.tint = DS.statusWarn
        case .approved:
            self.subtitle = "Approved · \(amount)"
            self.symbol = "checkmark.circle.fill"
            self.tint = DS.statusGood
        case .paidReimbursed:
            self.subtitle = "Paid · \(amount)"
            self.symbol = "checkmark.seal.fill"
            self.tint = DS.statusGood
        case .pendingReview:
            self.subtitle = "Pending review · \(amount)"
            self.symbol = "hourglass"
            self.tint = DS.accent
        case .denied:
            self.subtitle = "Denied · \(amount)"
            self.symbol = "xmark.circle.fill"
            self.tint = DS.statusBad
        }
    }

    init(expense: Expense) {
        self.id = expense.id
        self.date = expense.purchaseDate
        self.title = expense.vendorName.isEmpty ? "Receipt" : expense.vendorName
        let cat = expense.categoryKey ?? "Receipt"
        self.subtitle = "\(cat.capitalized) · \(expense.total.formatted(.currency(code: "USD")))"
        self.symbol = "doc.text"
        self.tint = DS.accent
    }
}
