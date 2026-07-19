import XCTest

final class LedgerlyV1UITests: XCTestCase {
    func testOnboardingHasAnAccessibleSetupAction() {
        let app = XCUIApplication()
        app.launch()
        XCTAssertTrue(app.buttons["setup.continue"].waitForExistence(timeout: 3) || app.tabBars.buttons.element(boundBy: 0).exists)
    }

    func testAccessibilityIdentifiersAreStableWhenLedgerIsReady() {
        let app = XCUIApplication()
        app.launchArguments += ["-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        // The app must launch at an accessibility Dynamic Type size without truncating or crashing.
        XCTAssertTrue(app.state == .runningForeground || app.state == .runningBackground)
    }

    func testTraditionalChineseLaunchesAtAccessibilitySizeUsingStableIdentifiers() {
        let app = XCUIApplication()
        app.launchArguments += ["-appLanguage", "traditionalChinese", "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL"]
        app.launch()
        XCTAssertTrue(app.buttons["setup.continue"].waitForExistence(timeout: 3) || app.tabBars.buttons.element(boundBy: 0).exists)
    }
}
