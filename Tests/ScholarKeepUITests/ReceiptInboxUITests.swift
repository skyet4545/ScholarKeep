import XCTest

final class ReceiptInboxUITests: XCTestCase {

    func testDemoReceiptCanBeReviewed() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--demo", "--tab", "more"]
        app.launch()

        let inboxRow = app.staticTexts["Receipt Inbox"]
        guard inboxRow.waitForExistence(timeout: 5) else {
            XCTFail("Receipt Inbox row did not appear")
            return
        }
        XCTAssertTrue(app.staticTexts["1 waiting for review"].exists)
        inboxRow.tap()

        guard app.navigationBars["Receipt Inbox"].waitForExistence(timeout: 3) else {
            XCTFail("Receipt Inbox did not open")
            return
        }
        XCTAssertTrue(app.staticTexts["Connected email"].exists)
        guard app.staticTexts["Rainbow Resource Center"].waitForExistence(timeout: 3) else {
            XCTFail("Seeded receipt did not appear")
            return
        }
        XCTAssertTrue(app.staticTexts["$64.72"].exists)

        app.staticTexts["Rainbow Resource Center"].tap()

        XCTAssertTrue(app.navigationBars["Review Receipt"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.staticTexts["No image or PDF was attached"].exists)
        app.swipeUp()
        XCTAssertTrue(app.buttons["Save as draft expense"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["Not a receipt"].exists)
    }
}
