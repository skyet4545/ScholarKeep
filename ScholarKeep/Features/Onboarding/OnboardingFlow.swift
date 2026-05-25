import SwiftUI
import SwiftData

/// v0.5.1 — Onboarding rewritten in Apple Journal style.
/// Cream canvas, editorial headers, custom cards, no stock iOS Forms.
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
            ZStack {
                DS.canvas.ignoresSafeArea()
                Group {
                    switch step {
                    case .welcome:     welcomeScreen
                    case .howItWorks:  howItWorksScreen
                    case .addStudent:  addStudentScreen
                    case .disclaimer:  disclaimerScreen
                    case .preferences: preferencesScreen
                    }
                }
                .animation(.easeInOut(duration: 0.25), value: step)
            }
        }
    }

    // MARK: 1. Welcome

    private var welcomeScreen: some View {
        VStack(spacing: 0) {
            Spacer()
            VStack(spacing: DS.lg) {
                ZStack {
                    Circle()
                        .fill(DS.accentSoft)
                        .frame(width: 124, height: 124)
                    Image(systemName: "graduationcap.fill")
                        .font(.system(size: 56, weight: .regular))
                        .foregroundStyle(DS.accent)
                }
                VStack(spacing: DS.sm) {
                    Text("Welcome to")
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    Text("ScholarKeep")
                        .font(.system(size: 38, weight: .bold))
                        .tracking(-0.5)
                }
                Text("A private companion for Florida ESA scholarship parents — so you never lose a receipt or miss a deadline.")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.xl)
                    .padding(.top, DS.sm)
            }
            Spacer()
            HStack(spacing: 6) {
                Image(systemName: "lock.shield.fill")
                    .font(.footnote)
                    .foregroundStyle(DS.statusGood)
                Text("Everything stays on your phone")
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, DS.md)
            JournalCTA("Get started") { step = .howItWorks }
                .padding(.horizontal, DS.lg)
                .padding(.bottom, DS.xxxl)
        }
    }

    // MARK: 2. How it works

    private var howItWorksScreen: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.lg) {
                    JournalHeader(eyebrow: "STEP 2 OF 5",
                                  title: "How it works")
                    VStack(spacing: DS.md) {
                        benefitCard(
                            icon: "doc.text.viewfinder",
                            title: "Scan receipts in seconds",
                            body: "Snap one or many at a time — Apple Vision reads the merchant, amount, and date right on your device."
                        )
                        benefitCard(
                            icon: "checkmark.seal.fill",
                            title: "Get a verdict instantly",
                            body: "Tell ScholarKeep what you're buying and it cites the exact Purchasing Guide line that says yes, no, or 'needs pre-auth.'"
                        )
                        benefitCard(
                            icon: "tray.and.arrow.up.fill",
                            title: "Stay submission-ready",
                            body: "Track every claim from draft to paid. Generate a clean PDF package right before the July 31 deadline."
                        )
                    }
                    .padding(.horizontal, DS.lg)
                }
                .padding(.bottom, DS.xxl)
            }
            footerBar(
                back: { step = .welcome },
                primaryLabel: "Next",
                primaryAction: { step = .addStudent },
                primaryEnabled: true
            )
        }
    }

    private func benefitCard(icon: String, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: DS.base) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(DS.accent)
                .frame(width: 44, height: 44)
                .background(DS.accentSoft, in: RoundedRectangle(cornerRadius: 12))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(body).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.lg)
        .background(DS.grouped, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
    }

    // MARK: 3. Add student

    private var addStudentScreen: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.lg) {
                    JournalHeader(eyebrow: "STEP 3 OF 5",
                                  title: "Add your first student",
                                  subtitle: "Just the basics. You can add details later.")

                    VStack(alignment: .leading, spacing: DS.sm) {
                        Text("STUDENT")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .tracking(0.5)
                            .padding(.horizontal, DS.lg + 4)
                        VStack(alignment: .leading, spacing: 0) {
                            journalField(label: "Name", placeholder: "First name or nickname",
                                         text: $draft.displayName)
                        }
                        .background(DS.grouped, in: RoundedRectangle(cornerRadius: DS.cardRadius))
                        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
                        .padding(.horizontal, DS.lg)
                        Text("First name or nickname is fine. You can add a second student later.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, DS.lg + 4)
                    }

                    VStack(alignment: .leading, spacing: DS.sm) {
                        Text("SCHOLARSHIP PROGRAM")
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .tracking(0.5)
                            .padding(.horizontal, DS.lg + 4)
                        VStack(alignment: .leading, spacing: 0) {
                            programPickerRow
                        }
                        .background(DS.grouped, in: RoundedRectangle(cornerRadius: DS.cardRadius))
                        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
                        .padding(.horizontal, DS.lg)
                        Button {
                            showProgramHelp = true
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "questionmark.circle")
                                Text("Not sure which one?")
                            }
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(DS.accent)
                            .padding(.horizontal, DS.lg + 4)
                        }
                    }

                    if draft.program == .pep {
                        slpSection
                    }

                    if let saveError {
                        Text(saveError)
                            .font(.footnote)
                            .foregroundStyle(DS.statusBad)
                            .padding(.horizontal, DS.lg + 4)
                    }
                }
                .padding(.bottom, DS.xxl)
            }
            footerBar(
                back: { step = .howItWorks },
                primaryLabel: "Next",
                primaryAction: { saveStudent() },
                primaryEnabled: draft.isValid
            )
        }
        .sheet(isPresented: $showProgramHelp) {
            ProgramHelpSheet(program: $draft.program)
        }
    }

    private var programPickerRow: some View {
        Menu {
            ForEach(Program.allCases) { p in
                Button {
                    draft.program = p
                } label: {
                    HStack {
                        Text(p.displayName)
                        if draft.program == p { Image(systemName: "checkmark") }
                    }
                }
            }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Program")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(draft.program.displayName)
                        .font(.body)
                        .foregroundStyle(.primary)
                }
                Spacer()
                Image(systemName: "chevron.up.chevron.down")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(DS.base)
        }
    }

    private var slpSection: some View {
        VStack(alignment: .leading, spacing: DS.sm) {
            Text("STUDENT LEARNING PLAN (PEP)")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
                .tracking(0.5)
                .padding(.horizontal, DS.lg + 4)
            VStack(spacing: 0) {
                Toggle(isOn: Binding(
                    get: { draft.slpApprovedDate != nil },
                    set: { newValue in
                        draft.slpApprovedDate = newValue ? (draft.slpApprovedDate ?? .now) : nil
                    }
                )) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("SLP has been approved")
                            .font(.body)
                    }
                }
                .tint(DS.accent)
                .padding(DS.base)

                if let date = draft.slpApprovedDate {
                    Divider().padding(.leading, DS.base)
                    DatePicker("Approved on",
                               selection: Binding(
                                get: { date },
                                set: { draft.slpApprovedDate = $0 }
                               ),
                               displayedComponents: .date)
                        .padding(DS.base)
                }
            }
            .background(DS.grouped, in: RoundedRectangle(cornerRadius: DS.cardRadius))
            .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
            .padding(.horizontal, DS.lg)
            Text("Anything purchased before the SLP is approved is permanently ineligible under PEP. There's no appeals process.")
                .font(.footnote)
                .foregroundStyle(.secondary)
                .padding(.horizontal, DS.lg + 4)
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

    // MARK: 4. Disclaimer

    private var disclaimerScreen: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.lg) {
                    JournalHeader(eyebrow: "STEP 4 OF 5",
                                  title: "Two things to know")

                    VStack(spacing: DS.md) {
                        factCard(
                            icon: "person.slash.fill",
                            tint: DS.statusWarn,
                            title: "We're not Step Up, AAA, or the state",
                            body: "ScholarKeep is an independent app. It doesn't connect to EMA, SMP, MyScholarShop, Tipalti, or any official portal. You still submit your claims yourself."
                        )
                        factCard(
                            icon: "scope",
                            tint: DS.accent,
                            title: "Verdicts are educated estimates",
                            body: "We mirror the official Purchasing Guide as closely as we can, but rules change every year and your SFO has the final say. Always double-check the guide before big purchases."
                        )
                    }
                    .padding(.horizontal, DS.lg)

                    DisclosureGroup {
                        Text(DisclaimerCopy.full(schoolYear: SchoolYear.label()))
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                            .padding(.top, DS.sm)
                    } label: {
                        HStack(spacing: DS.sm) {
                            Image(systemName: "doc.text")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(.secondary)
                            Text("Read the full disclosure")
                                .font(.subheadline.weight(.semibold))
                        }
                    }
                    .padding(DS.base)
                    .background(DS.grouped, in: RoundedRectangle(cornerRadius: DS.cardRadius))
                    .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
                    .padding(.horizontal, DS.lg)
                }
                .padding(.bottom, DS.xxl)
            }
            footerBar(
                back: { step = .addStudent },
                primaryLabel: "I understand — continue",
                primaryAction: { step = .preferences },
                primaryEnabled: true
            )
        }
    }

    private func factCard(icon: String, tint: Color, title: String, body: String) -> some View {
        HStack(alignment: .top, spacing: DS.base) {
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(tint)
                .frame(width: 36, height: 36)
                .background(tint.opacity(0.14), in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(body).font(.subheadline).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.lg)
        .background(DS.grouped, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
    }

    // MARK: 5. Preferences

    private var preferencesScreen: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.lg) {
                    JournalHeader(eyebrow: "STEP 5 OF 5",
                                  title: "A few preferences",
                                  subtitle: "All optional. Change anytime in Settings.")

                    preferenceCard(
                        title: "Lock with \(AppLockService.biometryDescription())",
                        subtitle: AppLockService.biometryAvailable()
                            ? "Recommended if your phone is shared."
                            : "Set up a device passcode in Settings to enable.",
                        isOn: $enableAppLock,
                        disabled: !AppLockService.biometryAvailable()
                    )
                    preferenceCard(
                        title: "Deadline reminders",
                        subtitle: "Local notifications for the July 31 cutoff, pre-auth windows, and on-hold clocks.",
                        isOn: $enableNotifications,
                        disabled: false
                    )
                    preferenceCard(
                        title: "Back up to iCloud",
                        subtitle: "Off by default. Saves preference; sync ships in a later release.",
                        isOn: $enableICloud,
                        disabled: false
                    )
                }
                .padding(.bottom, DS.xxl)
            }
            footerBar(
                back: { step = .disclaimer },
                primaryLabel: "Finish",
                primaryAction: { finishOnboarding() },
                primaryEnabled: true
            )
        }
    }

    private func preferenceCard(title: String, subtitle: String, isOn: Binding<Bool>, disabled: Bool) -> some View {
        HStack(alignment: .center, spacing: DS.base) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body.weight(.semibold))
                Text(subtitle).font(.footnote).foregroundStyle(.secondary)
            }
            Spacer()
            Toggle("", isOn: isOn)
                .labelsHidden()
                .tint(DS.accent)
                .disabled(disabled)
        }
        .padding(DS.lg)
        .background(DS.grouped, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
        .padding(.horizontal, DS.lg)
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

    // MARK: Shared helpers

    private func journalField(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            TextField(placeholder, text: text)
                .font(.body)
                .textContentType(.name)
                .textInputAutocapitalization(.words)
                .accessibilityIdentifier("Student name")
        }
        .padding(DS.base)
    }

    @ViewBuilder
    private func footerBar(back: @escaping () -> Void,
                           primaryLabel: String,
                           primaryAction: @escaping () -> Void,
                           primaryEnabled: Bool) -> some View {
        VStack(spacing: 0) {
            Divider()
                .opacity(0.4)
            HStack(spacing: DS.base) {
                Button("Back", action: back)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .padding(.vertical, 14)
                    .padding(.horizontal, 8)
                Spacer()
                JournalCTA(primaryLabel, isDisabled: !primaryEnabled, action: primaryAction)
                    .frame(maxWidth: 240)
            }
            .padding(.horizontal, DS.lg)
            .padding(.vertical, DS.sm)
            .padding(.bottom, DS.xs)
        }
        .background(.ultraThinMaterial)
    }
}
