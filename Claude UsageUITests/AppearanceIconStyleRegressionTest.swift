//
//  AppearanceIconStyleRegressionTest.swift
//  Claude UsageUITests
//
//  Verifies that the Icon Style picker (Ring / Bar / Numeric) in
//  AppearanceSettingsView is actually wired up. Originally pinned
//  BUG 1 (empty `selectIconStyle` body, hard-coded `currentIconStyle`).
//  BUG 1 is now fixed: `selectIconStyle` mutates the configuration and
//  `currentIconStyle` derives from `selectedIconStyleKey`. The tests
//  below assert the *correct* behavior — they will fail loudly if the
//  fix is regressed.
//
//  This is a *static analysis* regression test — it does not require
//  XCUITest to attach to the host (see BaseUITest header for the
//  LSUIElement explanation).
//

import XCTest

final class AppearanceIconStyleRegressionTest: BaseUITest {

    private let appearanceViewPath = "/Users/amitashwini/Projects/Claude Usage Optimizer/Claude-Usage-Optimizer/Claude Usage/Views/Settings/AppearanceSettingsView.swift"

    func test_selectIconStyle_has_real_body() throws {
        let source = try String(contentsOfFile: appearanceViewPath, encoding: .utf8)

        // Find the body of selectIconStyle. Use [\s\S] to match across
        // lines and accept nested braces (e.g. `else { return }`).
        let pattern = "private func selectIconStyle\\(_ style: String\\) \\{([\\s\\S]+?\\})\\s*\\n\\s*\\}"
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
        var captured = String(source[bodyRange]).trimmingCharacters(in: .whitespacesAndNewlines)
        if captured.hasPrefix("{") { captured.removeFirst() }
        if captured.hasSuffix("}") { captured.removeLast() }
        let body = captured.trimmingCharacters(in: .whitespacesAndNewlines)

        XCTAssertFalse(body.isEmpty, """
        REGRESSION: selectIconStyle(_:) in AppearanceSettingsView.swift has an empty body.
        Tapping the Ring / Bar / Numeric buttons does not change the icon style.

        (Originally pinned as BUG 1 — fixed by selecting from ProfileManager config.)
        """)
        XCTAssertTrue(body.contains("saveConfiguration"),
                      "selectIconStyle must persist via saveConfiguration() so the change reaches ProfileManager.")
    }

    func test_currentIconStyle_is_not_hardcoded() throws {
        let source = try String(contentsOfFile: appearanceViewPath, encoding: .utf8)

        // The original bug was a getter that returned the literal "ring":
        //   private var currentIconStyle: String {
        //       return "ring"
        //   }
        // That would make the picker highlight "ring" forever.
        let hardCoded = "private var currentIconStyle: String {\n        return \"ring\"\n    }"
        XCTAssertFalse(source.contains(hardCoded), """
        REGRESSION: currentIconStyle in AppearanceSettingsView.swift is hard-coded
        to return "ring", so the icon-style selection can never change.

        (Originally pinned as BUG 1 — now derives from selectedIconStyleKey.)
        """)
    }
}
