import Foundation
import os.log

/// Sends an authenticated "Hi" ping every 5 hours to keep the active profile's Claude.ai session alive.
/// This only works for profiles that store a Claude.ai session key, because the chat-conversation
/// endpoint on claude.ai is what resets the 5-hour rolling window. CLI/API Console OAuth tokens
/// cannot reset the web session, so those profiles are skipped with a clear log message.
/// Uses the existing incognito conversation flow (create → send "Hi" → delete) so no chat history remains.
/// On success, triggers a usage refresh so the UI reflects the 5-hour session reset.
///
/// Scheduling: a one-shot timer is scheduled for `max(lastPing + sessionWindow, now)`. When it fires,
/// the ping is sent and the next one-shot is scheduled for `now + sessionWindow`. This guarantees the
/// ping fires at the exact 5-hour mark from the last successful ping, regardless of app restarts.
@MainActor
final class ClaudeKeepAliveService {
    static let shared = ClaudeKeepAliveService()

    private let apiService = ClaudeAPIService()
    private let profileManager = ProfileManager.shared
    private let lastPingKeyPrefix = "keepalive.lastPing."
    private var timer: Timer?
    private var inFlight = false

    private init() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(pingNow),
            name: .claudeKeepAlivePingNow,
            object: nil
        )
    }

    /// Starts the keep-alive service. Schedules the next ping to fire at the 5-hour mark from the
    /// last successful ping, or immediately if that mark has already passed.
    func start() {
        timer?.invalidate()
        timer = nil

        let nextFireAt = nextScheduledFireDate()
        let interval = max(0, nextFireAt.timeIntervalSinceNow)

        LoggingService.shared.log("KeepAlive: scheduling next ping in \(Int(interval / 60)) minutes", type: .default)

        if interval <= 0 {
            sendIfNeeded()
        } else {
            scheduleOneShot(at: nextFireAt)
        }
    }

    /// Stops the scheduled timer.
    func stop() {
        timer?.invalidate()
        timer = nil
        LoggingService.shared.log("ClaudeKeepAliveService stopped", type: .default)
    }

    /// Sends a keep-alive "Hi" immediately, bypassing the 5-hour gate.
    @objc func pingNow() {
        LoggingService.shared.log("KeepAlive: manual ping requested", type: .default)
        timer?.invalidate()
        timer = nil
        sendPing(force: true)
    }

    private func nextScheduledFireDate() -> Date {
        guard let profile = profileManager.activeProfile else { return .distantFuture }
        let key = lastPingKeyPrefix + profile.id.uuidString
        let lastPing = UserDefaults.standard.object(forKey: key) as? Date ?? .distantPast
        let scheduled = lastPing.addingTimeInterval(Constants.sessionWindow)
        return max(scheduled, Date())
    }

    private func scheduleOneShot(at fireDate: Date) {
        timer?.invalidate()
        let interval = max(0.1, fireDate.timeIntervalSinceNow)
        timer = Timer.scheduledTimer(withTimeInterval: interval, repeats: false) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.sendIfNeeded()
            }
        }
        if let timer = timer {
            timer.tolerance = interval * 0.05
        }
    }

    private func sendIfNeeded() {
        sendPing(force: false)
    }

    private func sendPing(force: Bool) {
        guard let profile = profileManager.activeProfile else {
            LoggingService.shared.log("KeepAlive: no active profile – skipping", type: .default)
            reschedule()
            return
        }

        // The claude.ai chat endpoint only accepts a claude.ai session key cookie.
        // CLI OAuth / API Console keys cannot reset the web 5-hour session window.
        guard profile.claudeSessionKey != nil else {
            LoggingService.shared.log("KeepAlive: active profile '\(profile.name)' has no Claude.ai session key – skipping (CLI/API Console auth cannot reset the web session)", type: .default)
            reschedule()
            return
        }

        let key = lastPingKeyPrefix + profile.id.uuidString
        let lastPing = UserDefaults.standard.object(forKey: key) as? Date ?? .distantPast
        let elapsed = Date().timeIntervalSince(lastPing)

        if !force, elapsed < Constants.sessionWindow {
            let remaining = Constants.sessionWindow - elapsed
            LoggingService.shared.log("KeepAlive: next ping for '\(profile.name)' in \(Int(remaining / 60)) minutes", type: .default)
            reschedule()
            return
        }

        if inFlight {
            LoggingService.shared.log("KeepAlive: ping already in flight – skipping duplicate", type: .default)
            reschedule()
            return
        }

        LoggingService.shared.log("KeepAlive: sending 'Hi' for profile '\(profile.name)' (last ping \(Int(elapsed / 60)) minutes ago)", type: .default)
        inFlight = true

        Task {
            do {
                try await apiService.sendInitializationMessage()
                let now = Date()
                UserDefaults.standard.set(now, forKey: key)
                LoggingService.shared.log("KeepAlive: 'Hi' sent and conversation deleted for profile '\(profile.name)' – next ping in \(Int(Constants.sessionWindow / 3600))h", type: .default)

                // Trigger usage refresh so the 5-hour ring updates immediately
                NotificationCenter.default.post(name: .credentialsChanged, object: nil)
            } catch {
                LoggingService.shared.logError("KeepAlive: failed to send 'Hi' for profile '\(profile.name)' – \(error.localizedDescription)")
            }
            inFlight = false
            reschedule()
        }
    }

    private func reschedule() {
        let next = Date().addingTimeInterval(Constants.sessionWindow)
        scheduleOneShot(at: next)
    }
}

extension Notification.Name {
    static let claudeKeepAlivePingNow = Notification.Name("claudeKeepAlivePingNow")
}
