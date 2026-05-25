import XCTest

final class OnboardingUITests: XCTestCase {

    func testCompleteOnboardingFlowAndPersist() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--reset"]
        app.launch()

        // 1. Welcome — Journal-style title splits "Welcome to" + "ScholarKeep"
        XCTAssertTrue(app.staticTexts["ScholarKeep"].waitForExistence(timeout: 5))
        app.buttons["Get started"].tap()

        // 2. How it works — Journal header text
        XCTAssertTrue(app.staticTexts["How it works"].waitForExistence(timeout: 3))
        app.buttons["Next"].tap()

        // 3. Add student — Journal header text (no nav bar in custom screens)
        XCTAssertTrue(app.staticTexts["Add your first student"].waitForExistence(timeout: 3))
        let nameField = app.textFields["Student name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        nameField.typeText("Test Student")
        app.buttons["Next"].tap()

        // 4. Disclaimer
        XCTAssertTrue(app.staticTexts["Two things to know"].waitForExistence(timeout: 3))
        app.buttons["I understand — continue"].tap()

        // 5. Preferences
        XCTAssertTrue(app.staticTexts["A few preferences"].waitForExistence(timeout: 3))
        app.buttons["Finish"].tap()

        // Should land on Home tab
        XCTAssertTrue(app.navigationBars["Home"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Test Student"].waitForExistence(timeout: 3))
    }

    func testHowItWorksBackButton() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--reset"]
        app.launch()
        app.buttons["Get started"].tap()
        XCTAssertTrue(app.staticTexts["How it works"].waitForExistence(timeout: 3))
        app.buttons["Back"].tap()
        XCTAssertTrue(app.staticTexts["ScholarKeep"].waitForExistence(timeout: 3))
    }
}
