import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import UserNotifications

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext

    @Query private var students: [Student]
    @Query private var expenses: [Expense]
    @Query private var claims: [Claim]

    @State private var showDisclaimer = false
    @State private var lockToggleError: String?
    @State private var notificationsEnabled = false
    @State private var exportingAll = false
    @State private var exportURL: URL?
    @State private var exportError: String?
    @State private var showDeleteConfirm = false
    @State private var showDeleteSecondConfirm = false
    @State private var showPaywall = false
    @State private var subs = SubscriptionService.shared

    var body: some View {
        @Bindable var bindableSettings = settings
        NavigationStack {
            Form {
                subscriptionSection
                privacySection
                Section {
                    Toggle(isOn: Binding(
                        get: { bindableSettings.iCloudBackupEnabled && subs.isPro },
                        set: { newValue in
                            if newValue && !subs.isPro {
                                showPaywall = true
                            } else {
                                bindableSettings.iCloudBackupEnabled = newValue
                            }
                        }
                    )) {
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Back up to iCloud")
                                Text("Preference saved. Pro required to enable sync.")
                                    .font(.footnote).foregroundStyle(.secondary)
                            }
                            Spacer()
                            if !subs.isPro {
                                Text("PRO").font(.caption2.bold())
                                    .padding(.horizontal, 6).padding(.vertical, 2)
                                    .background(Color.accentColor, in: Capsule())
                                    .foregroundStyle(.white)
                            }
                        }
                    }
                } header: { Text("Backup") } footer: {
                    Text("Local-first by default. No third-party analytics or trackers — ever.")
                }
                notificationsSection
                rulesetSection
                dataSection
                aboutSection
            }
            .scrollContentBackground(.hidden)
            .background(DS.canvas)
            .navigationTitle("Settings")
            .task {
                let status = await UNUserNotificationCenter.current().notificationSettings().authorizationStatus
                notificationsEnabled = (status == .authorized || status == .provisional)
            }
            .sheet(isPresented: $showDisclaimer) {
                NavigationStack {
                    ScrollView {
                        Text(DisclaimerCopy.full(schoolYear: RulesetLoader.shared.schoolYearLabel))
                            .font(.callout)
                            .padding(24)
                    }
                    .navigationTitle("Disclaimer")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) { Button("Done") { showDisclaimer = false } }
                    }
                }
            }
            .confirmationDialog(
                "Delete all data on this device?",
                isPresented: $showDeleteConfirm,
                titleVisibility: .visible
            ) {
                Button("Continue", role: .destructive) { showDeleteSecondConfirm = true }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("This removes every student, expense, claim, and attachment from this device. It does not affect anything in EMA/SMP.")
            }
            .confirmationDialog(
                "Are you absolutely sure? This can't be undone.",
                isPresented: $showDeleteSecondConfirm,
                titleVisibility: .visible
            ) {
                Button("Delete everything", role: .destructive) { deleteAll() }
                Button("Cancel", role: .cancel) { }
            }
            .paywallSheet(isPresented: $showPaywall)
        }
    }

    private var subscriptionSection: some View {
        Section("Subscription") {
            if subs.isPro {
                Label("Pro is active", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                Link(destination: URL(string: "https://apps.apple.com/account/subscriptions")!) {
                    Label("Manage subscription", systemImage: "arrow.up.right.square")
                }
            } else {
                Button {
                    showPaywall = true
                } label: {
                    Label("Upgrade to Pro", systemImage: "graduationcap.fill")
                        .foregroundStyle(.tint)
                }
            }
        }
    }

    @ViewBuilder
    private var privacySection: some View {
        Section {
            Toggle(isOn: lockToggleBinding) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Lock with \(AppLockService.biometryDescription())")
                    Text("Require authentication when opening or returning.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            .disabled(!AppLockService.biometryAvailable())
            if let lockToggleError {
                Text(lockToggleError).font(.footnote).foregroundStyle(.red)
            }
        } header: { Text("Privacy") } footer: {
            Text("Biometrics or device passcode required. Nothing leaves this device.")
        }
    }

    private var notificationsSection: some View {
        Section {
            Toggle("Reminder notifications", isOn: Binding(
                get: { notificationsEnabled },
                set: { newValue in
                    Task {
                        if newValue {
                            notificationsEnabled = await NotificationsService.requestAuthorizationIfNeeded()
                            if notificationsEnabled {
                                await NotificationsService.scheduleSubmissionDeadline(school: RulesetLoader.shared.schoolYearLabel)
                            }
                        } else {
                            await NotificationsService.cancelAll()
                            notificationsEnabled = false
                        }
                    }
                }
            ))
        } header: { Text("Reminders") } footer: {
            Text("Local reminders for the July 31 deadline, on-hold clocks, and device-window openings. No remote push.")
        }
    }

    @State private var rulesetRefreshing = false
    @State private var rulesetRefreshResult: String?

    private var rulesetSection: some View {
        Section("Ruleset") {
            if let rs = RulesetLoader.shared.ruleset {
                LabeledContent("School year", value: rs.schoolYear)
                LabeledContent("Version", value: rs.sourceVersion)
                LabeledContent("Updated", value: rs.lastUpdated)
                LabeledContent("Source", value: RulesetLoader.shared.lastRefreshSource.rawValue)
                if let when = RulesetLoader.shared.lastRefreshAt {
                    LabeledContent("Last refresh", value: when.formatted(date: .abbreviated, time: .shortened))
                }
            }
            Button {
                refreshRuleset()
            } label: {
                if rulesetRefreshing {
                    HStack { ProgressView(); Text("Checking…") }
                } else {
                    Label("Check for updates", systemImage: "arrow.down.circle")
                }
            }
            .disabled(rulesetRefreshing)
            if let rulesetRefreshResult {
                Text(rulesetRefreshResult).font(.caption).foregroundStyle(.secondary)
            }
            Button("Reset to bundled ruleset") {
                RulesetLoader.shared.clearCache()
                rulesetRefreshResult = "Cache cleared, reloaded bundled."
            }
            .font(.caption)
        }
    }

    private func refreshRuleset() {
        rulesetRefreshing = true
        rulesetRefreshResult = nil
        Task {
            let success = await RulesetLoader.shared.fetchRemote()
            await MainActor.run {
                rulesetRefreshing = false
                rulesetRefreshResult = success
                    ? "Updated from remote."
                    : "No update available (or offline). Using current ruleset."
            }
        }
    }

    private var dataSection: some View {
        Section("Your data") {
            LabeledContent("Students", value: "\(students.count)")
            LabeledContent("Expenses", value: "\(expenses.count)")
            LabeledContent("Claims", value: "\(claims.count)")
            NavigationLink {
                ReportsView()
            } label: {
                Label("Reports & summaries", systemImage: "chart.bar.doc.horizontal")
            }
            Button {
                exportAll()
            } label: {
                if exportingAll {
                    HStack { ProgressView(); Text("Preparing…") }
                } else {
                    Label("Export all expenses (CSV)", systemImage: "square.and.arrow.up")
                }
            }
            .disabled(exportingAll)
            if let exportURL {
                ShareLink(item: exportURL) {
                    Label("Share \(exportURL.lastPathComponent)", systemImage: "square.and.arrow.up.on.square")
                }
            }
            if let exportError {
                Text(exportError).foregroundStyle(.red).font(.caption)
            }
            Button(role: .destructive) {
                showDeleteConfirm = true
            } label: {
                Label("Delete all data on this device", systemImage: "trash")
            }
        }
    }

    @ViewBuilder
    private var aboutSection: some View {
        Section {
            if let feedbackURL = feedbackMailtoURL() {
                Link(destination: feedbackURL) {
                    Label("Send feedback to Carlos", systemImage: "envelope.fill")
                        .foregroundStyle(.tint)
                }
            }
            Button("View disclaimer") { showDisclaimer = true }
            LabeledContent("Version", value: appVersionString)
            if let phone = RulesetLoader.shared.ruleset?.globalRules.stepUpSupportPhone, let url = URL(string: "tel:\(phone.filter { $0.isNumber || $0 == "+" })") {
                Link(destination: url) {
                    LabeledContent("Step Up support", value: phone)
                }
            }
        } header: { Text("About") } footer: {
            Text("Beta: tap “Send feedback” for anything broken, confusing, or missing. One sentence is fine.")
        }
        accountSection
    }

    /// Builds a mailto: URL with a structured body so feedback is easier to triage.
    private func feedbackMailtoURL() -> URL? {
        let to = "carlos.reyesiii@gmail.com"
        let subject = "ScholarKeep feedback — v\(appVersionString)"

        let activeProgram: String = {
            guard let id = settings.activeStudentID,
                  let student = students.first(where: { $0.id == id }) else { return "—" }
            return student.program.shortName
        }()
        let device = UIDevice.current.model
        let osVersion = UIDevice.current.systemVersion
        let stats = "Students: \(students.count) · Expenses: \(expenses.count) · Claims: \(claims.count)"

        let body = """


        ⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯⎯
        (Type your feedback above this line — one sentence is fine.)

        App version: \(appVersionString)
        Device: \(device) · iOS \(osVersion)
        Active program: \(activeProgram)
        \(stats)
        """

        var components = URLComponents()
        components.scheme = "mailto"
        components.path = to
        components.queryItems = [
            URLQueryItem(name: "subject", value: subject),
            URLQueryItem(name: "body", value: body)
        ]
        return components.url
    }

    private var accountSection: some View {
        Section("Account") {
            if case .signedIn(let user) = AuthService.shared.state {
                LabeledContent("Signed in as") {
                    VStack(alignment: .trailing) {
                        if let given = user.givenName, let family = user.familyName {
                            Text("\(given) \(family)").font(.subheadline)
                        }
                        if let email = user.email {
                            Text(email).font(.caption).foregroundStyle(.secondary)
                        } else {
                            Text("Apple ID").font(.caption).foregroundStyle(.secondary)
                        }
                    }
                }
                Button(role: .destructive) {
                    Task { @MainActor in AuthService.shared.signOut() }
                } label: {
                    Label("Sign out", systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        }
    }

    private var lockToggleBinding: Binding<Bool> {
        Binding(
            get: { settings.appLockEnabled },
            set: { newValue in
                if newValue {
                    Task {
                        let result = await AppLockService.authenticate(reason: "Confirm app lock")
                        switch result {
                        case .success:
                            settings.appLockEnabled = true
                            lockToggleError = nil
                        case .unavailable:
                            lockToggleError = "Biometrics or passcode are not set up on this device."
                        case .userCancelled:
                            lockToggleError = nil
                        case .failed(let message):
                            lockToggleError = message
                        }
                    }
                } else {
                    settings.appLockEnabled = false
                    lockToggleError = nil
                }
            }
        )
    }

    private var appVersionString: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        return "\(version) (\(build))"
    }

    private func exportAll() {
        guard subs.isPro else {
            showPaywall = true
            return
        }
        exportingAll = true
        Task {
            do {
                let url = try CSVExportService.exportExpenses(expenses)
                await MainActor.run {
                    self.exportURL = url
                    self.exportError = nil
                    self.exportingAll = false
                }
            } catch {
                await MainActor.run {
                    self.exportError = error.localizedDescription
                    self.exportingAll = false
                }
            }
        }
    }

    private func deleteAll() {
        for c in claims { modelContext.delete(c) }
        for e in expenses { modelContext.delete(e) }
        for s in students { modelContext.delete(s) }
        try? modelContext.save()
        settings.activeStudentID = nil
        Task { await NotificationsService.cancelAll() }
    }
}
