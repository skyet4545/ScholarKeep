import AuthenticationServices
import CryptoKit
import Foundation
import Observation
import UIKit

enum GoogleOAuthError: LocalizedError {
    case notConfigured
    case invalidAuthorizationResponse
    case stateMismatch
    case missingAuthorizationCode
    case tokenExchangeFailed(String)
    case noRefreshToken
    case presentationUnavailable

    var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Gmail connection is not configured in this build."
        case .invalidAuthorizationResponse:
            return "Google returned an invalid authorization response."
        case .stateMismatch:
            return "The Google sign-in response could not be verified."
        case .missingAuthorizationCode:
            return "Google did not return an authorization code."
        case .tokenExchangeFailed(let detail):
            return "Google authorization failed. \(detail)"
        case .noRefreshToken:
            return "Your Gmail connection expired. Please reconnect it."
        case .presentationUnavailable:
            return "ScholarKeep could not open the Google sign-in window."
        }
    }
}

struct GoogleOAuthTokenSet: Codable {
    var accessToken: String
    var refreshToken: String?
    var expiresAt: Date
    var scope: String

    var needsRefresh: Bool {
        expiresAt <= Date().addingTimeInterval(120)
    }
}

@MainActor
@Observable
final class GoogleOAuthService: NSObject {
    static let shared = GoogleOAuthService()

    private let keychainService = "com.carlosreyes.scholarkeep.google-oauth"
    private let keychainAccount = "gmail"
    private let accountEmailKey = "gmail.connectedEmail"
    private let redirectURI = "com.carlosreyes.scholarkeep:/oauth2redirect"
    private let callbackScheme = "com.carlosreyes.scholarkeep"
    private let scope = "https://www.googleapis.com/auth/gmail.readonly"

    private var webSession: ASWebAuthenticationSession?
    private let presentationProvider = OAuthPresentationContextProvider()

    private(set) var connectedEmail: String?
    private(set) var isAuthorizing = false
    private(set) var lastError: String?

    override private init() {
        connectedEmail = UserDefaults.standard.string(forKey: accountEmailKey)
        super.init()
    }

