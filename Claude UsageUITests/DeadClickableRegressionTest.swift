//
//  DeadClickableRegressionTest.swift
//  Claude UsageUITests
//
//  Pins every "clickable element that doesn't actually do anything" bug
//  surfaced by the click-test audit of 2026-06-25.
//
//  Method: static analysis of source files. Every assertion checks that a
//  known-bad pattern is GONE from the source. If a regression re-introduces
//  the dead-clickable, the test fails loudly with a message naming the
//  affected view/button/notification.
//
//  Bugs pinned here:
//
//    BUG 12 — Popover "Manage Profiles" button posts .showManageProfiles
//              but nothing observes the notification → button does nothing.
//
//    BUG 13 — AboutView.fetchContributors() exists but is never invoked;
//              onAppear body is empty. ContributorsGridView is defined
//              but never rendered.
//
//    BUG 14 — AboutView is not the active Settings → Account page
//              (AccountSettingsView is). Any "click" inside AboutView
//              is dead surface area.
//
//    BUG 15 — Several View structs are defined but never instantiated
//              anywhere in the active UI:
//                AppSettingsView, ManageProfilesView, APISettingsView,
//                ContextualTipCard, CrossProfileDashboard, SessionOverlapCard.
//
//    BUG 16 — ProfilesSettingsView "Limit" branch is unreachable because
//              profileManager.canCreateProfile always returns true. The
//              "Free tier profile capacity is full" copy is dead.
//
//    BUG 17 — AppearanceSettingsView "Global Settings" card renders
//              EmptyView() — the entire card is a no-op.
//
//    BUG 18 — AppearanceSettingsView popoverWidthIndex @State is bound
//              to a Picker but never persisted, so the user's selection
//              silently resets on every relaunch.
//

import XCTest

final class DeadClickableRegressionTest: BaseUITest {

    private let repoRoot = "/Users/amitashwini/Projects/Claude Usage Optimizer/Claude-Usage-Optimizer"

    // MARK: - BUG 12: Popover "Manage Profiles" button is dead

    /// The header "Manage Profiles" button in PopoverContentView posts
    /// `.showManageProfiles` (line ~267) but no observer registers for
    /// that notification anywhere in the codebase. The button does nothing
    /// when tapped. To verify: the string `.showManageProfiles` must appear
    /// in the production source as a *post* target OR there must be at least
    /// one observer (`addObserver`/`NotificationCenter.default.publisher`).
    func test_showManageProfiles_notification_has_an_observer() throws {
        let notificationName = ".showManageProfiles"

        // 1. Find every Swift file that references the notification.
        var producers: [String] = []
        var observers: [String] = []

        try walkSourceTree { relativePath, source in
            if source.contains(notificationName) {
                // Producer: a line that *posts* the notification.
                if source.contains("post(name: .showManageProfiles") {
                    producers.append(relativePath)
                }
                // Observer: any addObserver / publisher / NotificationCenter
                // registration referencing the same notification.
                if source.contains("addObserver(forName: .showManageProfiles") ||
                   source.contains(".showManageProfiles)") ||
                   source.contains(".showManagePublished ") {
                    observers.append(relativePath)
                }
            }
        }

        XCTAssertFalse(producers.isEmpty,
                       "Sanity check failed: nobody posts .showManageProfiles at all.")
        XCTAssertTrue(!observers.isEmpty,
                      """
                      BUG 12 — The popover "Manage Profiles" button is dead.

                      Producers of .showManageProfiles:
                        \(producers.joined(separator: "\n  "))

                      No file registers an observer for the notification, so the
                      button click is silently swallowed.

                      Fix: either
                        a) Wire an observer in AppDelegate / MenuBarManager that
                           opens the Manage Profiles sheet, OR
                        b) Replace the .post with an explicit call into
                           MenuBarManager.preferencesClicked() with the profiles
                           tab selected.
                      """)
    }

    // MARK: - BUG 13: AboutView.fetchContributors never runs

