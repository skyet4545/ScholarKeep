import SwiftUI

struct AppLockGate<Content: View>: View {
    @Environment(AppSettings.self) private var settings
    @Environment(\.scenePhase) private var scenePhase

    @State private var isUnlocked = false
    @State private var lastError: String?
    @State private var attempting = false

    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        Group {
            if !settings.appLockEnabled || isUnlocked {
                content()
            } else {
                lockScreen
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .background || phase == .inactive {
                isUnlocked = false
            }
        }
        .task(id: settings.appLockEnabled) {
            if settings.appLockEnabled && !isUnlocked {
                await tryUnlock()
            }
        }
    }

    private var lockScreen: some View {
        VStack(spacing: 20) {
            Image(systemName: "lock.shield")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text("ScholarKeep is locked")
                .font(.title2.weight(.semibold))
            Text("Authenticate with \(AppLockService.biometryDescription()) to continue.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            if let lastError {
                Text(lastError)
                    .font(.footnote)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Button {
                Task { await tryUnlock() }
            } label: {
                Label("Unlock", systemImage: "faceid")
                    .frame(maxWidth: 220)
            }
            .buttonStyle(.borderedProminent)
            .disabled(attempting)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }

    private func tryUnlock() async {
        attempting = true
        defer { attempting = false }
        let result = await AppLockService.authenticate()
        switch result {
        case .success:
            isUnlocked = true
            lastError = nil
        case .userCancelled:
            lastError = nil
        case .unavailable:
            lastError = "Biometrics or passcode are not set up on this device."
            settings.appLockEnabled = false
            isUnlocked = true
        case .failed(let message):
            lastError = message
        }
    }
}
