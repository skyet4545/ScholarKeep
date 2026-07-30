import XCTest
@testable import ScholarKeep

final class ReceiptCandidateTests: XCTestCase {
    func testLineItemsRoundTripAndStatusTransition() {
        let candidate = ReceiptCandidate(
            source: .gmail,
            sourceMessageID: "message-123",
            sender: "Vendor <orders@example.com>",
            subject: "Receipt",
            receivedAt: .now,
            snippet: "",
            bodyText: "",
            suggestedLineItems: [
                ParsedLineItem(descriptionText: "Math workbook", amount: 14.99),
                ParsedLineItem(descriptionText: "Pencils", amount: 3.50)
            ]
        )

        XCTAssertEqual(candidate.suggestedLineItems.count, 2)
        XCTAssertEqual(candidate.suggestedLineItems[0].descriptionText, "Math workbook")
        XCTAssertEqual(candidate.status, .pending)

        candidate.status = .imported
        XCTAssertEqual(candidate.status, .imported)
    }
}
