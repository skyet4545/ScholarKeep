import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.modelContext) private var modelContext

    @State private var showDisclaimer = false
    @State private var lockToggleError: String?

    var body: some View {
        @Bindable var bindableSettings = settings
        NavigationStack {
            Form {
                Section {
                    Toggle(isOn: lockToggleBinding) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Lock with \(AppLockService.biometryDescription())")
                            Text("Require authentication when opening or returning to ScholarKeep.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                    .disabled(!AppLockService.biometryAvailable())
                    if let lockToggleError {
                        Text(lockToggleError)
                            .font(.footnote)
                            .foregroundStyle(.red)
                    }
                } header: {
                    Text("Privacy")
                } footer: {
                    Text("Biometrics or device passcode required. Nothing leaves this device.")
                }

                Section {
                    Toggle(isOn: $bindableSettings.iCloudBackupEnabled) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Back up to iCloud")
                            Text("Preference saved. Full sync arrives in a later milestone.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                } header: {
                    Text("Backup")
                } footer: {
                    Text("Local-first by default. No third-party analytics or trackers — ever.")
                }

                Section("About") {
                    Button("View disclaimer") { showDisclaimer = true }
                    LabeledContent("Version", value: appVersionString)
                    LabeledContent("School year", value: SchoolYear.label())
                }
            }
            .navigationTitle("Settings")
            .sheet(isPresented: $showDisclaimer) {
                NavigationStack {
                    ScrollView {
                        Text(DisclaimerCopy.full(schoolYear: SchoolYear.label()))
                            .font(.callout)
                            .padding(24)
                    }
                    .navigationTitle("Disclaimer")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showDisclaimer = false }
                        }
                    }
                }
            }
        }
    }

    /// Confirms biometrics work before flipping the toggle on.
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
}
