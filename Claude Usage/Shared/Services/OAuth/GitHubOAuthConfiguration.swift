//
//  GitHubOAuthConfiguration.swift
//  Claude Usage
//
//  OAuth configuration for GitHub/Copilot.
//

import Foundation

/// OAuth configuration for GitHub (Copilot)
struct GitHubOAuthConfiguration: OAuthProviderConfiguration {
    let provider: AIProvider = .copilot

    var authorizationEndpoint: URL {
        URL(string: "https://github.com/login/oauth/authorize")!
    }

    var tokenEndpoint: URL {
        URL(string: "https://github.com/login/oauth/access_token")!
    }

    var scopes: [String] {
        ["read:user", "read:org"]
    }

    /// Client ID from GitHub OAuth App settings.
    /// TODO: Replace with your actual client ID before shipping.
    var clientId: String {
        Bundle.main.object(forInfoDictionaryKey: "GITHUB_OAUTH_CLIENT_ID") as? String
        ?? "YOUR_GITHUB_CLIENT_ID"
    }

    var redirectUri: String {
        "claude-usage-tracker://oauth/callback"
    }
}
