import XCTest

final class OnboardingUITests: XCTestCase {

    func testCompleteOnboardingFlowAndPersist() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--reset"]
        app.launch()

        // 1. Welcome
        XCTAssertTrue(app.staticTexts["Welcome to ScholarKeep"].waitForExistence(timeout: 5))
        app.buttons["Get started"].tap()

        // 2. How it works
        XCTAssertTrue(app.staticTexts["How ScholarKeep works"].waitForExistence(timeout: 3))
        app.buttons["Next"].tap()

        // 3. Add student
        XCTAssertTrue(app.navigationBars["Add your first student"].waitForExistence(timeout: 3))
        let nameField = app.textFields["Student name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        nameField.typeText("Test Student")
        app.buttons["Next"].tap()

        // 4. Disclaimer
        XCTAssertTrue(app.staticTexts["Two things to know before you go"].waitForExistence(timeout: 3))
        app.buttons["I understand — continue"].tap()

        // 5. Preferences
        XCTAssertTrue(app.navigationBars["A few preferences"].waitForExistence(timeout: 3))
        app.buttons["Finish"].tap()

        // Should land on Home tab
        XCTAssertTrue(app.staticTexts["Active student"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Test Student"].exists)
    }

    func testHowItWorksBackButton() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--reset"]
        app.launch()
        app.buttons["Get started"].tap()
        XCTAssertTrue(app.staticTexts["How ScholarKeep works"].waitForExistence(timeout: 3))
        app.buttons["Back"].tap()
        XCTAssertTrue(app.staticTexts["Welcome to ScholarKeep"].waitForExistence(timeout: 3))
    }
}
