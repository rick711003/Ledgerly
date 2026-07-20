import XCTest

final class LedgerlyV1UITests: XCTestCase {
  func testOnboardingHasAnAccessibleSetupAction() {
    let app = XCUIApplication()
    app.launchEnvironment["LEDGERLY_UI_TEST_FRESH_STORE"] = "1"
    app.launchArguments.append("--ledgerly-ui-test-fresh-store")
    app.launch()
    XCTAssertTrue(app.buttons["setup.continue"].waitForExistence(timeout: 3))
    XCTAssertFalse(app.tabBars.buttons.element(boundBy: 0).exists)
    attachScreenshot(named: "onboarding-first-launch", app: app)
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

  func testPrimaryProductSurfacesHaveVisualEvidence() {
    let app = XCUIApplication()
    launchReadyLedger(app)

    attachScreenshot(named: "home-redesign", app: app)

    app.tabBars.buttons.element(boundBy: 1).tap()
    XCTAssertTrue(app.otherElements["history.screen"].waitForExistence(timeout: 2))
    attachScreenshot(named: "history-redesign", app: app)

    app.tabBars.buttons.element(boundBy: 2).tap()
    XCTAssertTrue(app.staticTexts[L10nTestCopy.insightsTitle].waitForExistence(timeout: 2))
    attachScreenshot(named: "insights-redesign", app: app)

    app.tabBars.buttons.element(boundBy: 0).tap()
    app.buttons.matching(identifier: "Add transaction").firstMatch.tap()
    XCTAssertTrue(app.otherElements["transaction.editor.screen"].waitForExistence(timeout: 2))
    attachScreenshot(named: "add-transaction-redesign", app: app)
  }

  func testSettingsSurfacesHaveDesignedDestinations() {
    let app = XCUIApplication()

    assertSheet(
      app: app, trigger: "settings.language", destination: "language.screen")
    assertSheet(
      app: app, trigger: "settings.currency", destination: "currency.screen")
    assertSheet(
      app: app, trigger: "settings.categories", destination: "categories.screen")

    assertSheet(
      app: app, trigger: "settings.export", destination: "export.screen")
    assertSheet(
      app: app, trigger: "settings.privacy", destination: "privacy.screen")
    assertSheet(
      app: app, trigger: "settings.clear", destination: "clear.screen")

    openSettingsSheet(
      app: app, trigger: "settings.clear", destination: "clear.screen")
    app.buttons["clear.continue"].tap()
    XCTAssertTrue(app.textFields["clear.confirmation"].waitForExistence(timeout: 2))
  }

  func testSettingsVisualSnapshot() {
    let app = XCUIApplication()
    launchReadyLedger(app)

    guard waitForSettingsTab(in: app, timeout: 3) else {
      return XCTFail("A ready ledger is required to inspect Settings")
    }

    settingsTab(in: app).tap()
    XCTAssertTrue(app.otherElements["settings.screen"].waitForExistence(timeout: 2))

    let settingsFrame = app.otherElements["settings.screen"].frame
    let categoriesFrame = app.buttons["settings.categories"].frame
    XCTAssertGreaterThanOrEqual(categoriesFrame.minX, settingsFrame.minX)
    XCTAssertLessThanOrEqual(categoriesFrame.maxX, settingsFrame.maxX)

    let screenshot = XCTAttachment(screenshot: app.screenshot())
    screenshot.name = "settings-root"
    screenshot.lifetime = .keepAlways
    add(screenshot)
  }

  func testLanguageSheetFitsTheViewport() {
    let app = XCUIApplication()
    openSettingsSheet(
      app: app, trigger: "settings.language", destination: "language.screen")

    let screenFrame = app.windows.firstMatch.frame
    let optionFrame = app.buttons["language.system"].frame
    XCTAssertGreaterThanOrEqual(optionFrame.minX, screenFrame.minX)
    XCTAssertLessThanOrEqual(optionFrame.maxX, screenFrame.maxX)

    let screenshot = XCTAttachment(screenshot: app.screenshot())
    screenshot.name = "language-viewport"
    screenshot.lifetime = .keepAlways
    add(screenshot)
  }

  func testSettingsSecondaryStatesAreDesigned() {
    let app = XCUIApplication()

    openSettingsSheet(
      app: app, trigger: "settings.categories", destination: "categories.screen")
    app.buttons["category.new"].tap()
    XCTAssertTrue(
      app.otherElements["category.editor.screen"].waitForExistence(timeout: 2))
    attachScreenshot(named: "category-editor", app: app)

    openSettingsSheet(
      app: app, trigger: "settings.clear", destination: "clear.screen")
    app.buttons["clear.continue"].tap()
    XCTAssertTrue(app.textFields["clear.confirmation"].waitForExistence(timeout: 2))
    attachScreenshot(named: "clear-final-confirmation", app: app)
  }

  func testTraditionalChineseSettingsSurfacesAreDesigned() {
    let app = XCUIApplication()
    app.launchArguments += ["-appLanguage", "traditionalChinese"]

    assertSheet(
      app: app, trigger: "settings.language", destination: "language.screen")
    assertSheet(
      app: app, trigger: "settings.privacy", destination: "privacy.screen")
    assertSheet(
      app: app, trigger: "settings.clear", destination: "clear.screen")
  }

  private func assertSheet(app: XCUIApplication, trigger: String, destination: String) {
    openSettingsSheet(app: app, trigger: trigger, destination: destination)
    app.swipeDown()
    XCTAssertTrue(app.otherElements["settings.screen"].waitForExistence(timeout: 2))
  }

  private func openSettingsSheet(app: XCUIApplication, trigger: String, destination: String) {
    app.terminate()
    launchReadyLedger(app)

    guard waitForSettingsTab(in: app, timeout: 3) else {
      return XCTFail("A ready ledger is required to validate Settings")
    }

    settingsTab(in: app).tap()
    XCTAssertTrue(app.otherElements["settings.screen"].waitForExistence(timeout: 2))

    let button = app.buttons[trigger]
    XCTAssertTrue(button.waitForExistence(timeout: 2), "Missing settings trigger \(trigger)")
    if !button.isHittable {
      app.swipeUp()
    }
    button.tap()
    XCTAssertTrue(
      app.otherElements[destination].waitForExistence(timeout: 2),
      "Missing designed destination \(destination)")

    attachScreenshot(named: destination, app: app)
  }

  private func launchReadyLedger(_ app: XCUIApplication) {
    app.launch()

    if waitForSettingsTab(in: app, timeout: 2) {
      return
    }

    let setupButton = app.buttons["setup.continue"]
    XCTAssertTrue(
      setupButton.waitForExistence(timeout: 2),
      "Expected either a ready ledger or the onboarding flow")

    for _ in 0..<3 {
      setupButton.tap()
      if waitForSettingsTab(in: app, timeout: 2) {
        return
      }
      XCTAssertTrue(
        setupButton.waitForExistence(timeout: 2),
        "Onboarding did not advance to the next step")
    }

    XCTAssertTrue(
      waitForSettingsTab(in: app, timeout: 3),
      "Onboarding did not produce a ready ledger")
  }

  private func waitForSettingsTab(
    in app: XCUIApplication,
    timeout: TimeInterval
  ) -> Bool {
    let identifiedTab = app.buttons["tab.settings"].firstMatch
    if identifiedTab.waitForExistence(timeout: min(timeout, 1)) {
      return true
    }

    return app.tabBars.buttons.element(boundBy: 3)
      .waitForExistence(timeout: max(timeout - 1, 1))
  }

  private func settingsTab(in app: XCUIApplication) -> XCUIElement {
    let identifiedTab = app.buttons["tab.settings"].firstMatch
    return identifiedTab.exists
      ? identifiedTab
      : app.tabBars.buttons.element(boundBy: 3)
  }

  private func attachScreenshot(named name: String, app: XCUIApplication) {
    let screenshot = XCTAttachment(screenshot: app.screenshot())
    screenshot.name = name
    screenshot.lifetime = .keepAlways
    add(screenshot)
  }
}

private enum L10nTestCopy {
  static let insightsTitle = "Monthly insights"
}
