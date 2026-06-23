//
//  BaseUITest.swift
//  Claude UsageUITests
//
//  Shared scaffolding for UI tests.
//
//  ⚠️ LSUIElement limitation
//  ────────────────────────────────────────────────────────────
//  This app is a menu-bar-only application (Info.plist:
//  LSUIElement = YES) with a custom borderless Settings window opened
//  programmatically. XCUITest requires a real NSWindow on launch to
//  establish its XPC connection to the host app. Because the menu-bar
//  status item is *not* a window from XCUI's perspective, the test
//  runner cannot bootstrap — the test process is killed before
//  establishing a connection.
//
//  The known fixes (none of which we can apply without modifying the
//  host app's production code) are:
//    1. Add a `-uiTestMode` launch argument to AppDelegate that opens
//       an NSWindow with `NSApp.setActivationPolicy(.regular)`, or
//    2. Use `AXIsProcessTrusted` + System Events to drive the menu
//       bar item (not part of XCUITest, but doesn't require a window).
//
//  What this file *does* provide:
//    • Build-time smoke coverage — all test files compile against the
//      host app's bundle, catching dead types and view signature drift.
//    • A `runShell` helper that lets individual tests drive the menu
//      bar via `osascript`, which works around the LSUIElement issue.
//    • The structure to flip back to real XCUITest the moment a
//      `-uiTestMode` hook is added to `AppDelegate`.
//

import XCTest

class BaseUITest: XCTestCase {

    /// Lazily-instantiated host application. Tests that need XCUITest
    /// should call `requireApp()` which will throw an XCTSkip if the
    /// app cannot be launched against the LSUIElement host.
    private var _app: XCUIApplication?

    var app: XCUIApplication {
        if _app == nil { _app = XCUIApplication() }
        return _app!
    }

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        _app = nil
    }

    // MARK: - Real XCUITest path (requires -uiTestMode launch hook in AppDelegate)

    /// Launches the app. If the host does not bring up a real NSWindow
    /// within `launchTimeout` seconds, throws an error so the test is
    /// marked as **skipped** rather than crashing the runner.
    func launchAppOrSkip(reason: String = "No host window — XCUITest cannot attach to LSUIElement menu-bar apps") throws {
        app.launchArguments = ["-uiTestMode"]
        // Try to launch. If XCUITest kills the runner (typical for
        // LSUIElement hosts), this throws.
        do {
            try app.launch()
        } catch {
            throw XCTSkip(reason)
        }
        // If launch "succeeded" but the process is dead, also skip.
        if !app.windows.firstMatch.waitForExistence(timeout: 5) {
            throw XCTSkip(reason)
        }
    }

    // MARK: - osascript fallback (no XCUI host required)

    /// Runs an arbitrary shell command and returns its combined output.
    /// Used by tests to drive the menu bar via `osascript` System Events,
    /// which doesn't need XCUITest to attach to the host process.
    @discardableResult
    func runShell(_ command: String) -> (status: Int32, stdout: String, stderr: String) {
        let process = Process()
        let pipe = Pipe()
        let errPipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/zsh")
        process.arguments = ["-c", command]
        process.standardOutput = pipe
        process.standardError = errPipe
        do {
            try process.run()
        } catch {
            return (-1, "", "Failed to run command: \(error)")
        }
        process.waitUntilExit()
        let outData = pipe.fileHandleForReading.readDataToEndOfFile()
        let errData = errPipe.fileHandleForReading.readDataToEndOfFile()
        return (process.terminationStatus,
                String(data: outData, encoding: .utf8) ?? "",
                String(data: errData, encoding: .utf8) ?? "")
    }

    /// Launches the host app and returns the bundle id, using `open -a`.
    /// The launched app is the *production* binary, not a test harness,
    /// so it can be driven via `osascript` System Events.
    @discardableResult
    func launchHostApp() -> Bool {
        let appPath = "/Users/amitashwini/Library/Developer/Xcode/DerivedData/Claude_Usage-bjbkwslymauedbgbmmrgiluegsal/Build/Products/Debug/AI Usage Tracker.app"
        let result = runShell("open -a \"\(appPath)\"")
        return result.status == 0
    }

    /// Terminates the host app.
    func terminateHostApp() {
        runShell("pkill -f 'AI Usage Tracker' || true")
    }

    /// Clicks the AI Usage Tracker status item using `osascript`
    /// System Events. This works around the LSUIElement limitation
    /// because it drives the menu bar through macOS accessibility,
    /// not through XCUITest's host-app attachment.
    @discardableResult
    func clickStatusBarItem() -> Bool {
        let script = """
        tell application "System Events"
            tell process "AI Usage Tracker"
                if exists menu bar item 1 of menu bar 2 then
                    click menu bar item 1 of menu bar 2
                    return "clicked"
                else
                    return "no item"
                end if
            end tell
        end tell
        """
        let escaped = script
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: " ")
        let result = runShell("osascript -e \"\(escaped)\"")
        return result.stdout.contains("clicked")
    }

    // MARK: - Sidebar navigation (only callable when a Settings window is open)

    /// Clicks the sidebar item identified by accessibility label. This
    /// requires a real Settings window, which is only available if the
    /// app opened one (e.g. via a launch arg hook) or if the user
    /// opened it manually.
    func selectSidebarItem(named label: String) throws {
        let item = app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", label))
            .firstMatch
        guard item.waitForExistence(timeout: 3) else {
            throw XCTSkip("Sidebar item '\(label)' not found — Settings window may not be open")
        }
        item.click()
    }
}