    var clientID: String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: "SCHOLARKEEP_GOOGLE_CLIENT_ID") as? String,
              !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              !value.contains("$(")
        else { return nil }
        return value
    }

    var isConfigured: Bool { clientID != nil }

    var isConnected: Bool {
        guard connectedEmail != nil else { return false }
        return (try? loadTokens()) != nil
    }

    func connect() async throws {
        guard let clientID else { throw GoogleOAuthError.notConfigured }
        isAuthorizing = true
        lastError = nil
        defer { isAuthorizing = false }

        do {
            let verifier = Self.randomURLSafeString(byteCount: 48)
            let challenge = Self.base64URL(Data(SHA256.hash(data: Data(verifier.utf8))))
            let state = Self.randomURLSafeString(byteCount: 24)
            var components = URLComponents(string: "https://accounts.google.com/o/oauth2/v2/auth")!
            components.queryItems = [
                URLQueryItem(name: "client_id", value: clientID),
                URLQueryItem(name: "redirect_uri", value: redirectURI),
                URLQueryItem(name: "response_type", value: "code"),
                URLQueryItem(name: "scope", value: scope),
                URLQueryItem(name: "access_type", value: "offline"),
                URLQueryItem(name: "include_granted_scopes", value: "true"),
                URLQueryItem(name: "prompt", value: "consent"),
                URLQueryItem(name: "code_challenge", value: challenge),
                URLQueryItem(name: "code_challenge_method", value: "S256"),
                URLQueryItem(name: "state", value: state)
            ]
            guard let authorizationURL = components.url else {
                throw GoogleOAuthError.invalidAuthorizationResponse
            }

            let callbackURL = try await authorize(url: authorizationURL)
            guard let callback = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false) else {
                throw GoogleOAuthError.invalidAuthorizationResponse
            }
            let values = Dictionary(
                uniqueKeysWithValues: (callback.queryItems ?? []).map { ($0.name, $0.value ?? "") }
            )
            guard values["state"] == state else { throw GoogleOAuthError.stateMismatch }
            if let error = values["error"] {
                throw GoogleOAuthError.tokenExchangeFailed(error)
            }
            guard let code = values["code"], !code.isEmpty else {
                throw GoogleOAuthError.missingAuthorizationCode
            }

            let tokens = try await exchangeCode(code, verifier: verifier, clientID: clientID)
            try saveTokens(tokens)
            let profile = try await GmailAPIClient(accessTokenProvider: { [weak self] in
                guard let self else { throw GoogleOAuthError.noRefreshToken }
                return try await self.validAccessToken()
            }).profile()
            connectedEmail = profile.emailAddress
            UserDefaults.standard.set(profile.emailAddress, forKey: accountEmailKey)
        } catch {
            lastError = error.localizedDescription
            throw error
        }
    }

    func disconnect() async {
        if let tokens = try? loadTokens() {
            let token = tokens.refreshToken ?? tokens.accessToken
            if let url = URL(string: "https://oauth2.googleapis.com/revoke?token=\(token.urlQueryEncoded)") {
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                _ = try? await URLSession.shared.data(for: request)
            }
        }
        try? KeychainStore.delete(account: keychainAccount, service: keychainService)
        UserDefaults.standard.removeObject(forKey: accountEmailKey)
        connectedEmail = nil
        lastError = nil
    }

    func validAccessToken() async throws -> String {
        var tokens = try loadTokens()
        guard tokens.needsRefresh else { return tokens.accessToken }
        guard let clientID else { throw GoogleOAuthError.notConfigured }
        guard let refreshToken = tokens.refreshToken, !refreshToken.isEmpty else {
            throw GoogleOAuthError.noRefreshToken
        }
        let refreshed = try await refresh(refreshToken: refreshToken, clientID: clientID)
        tokens.accessToken = refreshed.accessToken
        tokens.expiresAt = refreshed.expiresAt
        if !refreshed.scope.isEmpty { tokens.scope = refreshed.scope }
        try saveTokens(tokens)
        return tokens.accessToken
    }

    private func authorize(url: URL) async throws -> URL {
        try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: callbackScheme
            ) { [weak self] callbackURL, error in
                self?.webSession = nil
                if let error {
                    continuation.resume(throwing: error)
                } else if let callbackURL {
                    continuation.resume(returning: callbackURL)
                } else {
                    continuation.resume(throwing: GoogleOAuthError.invalidAuthorizationResponse)
                }
            }
            session.presentationContextProvider = presentationProvider
            session.prefersEphemeralWebBrowserSession = false
            webSession = session
            guard session.start() else {
                webSession = nil
                continuation.resume(throwing: GoogleOAuthError.presentationUnavailable)
                return
            }
        }
    }

    private func exchangeCode(
        _ code: String,
        verifier: String,
        clientID: String
    ) async throws -> GoogleOAuthTokenSet {
        let values = [
            "client_id": clientID,
            "code": code,
            "code_verifier": verifier,
            "grant_type": "authorization_code",
            "redirect_uri": redirectURI
        ]
        return try await requestTokens(values: values)
    }

    private func refresh(refreshToken: String, clientID: String) async throws -> GoogleOAuthTokenSet {
        let values = [
            "client_id": clientID,
            "refresh_token": refreshToken,
            "grant_type": "refresh_token"
        ]
        return try await requestTokens(values: values)
    }

    private func requestTokens(values: [String: String]) async throws -> GoogleOAuthTokenSet {
        var request = URLRequest(url: URL(string: "https://oauth2.googleapis.com/token")!)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        var form = URLComponents()
        form.queryItems = values.map { URLQueryItem(name: $0.key, value: $0.value) }
        request.httpBody = form.percentEncodedQuery?.data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse, (200..<300).contains(http.statusCode) else {
            let detail = (try? JSONDecoder().decode(OAuthErrorResponse.self, from: data).errorDescription)
                ?? String(data: data, encoding: .utf8)
                ?? "Token endpoint rejected the request."
            throw GoogleOAuthError.tokenExchangeFailed(detail)
        }
        let payload = try JSONDecoder().decode(OAuthTokenResponse.self, from: data)
        return GoogleOAuthTokenSet(
            accessToken: payload.accessToken,
            refreshToken: payload.refreshToken,
            expiresAt: Date().addingTimeInterval(TimeInterval(payload.expiresIn)),
            scope: payload.scope ?? scope
        )
    }

    private func loadTokens() throws -> GoogleOAuthTokenSet {
        guard let data = try KeychainStore.data(for: keychainAccount, service: keychainService),
              let value = try? JSONDecoder().decode(GoogleOAuthTokenSet.self, from: data)
        else { throw GoogleOAuthError.noRefreshToken }
        return value
    }

    private func saveTokens(_ tokens: GoogleOAuthTokenSet) throws {
        let data = try JSONEncoder().encode(tokens)
        try KeychainStore.set(data, for: keychainAccount, service: keychainService)
    }

    static func randomURLSafeString(byteCount: Int) -> String {
        var bytes = [UInt8](repeating: 0, count: byteCount)
        let status = SecRandomCopyBytes(kSecRandomDefault, byteCount, &bytes)
        precondition(status == errSecSuccess)
        return base64URL(Data(bytes))
    }

    static func base64URL(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }
}

private final class OAuthPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        let scenes = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
        return scenes.flatMap(\.windows).first(where: \.isKeyWindow) ?? ASPresentationAnchor()
    }
}

private struct OAuthTokenResponse: Decodable {
    let accessToken: String
    let expiresIn: Int
    let refreshToken: String?
    let scope: String?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case scope
    }
}

private struct OAuthErrorResponse: Decodable {
    let errorDescription: String?

    enum CodingKeys: String, CodingKey {
        case errorDescription = "error_description"
    }
}

private extension String {
    var urlQueryEncoded: String {
        addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? self
    }
}
