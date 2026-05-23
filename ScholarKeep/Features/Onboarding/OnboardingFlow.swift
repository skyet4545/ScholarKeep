import SwiftUI
import SwiftData

struct OnboardingFlow: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings

    @State private var step: Step = .welcome
    @State private var draft = StudentFormDraft()
    @State private var enableAppLock = false
    @State private var enableICloud = false
    @State private var saveError: String?

    enum Step: Int, CaseIterable {
        case welcome, disclaimer, addStudent, preferences
    }

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .welcome:     welcomeScreen
                case .disclaimer:  disclaimerScreen
                case .addStudent:  addStudentScreen
                case .preferences: preferencesScreen
                }
            }
            .animation(.default, value: step)
        }
    }

    // MARK: Welcome

    private var welcomeScreen: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "graduationcap.fill")
                .font(.system(size: 72))
                .foregroundStyle(.tint)
            Text("Welcome to ScholarKeep")
                .font(.largeTitle.bold())
                .multilineTextAlignment(.center)
            Text("A private companion for tracking Florida ESA receipts, eligibility, and reimbursements — built for parents who do the paperwork themselves.")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)
            Spacer()
            Button {
                step = .disclaimer
            } label: {
                Text("Get started")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: Disclaimer (§16 verbatim)

    private var disclaimerScreen: some View {
        VStack(alignment: .leading, spacing: 16) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Important: read before continuing")
                        .font(.title2.bold())
                    Text(DisclaimerCopy.full(schoolYear: SchoolYear.label()))
                        .font(.callout)
                    Divider()
                    Label("Statuses, balances, and submissions are tracked manually. ScholarKeep does not talk to EMA, SMP, MyScholarShop, Step Up, or AAA.", systemImage: "info.circle")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .padding(24)
            }
            VStack(spacing: 12) {
                Button {
                    step = .addStudent
                } label: {
                    Text("I understand — continue")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                Button("Back") { step = .welcome }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .navigationTitle("Disclaimer")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: Add first student

    private var addStudentScreen: some View {
        VStack(spacing: 0) {
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
                    .padding(.horizontal, 24)
            }
            HStack {
                Button("Back") { step = .disclaimer }
                Spacer()
                Button {
                    saveStudent()
                } label: {
                    Text("Next")
                        .frame(minWidth: 100)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!draft.isValid)
            }
            .padding(24)
        }
        .navigationTitle("Add your first student")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func saveStudent() {
        let student = draft.newStudent()
        modelContext.insert(student)
        do {
            try modelContext.save()
            settings.activeStudentID = student.id
            saveError = nil
            step = .preferences
        } catch {
            saveError = "Couldn't save: \(error.localizedDescription)"
        }
    }

    // MARK: Preferences (Face ID + iCloud)

    private var preferencesScreen: some View {
        Form {
            Section {
                Toggle(isOn: $enableAppLock) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Lock with \(AppLockService.biometryDescription())")
                        Text("Require authentication every time ScholarKeep opens.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .disabled(!AppLockService.biometryAvailable())
            } header: {
                Text("Privacy")
            } footer: {
                if !AppLockService.biometryAvailable() {
                    Text("Set up a device passcode in Settings to enable app lock.")
                }
            }

            Section {
                Toggle(isOn: $enableICloud) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Back up to iCloud")
                        Text("Off by default. Full iCloud sync arrives in a later release; this saves your preference.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
            } header: {
                Text("Backup")
            } footer: {
                Text("Your data stays on this device unless you turn this on. ScholarKeep has no servers and no third-party trackers.")
            }

            Section {
                Button {
                    finishOnboarding()
                } label: {
                    Text("Finish")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
            }
        }
        .navigationTitle("A few preferences")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func finishOnboarding() {
        settings.appLockEnabled = enableAppLock
        settings.iCloudBackupEnabled = enableICloud
        settings.hasCompletedOnboarding = true
        // Schedule deadline reminders silently if user has notifications on.
        Task {
            if await NotificationsService.requestAuthorizationIfNeeded() {
                await NotificationsService.scheduleSubmissionDeadline(school: RulesetLoader.shared.schoolYearLabel)
            }
        }
    }
}
