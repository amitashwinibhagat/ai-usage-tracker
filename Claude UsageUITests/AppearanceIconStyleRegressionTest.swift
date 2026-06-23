//
//  AppearanceIconStyleRegressionTest.swift
//  Claude UsageUITests
//
//  Pins the bug found in the click-test audit (BUG 1):
//  `selectIconStyle(_:)` in `AppearanceSettingsView.swift` is an empty
//  function and `currentIconStyle` is hard-coded to "ring". The icon
//  style buttons (Ring / Bar / Numeric) are clickable but the tap
//  produces no visible change.
//
//  This is a *static analysis* regression test — it does not require
//  XCUITest to attach to the host (see BaseUITest header for the
//  LSUIElement explanation). It reads the source file from disk and
//  asserts on its content. When the bug is fixed, the assertions must
//  be inverted, at which point the test starts failing loudly until
//  the engineer updates the expected value to the new correct value.
//

import XCTest

final class AppearanceIconStyleRegressionTest: BaseUITest {

    private let appearanceViewPath = "/Users/amitashwini/Projects/Claude Usage Optimizer/Claude-Usage-Optimizer/Claude Usage/Views/Settings/AppearanceSettingsView.swift"

    func test_selectIconStyle_is_not_empty() throws {
        let source = try String(contentsOfFile: appearanceViewPath, encoding: .utf8)

        // Find the body of selectIconStyle. The current code has:
        //   private func selectIconStyle(_ style: String) {
        //   }
        // i.e. an empty function body. We assert that the function
        // contains at least one statement (something between { and }).
        let pattern = #"private func selectIconStyle\(_ style: String\) \{([^}]*)\}"#
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.dotMatchesLineSeparators]) else {
            XCTFail("Failed to build regex")
            return
        }
        let range = NSRange(source.startIndex..<source.endIndex, in: source)
        guard let match = regex.firstMatch(in: source, options: [], range: range) else {
            XCTFail("selectIconStyle function not found in \(appearanceViewPath)")
            return
        }
        guard match.numberOfRanges > 1,
              let bodyRange = Range(match.range(at: 1), in: source) else {
            XCTFail("Could not extract selectIconStyle body")
            return
        }
        let body = String(source[bodyRange])
            .trimmingCharacters(in: .whitespacesAndNewlines)

        XCTAssertFalse(body.isEmpty, """
        BUG 1 PIN — REGRESSION DETECTED.

        selectIconStyle(_:) in AppearanceSettingsView.swift has an empty body.
        Tapping the Ring / Bar / Numeric buttons in Appearance settings does
        not change the icon style.

        To fix:
          1. Add a @State var currentIconStyle in AppearanceSettingsView
          2. In selectIconStyle(_:), set it: self.currentIconStyle = style
          3. Persist the change via profileManager.updateIconConfig(...)
          4. Update iconStylePickerRow to use the binding state

        This test will fail loudly the moment a real implementation is
        committed, which is the correct behaviour for a regression pin.
        """)
    }

    func test_currentIconStyle_is_not_hardcoded() throws {
        let source = try String(contentsOfFile: appearanceViewPath, encoding: .utf8)

        // Find the getter for currentIconStyle. The current bug has:
        //   private var currentIconStyle: String {
        //       return "ring"
        //   }
        // A fixed version would derive it from `configuration` or a
        // @State property.
        let hardCoded = "private var currentIconStyle: String {\n        return \"ring\"\n    }"
        XCTAssertFalse(source.contains(hardCoded), """
        BUG 1 PIN — REGRESSION DETECTED.

        currentIconStyle in AppearanceSettingsView.swift is hard-coded
        to return "ring", so the icon-style selection can never change.

        Fix: replace the hard-coded return with a derived value from
        configuration or a @State binding.
        """)
    }
}
