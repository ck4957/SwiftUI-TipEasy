import XCTest

final class AppStoreScreenshotUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
    }

    override func tearDownWithError() throws {
        app = nil
    }

    @MainActor
    func testCaptureOnboardingScreenshots() throws {
        launch(scenario: "onboarding")

        XCTAssertTrue(app.staticTexts["Compare Tips Fast"].waitForExistence(timeout: 10))
        try capture("01-onboarding-calculate")

        app.buttons["Next"].tap()
        XCTAssertTrue(app.staticTexts["Scan a Receipt"].waitForExistence(timeout: 5))
        try capture("02-onboarding-scan")

        app.buttons["Next"].tap()
        XCTAssertTrue(app.staticTexts["Save the Visit"].waitForExistence(timeout: 5))
        try capture("03-onboarding-save")
    }

    @MainActor
    func testCaptureMainFlowScreenshots() throws {
        launch(scenario: "main-flow")

        XCTAssertTrue(app.staticTexts["Bill"].waitForExistence(timeout: 10))
        try capture("04-calculator-empty")

        let billField = app.textFields["Bill amount"]
        XCTAssertTrue(billField.waitForExistence(timeout: 5))
        billField.tap()
        billField.typeText("86.40")

        app.textFields["Place name (optional)"].tap()
        app.textFields["Place name (optional)"].typeText("Juniper Table")

        app.buttons["20 percent tip"].tap()
        app.toolbars.buttons["Done"].tap()
        try capture("05-calculator-total")

        try tapPrimaryNavigationItem("History")
        XCTAssertTrue(app.staticTexts["Local Totals"].waitForExistence(timeout: 5))
        try capture("06-history")

        try tapPrimaryNavigationItem("Settings")
        XCTAssertTrue(app.staticTexts["Quick Guide"].waitForExistence(timeout: 5))
        try capture("07-settings")
    }

    @MainActor
    private func launch(scenario: String) {
        app = XCUIApplication()
        app.launchArguments = [
            "-scanTipScreenshotAutomation",
            "-scanTipScreenshotScenario",
            scenario,
            "-AppleLanguages",
            "(en)",
            "-AppleLocale",
            "en_US"
        ]
        app.launch()
    }

    private func capture(_ name: String) throws {
        sleep(1)

        let screenshot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)

        guard let outputDirectory = ProcessInfo.processInfo.environment["SCREENSHOT_OUTPUT_DIR"],
              !outputDirectory.isEmpty else {
            return
        }

        let devicePrefix = ProcessInfo.processInfo.environment["SCREENSHOT_DEVICE_PREFIX"] ?? "simulator"
        let directoryURL = URL(fileURLWithPath: outputDirectory, isDirectory: true)
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)

        let fileURL = directoryURL.appendingPathComponent("\(devicePrefix)-\(name).png")
        try screenshot.pngRepresentation.write(to: fileURL, options: .atomic)
    }

    @MainActor
    private func tapPrimaryNavigationItem(_ label: String) throws {
        let tabBarButton = app.tabBars.buttons[label]
        if tabBarButton.waitForExistence(timeout: 2) {
            tabBarButton.firstMatch.tap()
            return
        }

        let button = app.buttons[label]
        if button.waitForExistence(timeout: 2) {
            button.firstMatch.tap()
            return
        }

        let text = app.staticTexts[label]
        if text.waitForExistence(timeout: 2) {
            text.tap()
            return
        }

        XCTFail("Could not find navigation item named \(label).")
    }
}
