//
//  OAuthFlowCoordinator.swift
//  Claude Usage
//
//  Generic PKCE-based OAuth flow using ASWebAuthenticationSession.
//

import AuthenticationServices
import CryptoKit
import Foundation

/// Protocol for provider-specific OAuth configuration
protocol OAuthProviderConfiguration {
    var provider: AIProvider { get }
    var authorizationEndpoint: URL { get }
    var tokenEndpoint: URL { get }
    var scopes: [String] { get }
    var clientId: String { get }
    var redirectUri: String { get }
}

/// Coordinates the OAuth login flow for a provider
@MainActor
final class OAuthFlowCoordinator: NSObject {
    static let shared = OAuthFlowCoordinator()

    private var authSession: ASWebAuthenticationSession?
    private var pendingCompletion: ((Result<OAuthToken, Error>) -> Void)?
    private var currentState: String?
    private var currentCodeVerifier: String?

    private override init() {
        super.init()
    }

    // MARK: - Public API

    /// Starts an OAuth login flow for the given provider configuration
    func startLogin(
        configuration: OAuthProviderConfiguration,
        profileId: UUID,
        completion: @escaping (Result<OAuthToken, Error>) -> Void
    ) {
        guard configuration.provider.supportsOAuth else {
            completion(.failure(OAuthError.unsupportedProvider))
            return
        }

        // Generate PKCE parameters
        guard let codeVerifier = generateCodeVerifier(),
              let codeChallenge = generateCodeChallenge(verifier: codeVerifier) else {
            completion(.failure(OAuthError.pkceGenerationFailed))
            return
        }

        let state = generateState()
        currentState = state
        currentCodeVerifier = codeVerifier
        pendingCompletion = completion

        // Build authorization URL
        var components = URLComponents(url: configuration.authorizationEndpoint, resolvingAgainstBaseURL: false)!
        var queryItems = [
            URLQueryItem(name: "client_id", value: configuration.clientId),
            URLQueryItem(name: "redirect_uri", value: configuration.redirectUri),
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "scope", value: configuration.scopes.joined(separator: " ")),
            URLQueryItem(name: "state", value: state),
            URLQueryItem(name: "code_challenge", value: codeChallenge),
            URLQueryItem(name: "code_challenge_method", value: "S256")
        ]

        // Google-specific: request offline access for refresh tokens
        if configuration.provider == .gemini {
            queryItems.append(URLQueryItem(name: "access_type", value: "offline"))
            queryItems.append(URLQueryItem(name: "prompt", value: "consent"))
        }

        components.queryItems = queryItems

        guard let authURL = components.url else {
            completion(.failure(OAuthError.invalidCallbackURL))
            return
        }

        // Create and start ASWebAuthenticationSession
        let session = ASWebAuthenticationSession(
            url: authURL,
            callbackURLScheme: callbackScheme(for: configuration.redirectUri)
        ) { [weak self] callbackURL, error in
            Task { @MainActor in
                self?.handleCallback(
                    callbackURL: callbackURL,
                    error: error,
                    configuration: configuration,
                    profileId: profileId
                )
            }
        }

        session.presentationContextProvider = self
        session.prefersEphemeralWebBrowserSession = false

        self.authSession = session
        session.start()

