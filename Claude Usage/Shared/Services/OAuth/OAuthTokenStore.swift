//
//  OAuthTokenStore.swift
//  Claude Usage
//
//  Secure Keychain storage for OAuth tokens.
//

import Foundation
import Security

/// Stores and retrieves OAuth tokens from the macOS Keychain.
/// Tokens are scoped per-provider and per-profile.
@MainActor
final class OAuthTokenStore {
    static let shared = OAuthTokenStore()

    private init() {}

    // MARK: - Key Helpers

    private func serviceKey(for provider: AIProvider, profileId: UUID) -> String {
        "com.claudeusage.oauth.\(provider.rawValue).\(profileId.uuidString)"
    }

    private func accountKey(for provider: AIProvider) -> String {
        "oauth-token-\(provider.rawValue)"
    }

    // MARK: - Public API

    /// Saves an OAuth token to the Keychain
    func save(_ token: OAuthToken) throws {
        let data = try JSONEncoder().encode(token)

        let service = serviceKey(for: token.provider, profileId: token.profileId)
        let account = accountKey(for: token.provider)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly,
            kSecAttrSynchronizable as String: false
        ]

        // Delete existing first (to avoid duplicates)
        SecItemDelete(query as CFDictionary)

        let status = SecItemAdd(query as CFDictionary, nil)
        guard status == errSecSuccess else {
            throw KeychainError.saveFailed(status: status)
        }

        LoggingService.shared.log("OAuthTokenStore: Saved token for \(token.provider.displayName)")
    }

    /// Loads an OAuth token for a given provider and profile
    func load(provider: AIProvider, profileId: UUID) -> OAuthToken? {
        let service = serviceKey(for: provider, profileId: profileId)
        let account = accountKey(for: provider)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]

        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)

        guard status == errSecSuccess,
              let data = result as? Data else {
            return nil
        }

        do {
            let token = try JSONDecoder().decode(OAuthToken.self, from: data)
            LoggingService.shared.log("OAuthTokenStore: Loaded token for \(provider.displayName)")
            return token
        } catch {
            LoggingService.shared.logError("OAuthTokenStore: Failed to decode token", error: error)
            return nil
        }
    }

    /// Deletes an OAuth token for a given provider and profile
    func delete(provider: AIProvider, profileId: UUID) {
        let service = serviceKey(for: provider, profileId: profileId)
        let account = accountKey(for: provider)

        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account
        ]

        let status = SecItemDelete(query as CFDictionary)
        if status == errSecSuccess || status == errSecItemNotFound {
            LoggingService.shared.log("OAuthTokenStore: Deleted token for \(provider.displayName)")
        }
    }

    /// Checks if a token exists for a provider/profile
    func hasToken(provider: AIProvider, profileId: UUID) -> Bool {
        load(provider: provider, profileId: profileId) != nil
    }

    /// Updates an existing token (e.g. after refresh)
    func update(_ token: OAuthToken) throws {
        try save(token)
    }

    /// Deletes all OAuth tokens for a given profile (used when profile is deleted)
    func deleteAllTokens(for profileId: UUID) {
        for provider in AIProvider.allCases where provider.supportsOAuth {
            delete(provider: provider, profileId: profileId)
        }
    }
}
