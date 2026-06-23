import Foundation
import os.log

/// Sends an authenticated "Hi" ping every 5 hours to keep the active profile's Claude.ai session alive.
/// This only works for profiles that store a Claude.ai session key, because the chat-conversation
/// endpoint on claude.ai is what resets the 5-hour rolling window. CLI/API Console OAuth tokens
/// cannot reset the web session, so those profiles are skipped with a clear log message.
/// Uses the existing incognito conversation flow (create → send "Hi" → delete) so no chat history remains.
/// On success, triggers a usage refresh so the UI reflects the 5-hour session reset.
@MainActor
final class ClaudeKeepAliveService {
    static let shared = ClaudeKeepAliveService()

    private let apiService = ClaudeAPIService()
    private let profileManager = ProfileManager.shared
    private let lastPingKeyPrefix = "keepalive.lastPing."
    private var timer: Timer?

    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(pingNow),
            name: .claudeKeepAlivePingNow,
            object: nil
        )
    }

    /// Starts the keep-alive service. Sends immediately if 5 h have elapsed since last successful ping,
    /// then schedules a repeating timer.
    func start() {
        timer?.invalidate()
        sendIfNeeded()
        timer = Timer.scheduledTimer(withTimeInterval: Constants.sessionWindow, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.sendIfNeeded()
            }
        }
        timer?.tolerance = Constants.sessionWindow * 0.1
        LoggingService.shared.log("ClaudeKeepAliveService started (5-hour interval)", type: .default)
    }

    /// Stops the repeating timer.
    func stop() {
        timer?.invalidate()
        timer = nil
        LoggingService.shared.log("ClaudeKeepAliveService stopped", type: .default)
    }

    /// Sends a keep-alive "Hi" immediately, bypassing the 5-hour gate.
    /// Used by the manual trigger notification and can be hooked up to a UI control.
    @objc func pingNow() {
        LoggingService.shared.log("KeepAlive: manual ping requested", type: .default)
        sendPing(force: true)
    }

    private func sendIfNeeded() {
        sendPing(force: false)
    }

    private func sendPing(force: Bool) {
        guard let profile = profileManager.activeProfile else {
            LoggingService.shared.log("KeepAlive: no active profile – skipping", type: .default)
            return
        }

        // The claude.ai chat endpoint only accepts a claude.ai session key cookie.
        // CLI OAuth / API Console keys cannot reset the web 5-hour session window.
        guard profile.claudeSessionKey != nil else {
            LoggingService.shared.log("KeepAlive: active profile '\(profile.name)' has no Claude.ai session key – skipping (CLI/API Console auth cannot reset the web session)", type: .default)
            return
        }

        let key = lastPingKeyPrefix + profile.id.uuidString
        let lastPing = UserDefaults.standard.object(forKey: key) as? Date ?? .distantPast
        let elapsed = Date().timeIntervalSince(lastPing)

        if !force, elapsed < Constants.sessionWindow {
            let remaining = Constants.sessionWindow - elapsed
            LoggingService.shared.log("KeepAlive: next ping for '\(profile.name)' in \(Int(remaining / 60)) minutes", type: .default)
            return
        }

        LoggingService.shared.log("KeepAlive: sending 'Hi' for profile '\(profile.name)' (last ping \(Int(elapsed / 60)) minutes ago)", type: .default)

        Task {
            do {
                try await apiService.sendInitializationMessage()
                UserDefaults.standard.set(Date(), forKey: key)
                LoggingService.shared.log("KeepAlive: 'Hi' sent and conversation deleted for profile '\(profile.name)'", type: .default)

                // Trigger usage refresh so the 5-hour ring updates immediately
                NotificationCenter.default.post(name: .credentialsChanged, object: nil)
            } catch {
                LoggingService.shared.logError("KeepAlive: failed to send 'Hi' for profile '\(profile.name)' – \(error.localizedDescription)")
            }
        }
    }
}

extension Notification.Name {
    static let claudeKeepAlivePingNow = Notification.Name("claudeKeepAlivePingNow")
}
