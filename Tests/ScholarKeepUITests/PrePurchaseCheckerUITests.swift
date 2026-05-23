import XCTest

final class PrePurchaseCheckerUITests: XCTestCase {

    private func launchAndOnboard(_ name: String = "Test Student") -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--reset"]
        app.launch()
        app.buttons["Get started"].tap()
        app.buttons["I understand — continue"].tap()
        let nameField = app.textFields["Student name"]
        _ = nameField.waitForExistence(timeout: 3)
        nameField.tap()
        nameField.typeText(name)
        app.buttons["Next"].tap()
        app.buttons["Finish"].tap()
        _ = app.staticTexts["Active student"].waitForExistence(timeout: 5)
        return app
    }

    func testIneligibleGasShowsIneligibleVerdict() throws {
        let app = launchAndOnboard()
        // Navigate to Check tab
        app.tabBars.buttons["Check"].tap()
        XCTAssertTrue(app.navigationBars["Can I buy this?"].waitForExistence(timeout: 3))

        // Chat-style input: amount capsule + description capsule
        let amountField = app.textFields["Amount"]
        XCTAssertTrue(amountField.waitForExistence(timeout: 3))
        amountField.tap()
        amountField.typeText("40")

        let descField = app.textFields["Describe what you're buying"]
        XCTAssertTrue(descField.exists)
        descField.tap()
        descField.typeText("Gas for co-op drive")

        // Tap the send arrow that appears once input is non-empty
        let sendButton = app.buttons["sendChat"]
        XCTAssertTrue(sendButton.waitForExistence(timeout: 3))
        sendButton.tap()

        // Bot bubble should render an Ineligible verdict header
        XCTAssertTrue(app.staticTexts["Ineligible"].waitForExistence(timeout: 5))
    }
}
