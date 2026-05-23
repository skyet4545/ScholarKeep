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

        // Describe purchase (SwiftUI vertical-axis TextField shows as a textField in XCUITest)
        let descField = app.textFields["Describe the item or service"]
        XCTAssertTrue(descField.waitForExistence(timeout: 3))
        descField.tap()
        descField.typeText("Gas for co-op drive")

        // Amount field uses "0.00" placeholder
        let amountField = app.textFields["0.00"]
        XCTAssertTrue(amountField.exists)
        amountField.tap()
        amountField.typeText("40")

        app.buttons["Check eligibility"].tap()
        // Result section should show Ineligible label
        XCTAssertTrue(app.staticTexts["Ineligible"].waitForExistence(timeout: 5))
    }
}
