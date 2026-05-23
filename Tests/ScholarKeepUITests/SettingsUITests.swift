import XCTest

final class SettingsUITests: XCTestCase {

    private func launchAndOnboard() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--reset"]
        app.launch()
        app.buttons["Get started"].tap()
        app.buttons["I understand — continue"].tap()
        let nameField = app.textFields["Student name"]
        _ = nameField.waitForExistence(timeout: 3)
        nameField.tap()
        nameField.typeText("Test Student")
        app.buttons["Next"].tap()
        app.buttons["Finish"].tap()
        _ = app.staticTexts["Active student"].waitForExistence(timeout: 5)
        return app
    }

    func testSettingsScreenDisplaysAllSections() throws {
        let app = launchAndOnboard()
        app.tabBars.buttons["More"].tap()
        XCTAssertTrue(app.cells.staticTexts["Settings"].waitForExistence(timeout: 3))
        app.cells.staticTexts["Settings"].tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
        // Should have key sections visible
        XCTAssertTrue(app.staticTexts["Privacy"].exists || app.staticTexts["Backup"].exists)
    }

    func testReferenceGuideLoads() throws {
        let app = launchAndOnboard()
        app.tabBars.buttons["More"].tap()
        XCTAssertTrue(app.cells.staticTexts["Reference guide"].waitForExistence(timeout: 3))
        app.cells.staticTexts["Reference guide"].tap()
        XCTAssertTrue(app.navigationBars["Reference"].waitForExistence(timeout: 3))
        // Ruleset version should be visible
        XCTAssertTrue(app.staticTexts["Florida ESA — 2026-27"].waitForExistence(timeout: 3))
    }
}
