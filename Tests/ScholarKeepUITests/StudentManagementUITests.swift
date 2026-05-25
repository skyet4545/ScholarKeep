import XCTest

final class StudentManagementUITests: XCTestCase {

    private func launchAndOnboard(_ name: String = "First Kid") -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--reset"]
        app.launch()
        app.buttons["Get started"].tap()
        app.buttons["Next"].tap() // How it works
        let nameField = app.textFields["Student name"]
        _ = nameField.waitForExistence(timeout: 3)
        nameField.tap()
        nameField.typeText(name)
        app.buttons["Next"].tap()
        app.buttons["I understand — continue"].tap()
        app.buttons["Finish"].tap()
        _ = app.navigationBars["Home"].waitForExistence(timeout: 5)
        return app
    }

    func testCanAddSecondStudent() throws {
        let app = launchAndOnboard()
        app.tabBars.buttons["More"].tap()
        let studentsTile = app.buttons["moreTileStudents"]
        XCTAssertTrue(studentsTile.waitForExistence(timeout: 3))
        studentsTile.tap()

        XCTAssertTrue(app.navigationBars["Students"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["First Kid"].exists)

        // Tap + to add
        app.buttons["Add student"].tap()

        let nameField = app.textFields["Student name"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 3))
        nameField.tap()
        nameField.typeText("Second Kid")

        app.buttons["Save"].tap()

        XCTAssertTrue(app.staticTexts["Second Kid"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["First Kid"].exists)
    }
}
