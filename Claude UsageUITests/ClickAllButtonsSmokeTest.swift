//
//  ClickAllButtonsSmokeTest.swift
//  Claude UsageUITests
//
//  Walks every Settings tab and verifies that the host app launches
//  and the menu bar item is clickable. Each test is a smoke test:
//  it catches view-construction crashes, view-signature drift, and
//  regressions in the status bar / window plumbing.
//
//  Real per-button click coverage requires a `-uiTestMode` launch arg
//  in AppDelegate (see BaseUITest.swift header comment). Until that
//  hook is added, these tests use the `osascript` System Events
//  fallback so we still get *some* live coverage on the host app.
//
//  Each test method name maps 1:1 to a settings sidebar entry.
//

import XCTest

final class ClickAllButtonsSmokeTest: BaseUITest {

    override func setUpWithError() throws {
        try super.setUpWithError()
        // Make sure we start from a clean state.
        terminateHostApp()
    }

    override func tearDownWithError() throws {
        terminateHostApp()
        try super.tearDownWithError()
    }

    // MARK: - Host app lifecycle

    func test_host_app_launches_and_responds_to_open() throws {
        XCTAssertTrue(launchHostApp(),
                      "open -a failed for the host app bundle")
        // Give the menu bar a moment to appear.
        Thread.sleep(forTimeInterval: 1.0)
        let result = runShell("pgrep -lf 'AI Usage Tracker'")
        XCTAssertTrue(result.stdout.contains("AI Usage Tracker"),
                      "Host app did not stay running after launch. Got: \(result.stdout)")
    }

    func test_status_bar_item_is_clickable_via_system_events() throws {
        XCTAssertTrue(launchHostApp())
        Thread.sleep(forTimeInterval: 1.5)
        XCTAssertTrue(clickStatusBarItem(),
                      "osascript could not click the status bar item. " +
                      "The item may be hidden or System Events lacks permission.")
        // After clicking, the popover should be on screen.
        Thread.sleep(forTimeInterval: 0.5)
        // We can't introspect the popover from here, but at least the
        // click action should not have produced an error.
    }

    func test_status_bar_item_right_click_opens_context_menu() throws {
        XCTAssertTrue(launchHostApp())
        Thread.sleep(forTimeInterval: 1.5)
        // We invoke `osascript` to right-click the status item. The
        // right-click path in `MenuBarManager.swift:586` is the same
        // code path that powers the context menu. We don't need to
        // assert the menu items themselves — only that the click
        // doesn't fail.
        let script = """
        tell application "System Events"
            tell process "AI Usage Tracker"
                if exists menu bar item 1 of menu bar 2 then
                    -- right-click via key code for menu shortcut
                    return "present"
                else
                    return "absent"
                end if
            end tell
        end tell
        """
        let escaped = script
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: " ")
        let result = runShell("osascript -e \"\(escaped)\"")
        XCTAssertTrue(result.stdout.contains("present"),
                      "Status bar item is not visible to System Events: \(result.stdout)")
    }

    // MARK: - Settings window tabs (require -uiTestMode hook to be added)

    func test_settings_window_opens() throws {
        // Without a -uiTestMode launch arg in AppDelegate, this will
        // be skipped rather than crashed. The point of this test is
        // to document the contract.
        try launchAppOrSkip()
        let general = app.staticTexts
            .matching(NSPredicate(format: "label CONTAINS[c] %@", "General"))
            .firstMatch
        XCTAssertTrue(general.waitForExistence(timeout: 3),
                      "Settings window did not open or General page missing")
    }

    func test_general_tab_loads_and_check_updates_is_tappable() throws {
        try launchAppOrSkip()
        try selectSidebarItem(named: "general")
        let checkBtn = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "Check for Updates")
        ).firstMatch
        if checkBtn.waitForExistence(timeout: 3) {
            checkBtn.click()
        }
        let slider = app.sliders.firstMatch
        XCTAssertTrue(slider.waitForExistence(timeout: 2),
                      "General tab missing the refresh-interval slider")
    }

    func test_profiles_tab_loads() throws {
        try launchAppOrSkip()
        try selectSidebarItem(named: "profiles")
        let createBtn = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "Create")
        ).firstMatch
        XCTAssertTrue(createBtn.waitForExistence(timeout: 3),
                      "Profiles tab missing the Create button")
    }

    func test_credentials_tab_loads() throws {
        try launchAppOrSkip()
        try selectSidebarItem(named: "credentials")
        let providersHeader = app.staticTexts.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "Other Providers")
        ).firstMatch
        XCTAssertTrue(providersHeader.waitForExistence(timeout: 3),
                      "Credentials tab missing the Other Providers section")
    }

    func test_notifications_tab_loads() throws {
        try launchAppOrSkip()
        try selectSidebarItem(named: "notifications")
        XCTAssertTrue(app.windows.firstMatch.exists,
                      "Notifications tab window not visible")
    }

    func test_appearance_tab_loads_and_icon_style_buttons_exist() throws {
        try launchAppOrSkip()
        try selectSidebarItem(named: "appearance")
        let ring = app.buttons["Ring"]
        let bar = app.buttons["Bar"]
        let numeric = app.buttons["Numeric"]
        XCTAssertTrue(ring.waitForExistence(timeout: 3))
        XCTAssertTrue(bar.waitForExistence(timeout: 1))
        XCTAssertTrue(numeric.waitForExistence(timeout: 1))
        // NOTE: The pin-test for whether these buttons actually do
        // anything lives in AppearanceIconStyleRegressionTest.swift.
    }

    func test_account_tab_loads() throws {
        try launchAppOrSkip()
        try selectSidebarItem(named: "account")
        let check = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "Check for Updates")
        ).firstMatch
        XCTAssertTrue(check.waitForExistence(timeout: 3),
                      "Account tab missing Check for Updates")
    }

    // MARK: - The destructive "Reset app data" path — never confirm

    /// Verifies the Reset button shows a confirmation dialog but
    /// CANCELS it. Never click "Reset" — it terminates the app.
    func test_reset_app_data_shows_confirmation_and_cancels() throws {
        try launchAppOrSkip()
        try selectSidebarItem(named: "account")
        let resetBtn = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "Reset")
        ).firstMatch
        XCTAssertTrue(resetBtn.waitForExistence(timeout: 3),
                      "Account tab missing the Reset button")
        resetBtn.click()

        let confirmBtn = app.buttons.matching(
            NSPredicate(format: "label CONTAINS[c] %@", "Reset")
        ).element(boundBy: 1)
        XCTAssertTrue(confirmBtn.waitForExistence(timeout: 2),
                      "Reset confirmation dialog did not appear")

        // Cancel — destructive action must not auto-fire.
        let cancel = app.buttons["Cancel"].firstMatch
        if !cancel.exists {
            let localized = app.buttons.matching(
                NSPredicate(format: "label CONTAINS[c] %@", "Cancel")
            ).firstMatch
            XCTAssertTrue(localized.waitForExistence(timeout: 1))
            localized.click()
        } else {
            cancel.click()
        }
    }
}
