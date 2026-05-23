import XCTest

final class OnboardingUITests: XCTestCase {

    func testCompleteOnboardingFlowAndPersist() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--reset"]
        app.launch()

        // Welcome screen
        XCTAssertTrue(app.staticTexts["Welcome to ScholarKeep"].waitForExistence(timeout: 5))
        app.buttons["Get started"].tap()

        // Disclaimer
        XCTAssertTrue(app.staticTexts["Important: read before continuing"].waitForExistence(timeout: 3))
        app.buttons["I understand — continue"].tap()

        // Add student
        XCTAssertTrue(app.staticTexts["Add your first student"].waitForExistence(timeout: 3))
        let nameField = app.textFields["Student name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        nameField.typeText("Test Student")

        // Submit name and proceed
        app.buttons["Next"].tap()

        // Preferences
        XCTAssertTrue(app.staticTexts["A few preferences"].waitForExistence(timeout: 3))
        app.buttons["Finish"].tap()

        // Should land on Home tab
        XCTAssertTrue(app.staticTexts["Active student"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Test Student"].exists)
    }

    func testDisclaimerBackButton() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--reset"]
        app.launch()
        app.buttons["Get started"].tap()
        XCTAssertTrue(app.staticTexts["Important: read before continuing"].waitForExistence(timeout: 3))
        app.buttons["Back"].tap()
        XCTAssertTrue(app.staticTexts["Welcome to ScholarKeep"].waitForExistence(timeout: 3))
    }
}
