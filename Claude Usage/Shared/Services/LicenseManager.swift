//
//  LicenseManager.swift
//  Claude Usage
//
//  Manages license validation, caching, and tier determination.
//  Supports Paddle direct distribution with offline grace period.
//

import Foundation
import Combine

/// Manages app licensing and subscription validation
@MainActor
final class LicenseManager: ObservableObject {
    static let shared = LicenseManager()

    @Published private(set) var currentTier: LicenseTier = .free
    @Published private(set) var licenseKey: String?
    @Published private(set) var isValidating: Bool = false
    @Published private(set) var lastValidationDate: Date?
    @Published private(set) var validationError: String?

    /// Offline grace period before features lock (7 days)
    private let offlineGracePeriod: TimeInterval = 7 * 24 * 60 * 60

    /// How often to validate license (daily)
    private let validationInterval: TimeInterval = 24 * 60 * 60

    private let defaults = UserDefaults.standard

    private enum Keys {
        static let licenseKey = "licenseKey"
        static let cachedTier = "cachedLicenseTier"
        static let lastValidation = "lastLicenseValidation"
        static let validationFailedDate = "licenseValidationFailedDate"
    }

    private init() {
        loadCachedLicense()
    }

    // MARK: - Public API

    /// Activates a license key (called during purchase/activation flow)
    func activateLicense(_ key: String) async -> Bool {
        isValidating = true
        validationError = nil
        defer { isValidating = false }

        // Validate against Paddle API
        let isValid = await validateWithPaddle(key: key)

        if isValid {
            self.licenseKey = key
            self.currentTier = .pro // Paddle validation succeeds -> Pro tier
            self.lastValidationDate = Date()
            saveCachedLicense()
            LoggingService.shared.log("License activated: Pro tier")
            return true
        } else {
            self.validationError = "Invalid or expired license key."
            LoggingService.shared.logError("License activation failed for key: \(key.prefix(8))...")
            return false
        }
    }

    /// Deactivates current license (logout/restore purchases)
    func deactivateLicense() {
        licenseKey = nil
        currentTier = .free
        lastValidationDate = nil
        clearCachedLicense()
        LoggingService.shared.log("License deactivated, reverting to Free tier")
    }

    /// Periodically validates the cached license (call on app launch / daily)
    func validateIfNeeded() async {
        // No license key to validate
        guard let key = licenseKey else {
            currentTier = .free
            return
        }

        // Check if enough time has passed since last validation
        if let lastValidation = lastValidationDate,
           Date().timeIntervalSince(lastValidation) < validationInterval {
            // Within validation interval, use cached tier
            return
        }

        isValidating = true
        defer { isValidating = false }

        let isValid = await validateWithPaddle(key: key)

        if isValid {
            lastValidationDate = Date()
            saveCachedLicense()
            LoggingService.shared.log("License revalidated successfully")
        } else {
            // Check if we're within grace period
            if isWithinGracePeriod {
                LoggingService.shared.log("License validation failed, but within grace period. Features remain active.")
            } else {
                // Grace period expired - downgrade
                currentTier = .free
                validationError = "License validation failed. Please reconnect to restore Pro features."
                LoggingService.shared.log("License grace period expired. Downgraded to Free.")
            }
        }
    }

    /// Forces immediate validation (for manual refresh)
    func forceValidation() async {
        guard licenseKey != nil else { return }
        await validateIfNeeded()
    }

    /// Whether the user can use Pro features right now (includes grace period)
    var canUseProFeatures: Bool {
        return currentTier.rank >= LicenseTier.pro.rank || isWithinGracePeriod
    }

    /// Whether we're within the offline grace period after a failed validation
    var isWithinGracePeriod: Bool {
        guard let failedDate = defaults.object(forKey: Keys.validationFailedDate) as? Date else {
            return false
        }
        return Date().timeIntervalSince(failedDate) < offlineGracePeriod
    }

    // MARK: - Private

    private func loadCachedLicense() {
        if let key = defaults.string(forKey: Keys.licenseKey) {
            licenseKey = key
        }

        if let tierRaw = defaults.string(forKey: Keys.cachedTier),
           let tier = LicenseTier(rawValue: tierRaw) {
            currentTier = tier
        }

        if let lastVal = defaults.object(forKey: Keys.lastValidation) as? Date {
            lastValidationDate = lastVal
        }

        LoggingService.shared.log("LicenseManager: Loaded cached tier: \(currentTier.displayName)")
    }

    private func saveCachedLicense() {
        if let key = licenseKey {
            defaults.set(key, forKey: Keys.licenseKey)
        }
        defaults.set(currentTier.rawValue, forKey: Keys.cachedTier)
        defaults.set(lastValidationDate, forKey: Keys.lastValidation)
        defaults.removeObject(forKey: Keys.validationFailedDate)
    }

    private func clearCachedLicense() {
        defaults.removeObject(forKey: Keys.licenseKey)
        defaults.removeObject(forKey: Keys.cachedTier)
        defaults.removeObject(forKey: Keys.lastValidation)
        defaults.removeObject(forKey: Keys.validationFailedDate)
    }

    private func recordValidationFailure() {
        if defaults.object(forKey: Keys.validationFailedDate) == nil {
            defaults.set(Date(), forKey: Keys.validationFailedDate)
        }
    }

    /// Validates license key against Paddle API
    /// NOTE: This is a stub implementation. Replace with actual Paddle SDK integration.
    private func validateWithPaddle(key: String) async -> Bool {
        // TODO: Integrate with Paddle macOS SDK
        // For now, accept any non-empty key format: XXXX-XXXX-XXXX-XXXX
        let isFormatValid = key.count >= 16 && key.contains("-")

        if !isFormatValid {
            recordValidationFailure()
            return false
        }

        // Simulate network validation delay
        try? await Task.sleep(nanoseconds: 500_000_000)

        // In production, call Paddle API:
        // let result = await Paddle.shared.verifyLicenseKey(key)
        // return result.isValid

        // Stub: accept well-formatted keys
        return true
    }

    /// Returns the Paddle checkout URL for purchasing Pro
    var proCheckoutURL: URL? {
        // TODO: Replace with actual Paddle product/checkout URL
        URL(string: "https://checkout.paddle.com/product/pro")
    }

    /// Returns the Paddle checkout URL for purchasing Team
    var teamCheckoutURL: URL? {
        // TODO: Replace with actual Paddle product/checkout URL
        URL(string: "https://checkout.paddle.com/product/team")
    }
}
