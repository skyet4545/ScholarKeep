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

    var body: some View {
        @Bindable var bindableSettings = settings
        NavigationStack {
            Form {
                privacySection
                Section {
                    Toggle(isOn: $bindableSettings.iCloudBackupEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Back up to iCloud")
                            Text("Preference saved. Full iCloud sync lands in v0.2 once the CloudKit container is provisioned.")
                                .font(.footnote).foregroundStyle(.secondary)
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

    private var rulesetSection: some View {
        Section("Ruleset") {
            if let rs = RulesetLoader.shared.ruleset {
                LabeledContent("School year", value: rs.schoolYear)
                LabeledContent("Version", value: rs.sourceVersion)
                LabeledContent("Updated", value: rs.lastUpdated)
            }
            Button("Re-load bundled ruleset") {
                RulesetLoader.shared.reload()
            }
        }
    }

    private var dataSection: some View {
        Section("Your data") {
            LabeledContent("Students", value: "\(students.count)")
            LabeledContent("Expenses", value: "\(expenses.count)")
            LabeledContent("Claims", value: "\(claims.count)")
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

    private var aboutSection: some View {
        Section("About") {
            Button("View disclaimer") { showDisclaimer = true }
            LabeledContent("Version", value: appVersionString)
            LabeledContent("Today", value: Date().formatted(date: .long, time: .omitted))
            if let phone = RulesetLoader.shared.ruleset?.globalRules.stepUpSupportPhone, let url = URL(string: "tel:\(phone.filter { $0.isNumber || $0 == "+" })") {
                Link(destination: url) {
                    LabeledContent("Step Up support", value: phone)
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
