//
//  OAuthToken.swift
//  Claude Usage
//
//  Model representing an OAuth token for a specific AI provider.
//

import Foundation

/// Represents an OAuth access token (and optional refresh token) for an AI provider.
/// Tokens are stored in the Keychain, never in Profile/UserDefaults.
struct OAuthToken: Codable {
    let provider: AIProvider
    let profileId: UUID
    var accessToken: String
    var refreshToken: String?
    var expiresAt: Date?

    /// Whether the access token has expired (with 60-second buffer)
    var isExpired: Bool {
        guard let expiresAt = expiresAt else { return false }
        return Date().addingTimeInterval(60) >= expiresAt
    }

    /// Whether this token can be refreshed
    var canRefresh: Bool {
        refreshToken != nil && !refreshToken!.isEmpty
    }
}

/// Errors specific to OAuth operations
enum OAuthError: Error, LocalizedError, Equatable {
    case pkceGenerationFailed
    case invalidCallbackURL
    case missingAuthorizationCode
    case stateMismatch
    case tokenExchangeFailed(String)
    case noRefreshToken
    case userCancelled
    case unsupportedProvider

    static func == (lhs: OAuthError, rhs: OAuthError) -> Bool {
        switch (lhs, rhs) {
        case (.pkceGenerationFailed, .pkceGenerationFailed),
             (.invalidCallbackURL, .invalidCallbackURL),
             (.missingAuthorizationCode, .missingAuthorizationCode),
             (.stateMismatch, .stateMismatch),
             (.noRefreshToken, .noRefreshToken),
             (.userCancelled, .userCancelled),
             (.unsupportedProvider, .unsupportedProvider):
            return true
        case (.tokenExchangeFailed(let a), .tokenExchangeFailed(let b)):
            return a == b
        default:
            return false
        }
    }

    var errorDescription: String? {
        switch self {
        case .pkceGenerationFailed:
            return "Failed to generate secure OAuth parameters"
        case .invalidCallbackURL:
            return "Invalid response from authentication server"
        case .missingAuthorizationCode:
            return "Authorization code not received"
        case .stateMismatch:
            return "Security validation failed (state mismatch)"
        case .tokenExchangeFailed(let detail):
            return "Token exchange failed: \(detail)"
        case .noRefreshToken:
            return "No refresh token available"
        case .userCancelled:
            return "Authentication was cancelled"
        case .unsupportedProvider:
            return "This provider does not support OAuth login"
        }
    }
}
