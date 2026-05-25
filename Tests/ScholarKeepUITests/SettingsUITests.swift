import XCTest

final class SettingsUITests: XCTestCase {

    private func launchAndOnboard() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["--reset"]
        app.launch()
        app.buttons["Get started"].tap()
        app.buttons["Next"].tap() // How it works
        let nameField = app.textFields["Student name"]
        _ = nameField.waitForExistence(timeout: 3)
        nameField.tap()
        nameField.typeText("Test Student")
        app.buttons["Next"].tap()
        app.buttons["I understand — continue"].tap()
        app.buttons["Finish"].tap()
        _ = app.navigationBars["Home"].waitForExistence(timeout: 5)
        return app
    }

    func testSettingsScreenDisplaysAllSections() throws {
        let app = launchAndOnboard()
        app.tabBars.buttons["More"].tap()
        let settingsTile = app.buttons["moreTileSettings"]
        XCTAssertTrue(settingsTile.waitForExistence(timeout: 3))
        settingsTile.tap()
        XCTAssertTrue(app.navigationBars["Settings"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Privacy"].exists || app.staticTexts["Backup"].exists)
    }

    func testReferenceGuideLoads() throws {
        let app = launchAndOnboard()
        app.tabBars.buttons["More"].tap()
        let refButton = app.buttons["moreRowReferenceGuide"]
        XCTAssertTrue(refButton.waitForExistence(timeout: 3))
        refButton.tap()
        XCTAssertTrue(app.navigationBars["Reference"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["Florida ESA — 2026-27"].waitForExistence(timeout: 3))
    }
}