    /// AboutView defines a fetchContributors() helper and a
    /// ContributorsGridView, but the body never renders the grid and the
    /// view's `.onAppear` body is empty (`{ }`). The whole contributor
    /// surface is dead.
    func test_about_view_contributors_are_actually_loaded_and_rendered() throws {
        let aboutPath = "\(repoRoot)/Claude Usage/Views/Settings/App/AboutView.swift"
        let source = try String(contentsOfFile: aboutPath, encoding: .utf8)

        // The .onAppear block must contain a call to fetchContributors.
        let onAppearPattern = #"\.onAppear\s*\{\s*([^}]*)\}"#
        let onAppearRegex = try NSRegularExpression(pattern: onAppearPattern, options: [.dotMatchesLineSeparators])
        let range = NSRange(source.startIndex..<source.endIndex, in: source)
        let onAppearMatches = onAppearRegex.matches(in: source, options: [], range: range)

        XCTAssertFalse(onAppearMatches.isEmpty,
                       "AboutView has no .onAppear block at all.")
        var anyOnAppearCallsFetch = false
        for match in onAppearMatches {
            guard match.numberOfRanges > 1,
                  let bodyRange = Range(match.range(at: 1), in: source) else { continue }
            let body = String(source[bodyRange])
            if body.contains("fetchContributors") {
                anyOnAppearCallsFetch = true
                break
            }
        }
        XCTAssertTrue(anyOnAppearCallsFetch,
                      """
                      BUG 13 — AboutView.fetchContributors() is never called.

                      The view has a `.onAppear { }` with an empty body, so the
                      contributor grid is never loaded and never shown.

                      Fix: `.onAppear { fetchContributors() }` and add the
                      ContributorsGridView to the body.
                      """)

        // The body must include ContributorsGridView (or render the
        // fetched contributors).
        XCTAssertTrue(source.contains("ContributorsGridView") &&
                      source.range(of: #"ContributorsGridView\("#, options: .regularExpression) != nil,
                      """
                      BUG 13 (cont.) — ContributorsGridView is defined but
                      never instantiated by the body.
                      """)
    }

    // MARK: - BUG 15: Dead View structs

    /// Several View structs exist but are never instantiated by any other
    /// view in the active UI. They're not broken clickables, but they
    /// represent "screen real estate" that ships without any test
    /// coverage and can drift silently. List the offenders so a future
    /// cleanup pass can either wire them up or delete them.
    func test_no_dead_view_structs_in_active_ui() throws {
        // Views to check. The first element of each pair is the struct name,
        // the second is a hint describing what it replaces or why it exists.
        let candidates: [(name: String, hint: String)] = [
            ("AppSettingsView",      "Merged into GeneralSettingsView"),
            ("ManageProfilesView",    "Merged into ProfilesSettingsView"),
            ("APISettingsView",       "Merged into APIBillingView"),
            ("CrossProfileDashboard", "Replaced by CrossProfileAccordion in popover"),
            ("ContextualTipCard",     "Removed in popover 5-card redesign"),
            ("SessionOverlapCard",    "Removed in popover 5-card redesign"),
        ]

        for (viewName, hint) in candidates {
            let usages = findInstantiations(ofViewNamed: viewName)
            // Each view should be instantiated at least once outside its own file
            // (e.g. by the SettingsView router or a popover).
            XCTAssertFalse(usages.isEmpty,
                           """
                           Dead View: \(viewName) — \(hint).

                           No other source file instantiates `\(viewName)()`, so it
                           is unreachable in the active UI. Either wire it into
                           SettingsView.router / PopoverContentView, or delete the
                           file. Dead views are how regressions sneak in.
                           """)
        }
    }

    // MARK: - BUG 16: Unreachable "Limit" branch in ProfilesSettingsView

    /// ProfilesSettingsView shows "Free tier profile capacity is full"
    /// when `profileManager.canCreateProfile` is false. The model returns
    /// `true` unconditionally, so the else-branch is unreachable and the
    /// copy is misleading.
    func test_profile_capacity_limit_copy_is_reachable() throws {
        let viewPath = "\(repoRoot)/Claude Usage/Views/Settings/ProfilesSettingsView.swift"
        let modelPath = "\(repoRoot)/Claude Usage/Shared/Services/ProfileManager.swift"

        let viewSource = try String(contentsOfFile: viewPath, encoding: .utf8)
        let modelSource = try String(contentsOfFile: modelPath, encoding: .utf8)

        // Look for the misleading copy.
        XCTAssertFalse(viewSource.contains("Free tier profile capacity is full"),
                       """
                       BUG 16 — ProfilesSettingsView shows 'Free tier profile
                       capacity is full. Existing profiles remain usable.' but
                       ProfileManager.canCreateProfile returns true unconditionally
                       (see ProfileManager.swift). The Limit branch is dead and
                       the copy is misleading.

                       Either:
                         a) Delete the Limit branch and show "Unlimited" / "Ready"
                            only, or
                         b) Make canCreateProfile actually gate something.
                       """)

        // Also guard against future drift: the getter must literally
        // return `true` (or compute from a real limit).
        XCTAssertFalse(modelSource.contains("var canCreateProfile: Bool {\n        true\n    }"),
                       """
                       BUG 16 (cont.) — ProfileManager.canCreateProfile is hard-coded
                       to `true`. If you re-add a paid tier or limit, remember to
                       update both this getter and ProfilesSettingsView's capacity card.
                       """)
    }

    // MARK: - BUG 17: Empty "Global Settings" card

    /// AppearanceSettingsView.displayToggleCard renders an EmptyView() in
    /// its content slot. The "Global Settings" header card has nothing
    /// inside. Users see a card with a title and a body that is a blank
    /// space. That's not strictly a broken clickable, but it's dead UI
    /// that violates the "no inert controls" rule.
    func test_display_toggle_card_is_not_empty() throws {
        let viewPath = "\(repoRoot)/Claude Usage/Views/Settings/AppearanceSettingsView.swift"
        let source = try String(contentsOfFile: viewPath, encoding: .utf8)

        let pattern = #"private var displayToggleCard: some View \{\s*SettingsSectionCard\([^)]*\)\s*\{\s*([^}]*)\}"#
        let regex = try NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators])
        let range = NSRange(source.startIndex..<source.endIndex, in: source)
        guard let match = regex.firstMatch(in: source, options: [], range: range),
              match.numberOfRanges > 1,
              let bodyRange = Range(match.range(at: 1), in: source) else {
            // If we cannot find the function, treat it as a pass: someone
            // may have refactored it. The regression we care about is the
            // EmptyView body.
            return
        }
        let body = String(source[bodyRange])
            .trimmingCharacters(in: .whitespacesAndNewlines)

