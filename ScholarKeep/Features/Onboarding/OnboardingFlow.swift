import SwiftUI
import SwiftData

struct OnboardingFlow: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(AppSettings.self) private var settings

    @State private var step: Step = .welcome
    @State private var draft = StudentFormDraft()
    @State private var enableAppLock = false
    @State private var enableICloud = false
    @State private var enableNotifications = true
    @State private var saveError: String?
    @State private var showProgramHelp = false

    enum Step: Int, CaseIterable {
        case welcome, howItWorks, addStudent, disclaimer, preferences
    }

    var body: some View {
        NavigationStack {
            Group {
                switch step {
                case .welcome:     welcomeScreen
                case .howItWorks:  howItWorksScreen
                case .addStudent:  addStudentScreen
                case .disclaimer:  disclaimerScreen
                case .preferences: preferencesScreen
                }
            }
            .animation(.default, value: step)
        }
    }

    // MARK: 1. Welcome — value prop + trust signal

    private var welcomeScreen: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "graduationcap.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            VStack(spacing: 10) {
                Text("Welcome to ScholarKeep")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)
                Text("A private companion for Florida ESA scholarship parents — built so you never lose a receipt or miss a deadline.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }
            HStack(spacing: 6) {
                Image(systemName: "lock.shield.fill")
                    .foregroundStyle(.green)
                Text("Everything stays on your phone")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 4)
            Spacer()
            Button {
                step = .howItWorks
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

    // MARK: 2. How it works — three benefit cards

    private var howItWorksScreen: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("How ScholarKeep works")
                        .font(.title2.bold())
                        .padding(.bottom, 4)
                    benefitCard(
                        icon: "doc.text.viewfinder",
                        title: "Scan receipts in seconds",
                        body: "Snap one or multiple receipts at a time — Apple Vision reads the merchant, amount, and date right on your device."
                    )
                    benefitCard(
                        icon: "checkmark.seal.fill",
                        title: "Get a verdict instantly",
                        body: "Tell ScholarKeep what you're buying and it'll cite the exact line of the official Purchasing Guide that says yes, no, or 'needs pre-auth'."
                    )
                    benefitCard(
                        icon: "tray.and.arrow.up.fill",
                        title: "Stay submission-ready",
                        body: "Track every claim from draft to paid. Generate a clean PDF package right before the July 31 deadline."
                    )
                }
                .padding(24)
            }
            navFooter(
                back: { step = .welcome },
                primary: ("Next", { step = .addStudent })
            )
        }
        .navigationTitle("How it works")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func benefitCard(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(.tint)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(body).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: 3. Add first student — name + program only (SLP if PEP)

    private var addStudentScreen: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    TextField("Student name", text: $draft.displayName)
                        .textContentType(.name)
                        .textInputAutocapitalization(.words)
                } header: {
                    Text("Student")
                } footer: {
                    Text("First name or nickname is fine. You can add a second student later.")
                }

                Section {
                    Picker("Program", selection: $draft.program) {
                        ForEach(Program.allCases) { p in
                            Text(p.displayName).tag(p)
                        }
                    }
                    Button {
                        showProgramHelp = true
                    } label: {
                        Label("Not sure which one?", systemImage: "questionmark.circle")
                            .font(.subheadline)
                    }
                } header: {
                    Text("Scholarship program")
                }

                if draft.program == .pep {
                    Section {
                        Toggle("SLP has been approved", isOn: Binding(
                            get: { draft.slpApprovedDate != nil },
                            set: { newValue in
                                draft.slpApprovedDate = newValue ? (draft.slpApprovedDate ?? .now) : nil
                            }
                        ))
                        if let date = draft.slpApprovedDate {
                            DatePicker("Approved on",
                                       selection: Binding(
                                        get: { date },
                                        set: { draft.slpApprovedDate = $0 }
                                       ),
                                       displayedComponents: .date)
                        }
                    } header: {
                        Text("Student Learning Plan (PEP)")
                    } footer: {
                        Text("Anything purchased before the SLP is approved is permanently ineligible under PEP. There's no appeals process.")
                    }
                }

                Section {
                    Text("You can add award amount, county, grade level, and notes later from the student detail screen.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            if let saveError {
                Text(saveError)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .padding(.horizontal, 24)
            }
            navFooter(
                back: { step = .howItWorks },
                primary: ("Next", { saveStudent() }),
                primaryEnabled: draft.isValid
            )
        }
        .navigationTitle("Add your first student")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showProgramHelp) {
            ProgramHelpSheet(program: $draft.program)
        }
    }

    private func saveStudent() {
        let student = draft.newStudent()
        modelContext.insert(student)
        do {
            try modelContext.save()
            settings.activeStudentID = student.id
            saveError = nil
            step = .disclaimer
        } catch {
            saveError = "Couldn't save: \(error.localizedDescription)"
        }
    }

    // MARK: 4. Disclaimer — scannable bullets + full text disclosure

    private var disclaimerScreen: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Two things to know before you go")
                        .font(.title2.bold())

                    factCard(
                        icon: "person.slash.fill",
                        tint: .orange,
                        title: "We're not Step Up, AAA, or the state",
                        body: "ScholarKeep is an independent app. It doesn't connect to EMA, SMP, MyScholarShop, Tipalti, or any official portal. You still submit your claims yourself."
                    )

                    factCard(
                        icon: "scope",
                        tint: .blue,
                        title: "Verdicts are educated estimates",
                        body: "We mirror the official Purchasing Guide as closely as we can, but rules change every year and your SFO has final say. Always double-check the guide before big purchases."
                    )

                    DisclosureGroup {
                        Text(DisclaimerCopy.full(schoolYear: SchoolYear.label()))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, 8)
                    } label: {
                        Label("Read the full disclosure", systemImage: "doc.text")
                            .font(.subheadline.weight(.semibold))
                    }
                    .padding(12)
                    .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                }
                .padding(24)
            }
            navFooter(
                back: { step = .addStudent },
                primary: ("I understand — continue", { step = .preferences })
            )
        }
        .navigationTitle("Disclaimer")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func factCard(icon: String, tint: Color, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(tint)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(body).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(tint.opacity(0.1), in: RoundedRectangle(cornerRadius: 14))
    }

    // MARK: 5. Permissions — all optional, skippable

    private var preferencesScreen: some View {
        VStack(spacing: 0) {
            Form {
                Section {
                    Toggle(isOn: $enableAppLock) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Lock with \(AppLockService.biometryDescription())")
                            Text("Require authentication when you open ScholarKeep.")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                    .disabled(!AppLockService.biometryAvailable())
                } header: {
                    Text("Privacy")
                } footer: {
                    if AppLockService.biometryAvailable() {
                        Text("Recommended if your phone is shared.")
                    } else {
                        Text("Set up a device passcode in Settings to enable app lock.")
                    }
                }

                Section {
                    Toggle(isOn: $enableNotifications) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Deadline reminders")
                            Text("July 31 cutoff, pre-auth windows, and on-hold clocks.")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Reminders")
                } footer: {
                    Text("Local notifications only — never sent to a server.")
                }

                Section {
                    Toggle(isOn: $enableICloud) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Back up to iCloud")
                            Text("Off by default. Saves your preference; sync ships in a later release.")
                                .font(.footnote).foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Backup")
                } footer: {
                    Text("All three of these are optional. You can change them anytime in Settings.")
                }
            }
            navFooter(
                back: { step = .disclaimer },
                primary: ("Finish", { finishOnboarding() })
            )
        }
        .navigationTitle("A few preferences")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func finishOnboarding() {
        settings.appLockEnabled = enableAppLock
        settings.iCloudBackupEnabled = enableICloud
        settings.hasCompletedOnboarding = true
        if enableNotifications {
            Task {
                if await NotificationsService.requestAuthorizationIfNeeded() {
                    await NotificationsService.scheduleSubmissionDeadline(school: RulesetLoader.shared.schoolYearLabel)
                }
            }
        }
    }

    // MARK: Shared nav footer

    @ViewBuilder
    private func navFooter(back: @escaping () -> Void, primary: (String, () -> Void), primaryEnabled: Bool = true) -> some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                Button("Back", action: back)
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                Spacer()
                Button {
                    primary.1()
                } label: {
                    Text(primary.0)
                        .frame(minWidth: 140)
                }
                .buttonStyle(.borderedProminent)
                .disabled(!primaryEnabled)
            }
            .padding(20)
        }
        .background(.regularMaterial)
    }
}
