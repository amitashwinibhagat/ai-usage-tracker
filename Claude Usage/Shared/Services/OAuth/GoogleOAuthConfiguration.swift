//
//  GoogleOAuthConfiguration.swift
//  Claude Usage
//
//  OAuth configuration for Google/Gemini.
//

import Foundation

/// OAuth configuration for Google (Gemini / Cloud Monitoring)
struct GoogleOAuthConfiguration: OAuthProviderConfiguration {
    let provider: AIProvider = .gemini

    var authorizationEndpoint: URL {
        URL(string: "https://accounts.google.com/o/oauth2/v2/auth")!
    }

    var tokenEndpoint: URL {
        URL(string: "https://oauth2.googleapis.com/token")!
    }

    var scopes: [String] {
        [
            "https://www.googleapis.com/auth/monitoring.read",
            "https://www.googleapis.com/auth/cloud-platform.read-only"
        ]
    }

    /// Client ID from Google Cloud Console.
    /// Register an OAuth 2.0 client ID for "iOS" with bundle ID matching the app.
    /// TODO: Replace with your actual client ID before shipping.
    var clientId: String {
        Bundle.main.object(forInfoDictionaryKey: "GOOGLE_OAUTH_CLIENT_ID") as? String
        ?? "YOUR_GOOGLE_CLIENT_ID.apps.googleusercontent.com"
    }

    var redirectUri: String {
        let bundleId = Bundle.main.bundleIdentifier ?? "com.claudeusage.app"
        return "\(bundleId):/oauth/callback"
    }
}