        LoggingService.shared.log("OAuthFlow: Started login for \(configuration.provider.displayName)")
    }

    /// Refreshes an OAuth token using its refresh token
    func refreshToken(
        _ token: OAuthToken,
        configuration: OAuthProviderConfiguration,
        completion: @escaping (Result<OAuthToken, Error>) -> Void
    ) {
        guard let refreshToken = token.refreshToken else {
            completion(.failure(OAuthError.noRefreshToken))
            return
        }

        var request = URLRequest(url: configuration.tokenEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var bodyComponents = URLComponents()
        bodyComponents.queryItems = [
            URLQueryItem(name: "grant_type", value: "refresh_token"),
            URLQueryItem(name: "refresh_token", value: refreshToken),
            URLQueryItem(name: "client_id", value: configuration.clientId)
        ]

        request.httpBody = bodyComponents.query?.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            Task { @MainActor in
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let data = data,
                      let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    completion(.failure(OAuthError.tokenExchangeFailed("Refresh failed")))
                    return
                }

                do {
                    let newToken = try self?.parseTokenResponse(
                        data: data,
                        provider: token.provider,
                        profileId: token.profileId,
                        existingRefreshToken: refreshToken
                    )
                    if let newToken = newToken {
                        try OAuthTokenStore.shared.update(newToken)
                        completion(.success(newToken))
                    } else {
                        completion(.failure(OAuthError.tokenExchangeFailed("Invalid response")))
                    }
                } catch {
                    completion(.failure(error))
                }
            }
        }.resume()
    }

    // MARK: - Private

    private func handleCallback(
        callbackURL: URL?,
        error: Error?,
        configuration: OAuthProviderConfiguration,
        profileId: UUID
    ) {
        defer {
            authSession = nil
            pendingCompletion = nil
            currentState = nil
            currentCodeVerifier = nil
        }

        // Check for cancellation
        if let error = error as? ASWebAuthenticationSessionError,
           error.code == .canceledLogin {
            pendingCompletion?(.failure(OAuthError.userCancelled))
            return
        }

        guard let callbackURL = callbackURL else {
            pendingCompletion?(.failure(error ?? OAuthError.invalidCallbackURL))
            return
        }

        // Parse callback URL
        guard let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
              let queryItems = components.queryItems else {
            pendingCompletion?(.failure(OAuthError.invalidCallbackURL))
            return
        }

        let params = queryItems.reduce(into: [String: String]()) { result, item in
            result[item.name] = item.value
        }

        // Verify state to prevent CSRF
        guard let returnedState = params["state"], returnedState == currentState else {
            pendingCompletion?(.failure(OAuthError.stateMismatch))
            return
        }

        // Check for error
        if let errorDesc = params["error_description"] {
            pendingCompletion?(.failure(OAuthError.tokenExchangeFailed(errorDesc)))
            return
        }
        if let errorCode = params["error"] {
            pendingCompletion?(.failure(OAuthError.tokenExchangeFailed(errorCode)))
            return
        }

        // Extract authorization code
        guard let code = params["code"] else {
            pendingCompletion?(.failure(OAuthError.missingAuthorizationCode))
            return
        }

        // Exchange code for token
        exchangeCodeForToken(
            code: code,
            configuration: configuration,
            profileId: profileId
        )
    }

    private func exchangeCodeForToken(
        code: String,
        configuration: OAuthProviderConfiguration,
        profileId: UUID
    ) {
        guard let codeVerifier = currentCodeVerifier else {
            pendingCompletion?(.failure(OAuthError.pkceGenerationFailed))
            return
        }

        var request = URLRequest(url: configuration.tokenEndpoint)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        var bodyComponents = URLComponents()
        bodyComponents.queryItems = [
            URLQueryItem(name: "grant_type", value: "authorization_code"),
            URLQueryItem(name: "code", value: code),
            URLQueryItem(name: "redirect_uri", value: configuration.redirectUri),
            URLQueryItem(name: "client_id", value: configuration.clientId),
            URLQueryItem(name: "code_verifier", value: codeVerifier)
        ]

        request.httpBody = bodyComponents.query?.data(using: .utf8)

        URLSession.shared.dataTask(with: request) { [weak self] data, response, error in
            Task { @MainActor in
                if let error = error {
                    self?.pendingCompletion?(.failure(error))
                    return
                }

                guard let data = data,
                      let httpResponse = response as? HTTPURLResponse,
                      httpResponse.statusCode == 200 else {
                    let statusCode = (response as? HTTPURLResponse)?.statusCode ?? 0
                    self?.pendingCompletion?(.failure(OAuthError.tokenExchangeFailed("HTTP \(statusCode)")))
                    return
                }

                do {
                    let token = try self?.parseTokenResponse(
                        data: data,
                        provider: configuration.provider,
                        profileId: profileId
                    )
                    if let token = token {
                        try OAuthTokenStore.shared.save(token)
                        self?.pendingCompletion?(.success(token))
                    } else {
                        self?.pendingCompletion?(.failure(OAuthError.tokenExchangeFailed("Invalid token response")))
                    }
                } catch {
                    self?.pendingCompletion?(.failure(error))
                }
            }
        }.resume()
    }

    private func parseTokenResponse(
        data: Data,
        provider: AIProvider,
        profileId: UUID,
        existingRefreshToken: String? = nil
    ) throws -> OAuthToken {
        struct TokenResponse: Codable {
            let access_token: String
            let refresh_token: String?
            let expires_in: Int?
            let token_type: String?
            let scope: String?
            let error: String?
            let error_description: String?
        }

        let response = try JSONDecoder().decode(TokenResponse.self, from: data)

        if let error = response.error {
            let detail = response.error_description ?? error
            throw OAuthError.tokenExchangeFailed(detail)
        }

        let expiresAt: Date?
        if let expiresIn = response.expires_in {
            expiresAt = Date().addingTimeInterval(TimeInterval(expiresIn))
        } else {
            expiresAt = nil
        }

        // Use existing refresh token if new one not provided
        let refreshToken = response.refresh_token ?? existingRefreshToken

        return OAuthToken(
            provider: provider,
            profileId: profileId,
            accessToken: response.access_token,
            refreshToken: refreshToken,
            expiresAt: expiresAt
        )
    }

    // MARK: - PKCE Helpers

    private func generateCodeVerifier() -> String? {
        var bytes = [UInt8](repeating: 0, count: 32)
        let result = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        guard result == errSecSuccess else { return nil }
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func generateCodeChallenge(verifier: String) -> String? {
        guard let data = verifier.data(using: .utf8) else { return nil }
        let hash = SHA256.hash(data: data)
        return Data(hash).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func generateState() -> String {
        var bytes = [UInt8](repeating: 0, count: 16)
        _ = SecRandomCopyBytes(kSecRandomDefault, bytes.count, &bytes)
        return Data(bytes).base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    private func callbackScheme(for redirectUri: String) -> String {
        if let url = URL(string: redirectUri), let scheme = url.scheme {
            return scheme
        }
        // Fallback for custom URI schemes like com.claudeusage.app:/oauth/callback
        let components = redirectUri.split(separator: ":")
        if let first = components.first {
            return String(first)
        }
        return "claude-usage-tracker"
    }
}

// MARK: - ASWebAuthenticationPresentationContextProviding

extension OAuthFlowCoordinator: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        NSApp.keyWindow ?? NSWindow()
    }
}
