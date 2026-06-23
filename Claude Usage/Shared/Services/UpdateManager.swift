//
//  UpdateManager.swift
//  Claude Usage
//
//  Sparkle update manager wrapper
//

import Foundation
import Combine
import Sparkle

/// User driver delegate for Sparkle gentle reminders
final class UpdateUserDriver: NSObject, SPUStandardUserDriverDelegate {
    // REQUIRED: Enable gentle reminders for background apps
    var supportsGentleScheduledUpdateReminders: Bool {
        return true
    }

    // Handle showing scheduled updates
    func standardUserDriverShouldHandleShowingScheduledUpdate(_ update: SUAppcastItem, andInImmediateFocus immediateFocus: Bool) -> Bool {
        // For background/menu bar apps, always show updates
        return true
    }

    // Customize how updates are shown
    func standardUserDriverWillHandleShowingUpdate(_ handleShowingUpdate: Bool, forUpdate update: SUAppcastItem, state: SPUUserUpdateState) {
        if handleShowingUpdate {
            LoggingService.shared.logInfo("Showing update alert for version \(update.displayVersionString)")
        }
    }

    // Optional: Handle when user interacts with update
    func standardUserDriverDidReceiveUserAttention(forUpdate update: SUAppcastItem) {
        LoggingService.shared.logInfo("User attended to update: \(update.displayVersionString)")
    }

    // Optional: Cleanup when update session finishes
    func standardUserDriverWillFinishUpdateSession() {
        LoggingService.shared.logInfo("Update session finished")
    }
}

/// Outcome of the most recent update check. Surfaced to the UI so
/// the user gets feedback after tapping "Check for Updates".
/// (BUG 5 from the click audit.)
enum UpdateCheckOutcome: Equatable {
    case idle
    case checking
    case upToDate
    case updateAvailable(version: String)
    case failed(message: String)
}

/// Manages automatic updates using Sparkle framework
final class UpdateManager: ObservableObject {
    static let shared = UpdateManager()

    private let updaterController: SPUStandardUpdaterController
    private let userDriver: UpdateUserDriver // Keep strong reference
    private let updaterDelegate: UpdaterDelegate
    private let callbackBox = UpdaterCallbackBox()

    @Published private(set) var canCheckForUpdates: Bool = false
    @Published private(set) var automaticChecksEnabled: Bool = false
    @Published private(set) var lastCheckOutcome: UpdateCheckOutcome = .idle

    private init() {
        // Create user driver delegate for gentle reminders
        userDriver = UpdateUserDriver()

        // Create the updater delegate with a box. The box's
        // callback is set after self is fully initialized to
        // satisfy Swift's strict init checking.
        let delegate = UpdaterDelegate(box: callbackBox)

        // Initialize Sparkle updater with the delegate
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true,
            updaterDelegate: delegate,
            userDriverDelegate: userDriver
        )
        self.updaterDelegate = delegate

        // Now that self is fully initialized, wire the box to
        // forward outcomes to our @Published property.
        callbackBox.set { [weak self] outcome in
            DispatchQueue.main.async {
                self?.lastCheckOutcome = outcome
            }
        }

        automaticChecksEnabled = updaterController.updater.automaticallyChecksForUpdates
        canCheckForUpdates = updaterController.updater.canCheckForUpdates

        LoggingService.shared.logInfo("Update manager initialized with gentle reminders")
    }

    /// Manually check for updates. The result is published on
    /// `lastCheckOutcome` once Sparkle reports back.
    func checkForUpdates() {
        lastCheckOutcome = .checking
        updaterController.checkForUpdates(nil)
        LoggingService.shared.logInfo("Manual update check triggered")
    }

    /// Reset the last-check outcome (e.g. when the user dismisses the toast).
    func acknowledgeLastCheckOutcome() {
        lastCheckOutcome = .idle
    }

    /// Toggle automatic update checks
    func setAutomaticChecksEnabled(_ enabled: Bool) {
        updaterController.updater.automaticallyChecksForUpdates = enabled
        automaticChecksEnabled = enabled
        DataStore.shared.userDefaults.set(enabled, forKey: "SUEnableAutomaticChecks")
        LoggingService.shared.logInfo("Automatic updates: \(enabled)")
    }

    /// Get last update check date
    var lastUpdateCheckDate: Date? {
        return updaterController.updater.lastUpdateCheckDate
    }
}

/// Box that holds a callback set after `UpdateManager` is fully
/// initialized. Using a box lets the `UpdaterDelegate` be created
/// during `UpdateManager.init` without capturing `self` (which
/// Swift's strict init checking forbids).
private final class UpdaterCallbackBox: @unchecked Sendable {
    private var callback: ((UpdateCheckOutcome) -> Void)?

    func set(_ callback: @escaping (UpdateCheckOutcome) -> Void) {
        self.callback = callback
    }

    func emit(_ outcome: UpdateCheckOutcome) {
        callback?(outcome)
    }
}

/// Sparkle updater delegate that bridges result callbacks into
/// `UpdateManager.lastCheckOutcome`.
private final class UpdaterDelegate: NSObject, SPUUpdaterDelegate {
    private let box: UpdaterCallbackBox

    init(box: UpdaterCallbackBox) {
        self.box = box
    }

    func updaterDidNotFindUpdate(_ updater: SPUUpdater) {
        box.emit(.upToDate)
    }

    func updater(_ updater: SPUUpdater, didFindUpdate item: SUAppcastItem) {
        box.emit(.updateAvailable(version: item.displayVersionString))
    }

    func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        box.emit(.failed(message: error.localizedDescription))
    }
}
