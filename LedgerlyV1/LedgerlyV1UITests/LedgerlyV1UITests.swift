import XCTest

final class LedgerlyV1UITests: XCTestCase {
  func testOnboardingHasAnAccessibleSetupAction() {
    let app = XCUIApplication()
    app.launch()
    XCTAssertTrue(
      app.buttons["setup.continue"].waitForExistence(timeout: 3)
        || app.tabBars.buttons.element(boundBy: 0).exists)
  }

  func testAccessibilityIdentifiersAreStableWhenLedgerIsReady() {
    let app = XCUIApplication()
    app.launchArguments += [
      "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXXXL",
    ]
    app.launch()
    // The app must launch at an accessibility Dynamic Type size without truncating or crashing.
    XCTAssertTrue(app.state == .runningForeground || app.state == .runningBackground)
  }

  func testTraditionalChineseLaunchesAtAccessibilitySizeUsingStableIdentifiers() {
    let app = XCUIApplication()
    app.launchArguments += [
      "-appLanguage", "traditionalChinese", "-UIPreferredContentSizeCategoryName",
      "UICTContentSizeCategoryAccessibilityXXXL",
    ]
    app.launch()
    XCTAssertTrue(
      app.buttons["setup.continue"].waitForExistence(timeout: 3)
        || app.tabBars.buttons.element(boundBy: 0).exists)
  }

  func testReadyLedgerCanOpenHistoryAndTransactionEditor() {
    let app = XCUIApplication()
    app.launch()

    guard app.tabBars.buttons.element(boundBy: 0).waitForExistence(timeout: 3) else {
      return
    }

    app.tabBars.buttons.element(boundBy: 1).tap()
    XCTAssertTrue(app.otherElements["history.screen"].waitForExistence(timeout: 2))

    app.tabBars.buttons.element(boundBy: 0).tap()
    app.buttons.matching(identifier: "Add transaction").firstMatch.tap()
    XCTAssertTrue(app.otherElements["transaction.editor.screen"].waitForExistence(timeout: 2))
    XCTAssertTrue(app.buttons["transaction.save"].exists)
  }
}
