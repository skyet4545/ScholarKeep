import Foundation
import AuthenticationServices
import Observation

/// Account state — what the app knows about the currently-authenticated Apple ID.
enum AuthState: Equatable {
    case unknown          // app just launched, haven't checked yet
    case signedOut        // no user signed in
    case signedIn(SignedInUser)
}

struct SignedInUser: Equatable {
    let userIdentifier: String      // Apple-provided stable ID, unique per app per Apple ID
    let givenName: String?          // only available the FIRST time the user signs in
    let familyName: String?
    let email: String?              // private-relay email if user chose to hide
    let signedInAt: Date
}

/// Source of truth for who's signed in. Persists the Apple `userIdentifier` in
/// UserDefaults so the next app launch can verify the credential is still valid.
@Observable
final class AuthService {
    static let shared = AuthService()

    private let storedUserIdKey = "auth.appleUserId"
    private let storedGivenNameKey = "auth.givenName"
    private let storedFamilyNameKey = "auth.familyName"
    private let storedEmailKey = "auth.email"

    private(set) var state: AuthState = .unknown

    private init() {
        // UI tests run with --reset and need to bypass the sign-in gate.
        if CommandLine.arguments.contains("--reset") || CommandLine.arguments.contains("--skip-auth") {
            let stub = SignedInUser(
                userIdentifier: "ui-test-stub",
                givenName: "Test",
                familyName: "User",
                email: nil,
                signedInAt: .now
            )
            self.state = .signedIn(stub)
            return
        }
        Task { await loadStoredState() }
    }

    /// Called by the app on launch to check that the stored Apple credential
    /// is still valid. Apple revokes the credential if the user disables the
    /// integration in Settings → Apple ID → Password & Security → Sign In with
    /// Apple, or if they delete the Apple ID.
    @MainActor
    func refresh() async {
        await loadStoredState()
    }

    @MainActor
    private func loadStoredState() async {
        let defaults = UserDefaults.standard
        guard let userId = defaults.string(forKey: storedUserIdKey), !userId.isEmpty else {
            state = .signedOut
            return
        }
        // Check Apple's credential state. If still authorized → signed in.
        let provider = ASAuthorizationAppleIDProvider()
        let credentialState: ASAuthorizationAppleIDProvider.CredentialState
        do {
            credentialState = try await provider.credentialState(forUserID: userId)
        } catch {
            credentialState = .notFound
        }
        switch credentialState {
        case .authorized:
            let user = SignedInUser(
                userIdentifier: userId,
                givenName: defaults.string(forKey: storedGivenNameKey),
                familyName: defaults.string(forKey: storedFamilyNameKey),
                email: defaults.string(forKey: storedEmailKey),
                signedInAt: .now
            )
            state = .signedIn(user)
        case .revoked, .notFound, .transferred:
            // Credential is no longer valid — force re-sign-in.
            clearStored()
            state = .signedOut
        @unknown default:
            state = .signedOut
        }
    }

    /// Called by `SignInGate` when Apple returns a successful credential.
    @MainActor
    func handle(credential: ASAuthorizationAppleIDCredential) {
        let defaults = UserDefaults.standard
        defaults.set(credential.user, forKey: storedUserIdKey)
        if let given = credential.fullName?.givenName {
            defaults.set(given, forKey: storedGivenNameKey)
        }
        if let family = credential.fullName?.familyName {
            defaults.set(family, forKey: storedFamilyNameKey)
        }
        if let email = credential.email {
            defaults.set(email, forKey: storedEmailKey)
        }
        let user = SignedInUser(
            userIdentifier: credential.user,
            givenName: credential.fullName?.givenName ?? defaults.string(forKey: storedGivenNameKey),
            familyName: credential.fullName?.familyName ?? defaults.string(forKey: storedFamilyNameKey),
            email: credential.email ?? defaults.string(forKey: storedEmailKey),
            signedInAt: .now
        )
        state = .signedIn(user)
    }

    /// User tapped "Sign out" in Settings. Clears the stored credential but
    /// keeps SwiftData on disk — user can sign back in to access it.
    @MainActor
    func signOut() {
        clearStored()
        state = .signedOut
    }

    private func clearStored() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: storedUserIdKey)
        defaults.removeObject(forKey: storedGivenNameKey)
        defaults.removeObject(forKey: storedFamilyNameKey)
        defaults.removeObject(forKey: storedEmailKey)
    }

    /// True when the current state is signed-in. Used by SignInGate.
    var isSignedIn: Bool {
        if case .signedIn = state { return true }
        return false
    }
}
