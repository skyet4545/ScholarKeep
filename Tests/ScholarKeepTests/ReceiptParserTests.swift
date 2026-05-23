import XCTest
@testable import ScholarKeep

final class ReceiptParserTests: XCTestCase {
    func testParsesTotalSubtotalTax() {
        let lines: [OCRLine] = [
            line("Office Depot", y: 0.95),
            line("123 Main St", y: 0.90),
            line("Spiral Notebook  3.99", y: 0.70),
            line("Composition Book 4.50", y: 0.65),
            line("Subtotal 8.49", y: 0.40),
            line("Tax 0.59", y: 0.35),
            line("Total 9.08", y: 0.30)
        ]
        let parsed = ReceiptParser.parse(lines: lines)
        XCTAssertEqual(parsed.vendorName, "Office Depot")
        XCTAssertEqual(parsed.subtotal, Decimal(string: "8.49"))
        XCTAssertEqual(parsed.tax, Decimal(string: "0.59"))
        XCTAssertEqual(parsed.total, Decimal(string: "9.08"))
        XCTAssertEqual(parsed.lineItems.count, 2)
    }

    func testFallsBackToLargestAmountWhenNoTotalLabel() {
        let lines: [OCRLine] = [
            line("Vendor Y", y: 0.95),
            line("Item A 5.00", y: 0.7),
            line("Item B 12.50", y: 0.6),
            line("Item C 3.25", y: 0.5)
        ]
        let parsed = ReceiptParser.parse(lines: lines)
        XCTAssertEqual(parsed.total, Decimal(string: "12.50"))
    }

    private func line(_ text: String, y: CGFloat) -> OCRLine {
        OCRLine(text: text, boundingBox: CGRect(x: 0, y: y, width: 1, height: 0.02))
    }
}
