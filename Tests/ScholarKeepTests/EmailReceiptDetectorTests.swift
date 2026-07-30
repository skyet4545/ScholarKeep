import XCTest
@testable import ScholarKeep

final class EmailReceiptDetectorTests: XCTestCase {
    func testReceiptSubjectAmountAndAttachmentPassThreshold() {
        let result = EmailReceiptDetector.evaluate(
            subject: "Your Lakeshore order receipt",
            sender: "Lakeshore Learning <orders@example.com>",
            snippet: "Order #12345",
            bodyText: "Subtotal $38.00\nTax $2.66\nTotal paid $40.66",
            hasReceiptAttachment: true
        )

        XCTAssertTrue(result.isLikelyReceipt)
        XCTAssertGreaterThanOrEqual(result.score, 8)
    }

    func testSecurityEmailIsRejected() {
        let result = EmailReceiptDetector.evaluate(
            subject: "Security alert",
            sender: "Account Team <security@example.com>",
            snippet: "A new device signed in",
            bodyText: "",
            hasReceiptAttachment: false
        )

        XCTAssertFalse(result.isLikelyReceipt)
    }

    func testInfersDisplayNameAsVendor() {
        XCTAssertEqual(
            EmailReceiptDetector.inferredVendor(
                sender: "Office Depot <orders@officedepot.com>",
                subject: "Your receipt"
            ),
            "Office Depot"
        )
    }

    func testInfersAmountsFromEmailText() {
        let amounts = EmailReceiptDetector.inferredAmounts(
            from: "Subtotal: $18.99\nTax: $1.33\nOrder total: $20.32"
        )

        XCTAssertEqual(amounts.subtotal, Decimal(string: "18.99"))
        XCTAssertEqual(amounts.tax, Decimal(string: "1.33"))
        XCTAssertEqual(amounts.total, Decimal(string: "20.32"))
    }
}
