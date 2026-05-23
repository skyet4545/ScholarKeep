import XCTest
@testable import ScholarKeep

final class ParserEdgeCaseTests: XCTestCase {

    private func line(_ text: String, y: CGFloat = 0.5) -> OCRLine {
        OCRLine(text: text, boundingBox: CGRect(x: 0, y: y, width: 1, height: 0.02))
    }

    func testEmptyReceipt() {
        let parsed = ReceiptParser.parse(lines: [])
        XCTAssertEqual(parsed.vendorName, "")
        XCTAssertNil(parsed.total)
        XCTAssertTrue(parsed.lineItems.isEmpty)
    }

    func testIgnoresPaymentLines() {
        let lines = [
            line("Vendor X", y: 0.95),
            line("Item A 10.00", y: 0.7),
            line("Subtotal 10.00", y: 0.5),
            line("Total 10.00", y: 0.4),
            line("Visa **** 1234   10.00", y: 0.3),
            line("Approved Auth 1234567", y: 0.25)
        ]
        let parsed = ReceiptParser.parse(lines: lines)
        // Payment lines should not appear as line items
        XCTAssertFalse(parsed.lineItems.contains { $0.descriptionText.lowercased().contains("visa") })
        XCTAssertFalse(parsed.lineItems.contains { $0.descriptionText.lowercased().contains("approved") })
    }

    func testTotalKeywordPriority() {
        let lines = [
            line("Some Store", y: 0.95),
            line("Item 100.00", y: 0.7),
            line("Subtotal 90.00", y: 0.5),
            line("Tax 7.20", y: 0.45),
            line("Grand Total 97.20", y: 0.4)
        ]
        let parsed = ReceiptParser.parse(lines: lines)
        XCTAssertEqual(parsed.total, Decimal(string: "97.20"))
        XCTAssertEqual(parsed.subtotal, Decimal(string: "90.00"))
        XCTAssertEqual(parsed.tax, Decimal(string: "7.20"))
    }

    func testVendorSkipsHeaderJunk() {
        let lines = [
            line("RECEIPT", y: 0.99),
            line("12345 Main Street", y: 0.98),
            line("Best Curriculum Co", y: 0.95),
            line("Item 1   10.00", y: 0.5)
        ]
        let parsed = ReceiptParser.parse(lines: lines)
        XCTAssertEqual(parsed.vendorName, "Best Curriculum Co")
    }

    func testHandlesLargeNumbersWithCommas() {
        let lines = [
            line("Big School Inc", y: 0.95),
            line("Annual Tuition 12,500.00", y: 0.6),
            line("Total 12,500.00", y: 0.3)
        ]
        let parsed = ReceiptParser.parse(lines: lines)
        XCTAssertEqual(parsed.total, Decimal(string: "12500.00"))
    }
}
