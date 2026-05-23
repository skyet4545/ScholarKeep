import SwiftUI
import AuthenticationServices

struct SignInGate<Content: View>: View {
    @State private var auth = AuthService.shared
    @State private var signInError: String?

    let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        Group {
            switch auth.state {
            case .signedIn:
                content()
            case .signedOut:
                signInScreen
            case .unknown:
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .task { await auth.refresh() }
    }

    private var signInScreen: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "graduationcap.fill")
                .font(.system(size: 64))
                .foregroundStyle(.tint)
            Text("Sign in to ScholarKeep")
                .font(.title2.weight(.semibold))
            Text("Your records stay on this device. Sign in with Apple gates access so a lost phone doesn't expose your child's expenses.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
            SignInWithAppleButton(.signIn) { request in
                request.requestedScopes = [.fullName, .email]
            } onCompletion: { result in
                switch result {
                case .success(let auth):
                    if let credential = auth.credential as? ASAuthorizationAppleIDCredential {
                        AuthService.shared.handle(credential: credential)
                        signInError = nil
                    } else {
                        signInError = "Unexpected credential type."
                    }
                case .failure(let error):
                    if (error as NSError).code == ASAuthorizationError.canceled.rawValue {
                        signInError = nil
                    } else {
                        signInError = error.localizedDescription
                    }
                }
            }
            .signInWithAppleButtonStyle(.black)
            .frame(maxWidth: 320, minHeight: 48)
            if let signInError {
                Text(signInError)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }
            Text("Signing in does not share your records with Apple, Step Up, AAA, or anyone else. Your data stays on this device.")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer().frame(height: 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
}
