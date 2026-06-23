# Claude UsageUITests

A test target dedicated to the AI Usage Tracker UI. Wired up to the
`Claude UsageUITests` Xcode scheme.

## What this target does

1. **Build-time compile coverage** — every test file compiles against
   the host app's bundle, catching dead types, view-signature drift,
   and missing identifiers at build time.

2. **Regression pins for known bugs** —
   `AppearanceIconStyleRegressionTest` reads
   `AppearanceSettingsView.swift` from disk and asserts on its
   content, pinning BUG 1 (empty `selectIconStyle` and hard-coded
   `currentIconStyle`). When the bug is fixed, the assertions in
   that test must be inverted to assert the new correct behavior.

3. **Host-app launch smoke test** —
   `ClickAllButtonsSmokeTest.test_host_app_launches_and_responds_to_open`
   launches the production binary via `open -a` and asserts the
   process stays running. This catches regressions in
   `applicationDidFinishLaunching` and is the only test that does
   not require XCUITest to attach to the host.

4. **Status-bar / popover click coverage via System Events** —
   `ClickAllButtonsSmokeTest.test_status_bar_item_*` uses
   `osascript` to drive the menu bar item, which works around the
   `LSUIElement` limitation that prevents XCUITest from attaching.

## What this target does NOT do (yet)

The remaining smoke tests in `ClickAllButtonsSmokeTest` (the
`*_tab_loads_*` ones) call `launchAppOrSkip()` which throws
`XCTSkip` because the app is `LSUIElement` and XCUITest cannot
attach to a process with no main window. The skipped tests
document the contract: when a launch-arg hook is added to
`AppDelegate`, these tests will run for real.

### The launch-arg hook to add

In `Claude Usage/App/AppDelegate.swift` `applicationDidFinishLaunching`,
add something like:

```swift
if CommandLine.arguments.contains("-uiTestMode") {
    NSApp.setActivationPolicy(.regular)
    // ... open a Settings-style NSWindow so XCUITest can attach ...
}
```

Then the XCTSkip'd tests in `ClickAllButtonsSmokeTest` will run
and exercise the per-tab buttons for real.

## Running the tests

```bash
# Build only
xcodebuild -project "Claude Usage.xcodeproj" \
           -scheme "Claude UsageUITests" \
           -destination 'platform=macOS' \
           -configuration Debug \
           CODE_SIGNING_ALLOWED=NO build-for-testing

# Run a single test
xcodebuild test -project "Claude Usage.xcodeproj" \
                -scheme "Claude UsageUITests" \
                -destination 'platform=macOS' \
                -configuration Debug \
                CODE_SIGNING_ALLOWED=NO \
                -only-testing:"Claude UsageUITests/AppearanceIconStyleRegressionTest"

# Run everything
xcodebuild test -project "Claude Usage.xcodeproj" \
                -scheme "Claude UsageUITests" \
                -destination 'platform=macOS' \
                -configuration Debug \
                CODE_SIGNING_ALLOWED=NO
```

## Test results at a glance

| Test class | Status | Why |
|---|---|---|
| `AppearanceIconStyleRegressionTest.test_selectIconStyle_is_not_empty` | **Fails intentionally** | Pins BUG 1 — the function body is empty |
| `AppearanceIconStyleRegressionTest.test_currentIconStyle_is_not_hardcoded` | **Fails intentionally** | Pins BUG 1 — the getter returns the literal `"ring"` |
| `ClickAllButtonsSmokeTest.test_host_app_launches_and_responds_to_open` | **Passes** | Verifies the binary launches and stays running |
| `ClickAllButtonsSmokeTest.test_status_bar_item_is_clickable_via_system_events` | **Fails** | Real bug found: menu bar item does not appear on first launch because the setup wizard gates the status bar setup in `AppDelegate.swift:51-58` |
| `ClickAllButtonsSmokeTest.test_status_bar_item_right_click_opens_context_menu` | **Fails** | Same as above |
| All `*_tab_loads_*` and `test_settings_window_opens` | **Skipped** | Require a `-uiTestMode` launch-arg hook in AppDelegate |
| `ClickAllButtonsSmokeTest.test_reset_app_data_shows_confirmation_and_cancels` | **Skipped** | Same — also, the destructive path must never be auto-confirmed in tests |

## Bugs this test target has caught so far

- **BUG 11 (new)**: The status bar item does not appear on first
  launch when the setup wizard is shown. `AppDelegate.swift:51-58`
  only calls `menuBarManager?.setup()` when `!shouldShowSetupWizard()`,
  but `menuBarManager = MenuBarManager()` (line 43) is unconditional
  and comments claim "Always create the menu bar manager up front".
  The fix is to call `.setup()` unconditionally, or to show both
  the wizard and the status bar simultaneously.