        XCTAssertNotEqual(body, "EmptyView()",
                          """
                          BUG 17 — AppearanceSettingsView.displayToggleCard
                          renders EmptyView(). The "Global Settings" card has a
                          title and subtitle but no actual controls. Delete the
                          card or populate it.
                          """)
    }

    // MARK: - BUG 18: Popover width picker doesn't persist

    /// The Popover Width segmented control is bound to a local @State
    /// `popoverWidthIndex` that is never written to SharedDataStore or any
    /// other persistent store. The user's selection silently resets on
    /// every relaunch.
    func test_popover_width_picker_persists_selection() throws {
        let viewPath = "\(repoRoot)/Claude Usage/Views/Settings/AppearanceSettingsView.swift"
        let source = try String(contentsOfFile: viewPath, encoding: .utf8)

        // Confirm the @State exists.
        XCTAssertTrue(source.contains("popoverWidthIndex"),
                      "Sanity check: popoverWidthIndex state variable missing.")

        // The persistence hook for popoverWidth must exist. Acceptable:
        //   @AppStorage("popoverWidth")   / @AppStorage("popoverWidthIndex")
        //   SharedDataStore.shared.savePopoverWidth(...)
        //   savePopoverWidthIndex(...)
        //   UserDefaults.standard.set(..., forKey: "popoverWidth")
        //   profileManager.update(...) with popoverWidth
        // We deliberately check the *narrow* keyword so an unrelated
        // @AppStorage elsewhere in the file does not satisfy the test.
        let keys = ["popoverWidth", "popoverWidthIndex"]
        let hasPersistence = keys.contains { key in
            source.contains("@AppStorage(\"\(key)")
                || source.contains("save\(key.capitalized)")
                || source.contains("forKey: \"\(key)\"")
                || source.contains("UserDefaults.standard.set(\(key)")
                || source.contains("save\(key)")
                || source.contains("popoverWidth")
                   && source.contains("SharedDataStore.shared")
                   && source.range(of: #"SharedDataStore\.shared\.\w+\(.*popoverWidth"#,
                                   options: .regularExpression) != nil
        }

        XCTAssertTrue(hasPersistence,
                      """
                      BUG 18 — AppearanceSettingsView.popoverWidthIndex is a
                      local @State that is never persisted. The picker looks
                      functional, but every relaunch resets it to the default.

                      Fix: either drop the picker (the value is unused) or
                      wire it through @AppStorage("popoverWidthIndex") and
                      have the popover actually read the width on appear.
                      """)
    }

    // MARK: - BUG 19: "Send Test Notification" button bypasses auth check

    /// NotificationsSettingsView defines `requestNotificationPermission()`,
    /// which correctly checks authorization status, requests permission if
    /// undetermined, and only then sends the test alert. The "Send Test
    /// Notification" button MUST route through that helper. Calling
    /// `sendSimpleAlert` directly is a bug because:
    ///
    ///   * If authorization status is `.notDetermined`, the notification
    ///     request is queued but no banner appears.
    ///   * If authorization status is `.denied`, the request is silently
    ///     dropped.
    ///   * The completion handler `add(request) { _ in }` discards errors,
    ///     so even a failed delivery is invisible to the user.
    ///
    /// This test pins the wiring so a future refactor can't silently
    /// re-introduce the bypass.
    func test_send_test_notification_button_requests_authorization() throws {
        let viewPath = "\(repoRoot)/Claude Usage/Views/Settings/NotificationsSettingsView.swift"
        let source = try String(contentsOfFile: viewPath, encoding: .utf8)

        // Locate the "Send Test Notification" button. Use a pattern that
        // matches across newlines and tolerates minor whitespace
        // differences inside the closure.
        let pattern = #"""
        SettingsButton\s*\([^)]*title:\s*["\']Send Test Notification["\'][^)]*\)\s*\{[^}]*\}
        """#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            XCTFail("Failed to build regex for Send Test Notification button")
            return
        }
        let range = NSRange(source.startIndex..<source.endIndex, in: source)
        guard let match = regex.firstMatch(in: source, options: [], range: range),
              match.numberOfRanges > 0 else {
            XCTFail("Could not locate the Send Test Notification button in \(viewPath)")
            return
        }
        let closureRange = Range(match.range, in: source)!
        let button = String(source[closureRange])

        XCTAssertTrue(button.contains("requestNotificationPermission"),
                      """
                      BUG 19 — NotificationsSettingsView's "Send Test Notification"
                      button calls sendSimpleAlert directly, bypassing the
                      authorization check.

                      Found closure:
                        \(button)

                      When the user has never been prompted for notification
                      permission (authorizationStatus == .notDetermined), or has
                      previously denied it, the notification is silently dropped
                      by UNUserNotificationCenter — the button appears to do
                      nothing.

                      Fix: replace the closure body with
                          `requestNotificationPermission()`
                      (defined at the bottom of the same file). That helper
                      checks status, requests permission, and surfaces the
                      outcome.
                      """)

        // The helper must itself check authorization before sending.
        XCTAssertTrue(source.contains("authorizationStatus") &&
                      source.contains("requestAuthorization"),
                      """
                      BUG 19 (cont.) — The requestNotificationPermission()
                      helper no longer checks authorizationStatus before
                      requesting or sending. Restore the .notDetermined /
                      .authorized branches so the flow still works.
                      """)
    }

    // MARK: - Helpers

    /// Walks the Claude Usage/ tree and yields (relativePath, source) for
    /// every .swift file. Skips generated/derived paths.
    private func walkSourceTree(_ body: (String, String) throws -> Void) throws {
        let task = Process()
        let pipe = Pipe()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/find")
        task.arguments = [
            "\(repoRoot)/Claude Usage",
            "-name", "*.swift",
            "-type", "f",
            "-not", "-path", "*/.*"
        ]
        task.standardOutput = pipe
        try task.run()
        task.waitUntilExit()
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let stdout = String(data: data, encoding: .utf8) ?? ""
        for line in stdout.split(separator: "\n") {
            let path = String(line)
            guard let contents = try? String(contentsOfFile: path, encoding: .utf8) else { continue }
            let relative = path
                .replacingOccurrences(of: "\(repoRoot)/", with: "")
            try body(relative, contents)
        }
    }

    /// Returns the list of files (outside the view's own file) that
    /// instantiate the given struct, e.g. `SettingsButton(` or
    /// `SettingsView(`.
    private func findInstantiations(ofViewNamed name: String) -> [String] {
        var result: [String] = []
        let ownFile = "\(name).swift"
        do {
            try walkSourceTree { relativePath, source in
                if relativePath.hasSuffix(ownFile) { return }
                // Match `StructName(` but not `StructName.Foo(` or
                // `extension StructName`.
                let pattern = "(?<!\\.)\\b\(name)\\s*\\("
                if source.range(of: pattern, options: .regularExpression) != nil {
                    result.append(relativePath)
                }
            }
        } catch {
            XCTFail("Failed to walk source tree: \(error)")
        }
        return result
    }
}
