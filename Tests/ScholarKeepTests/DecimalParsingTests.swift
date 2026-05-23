import XCTest
@testable import ScholarKeep

final class DecimalParsingTests: XCTestCase {

    func testParsesSimpleAmount() {
        XCTAssertEqual(DecimalParsing.parse("12.34"), Decimal(string: "12.34"))
    }

    func testStripsLeadingDollarSign() {
        XCTAssertEqual(DecimalParsing.parse("$12.34"), Decimal(string: "12.34"))
        XCTAssertEqual(DecimalParsing.parse("$ 12.34"), Decimal(string: "12.34"))
    }

    func testStripsCommasInThousands() {
        XCTAssertEqual(DecimalParsing.parse("1,234.56"), Decimal(string: "1234.56"))
        XCTAssertEqual(DecimalParsing.parse("$1,234.56"), Decimal(string: "1234.56"))
        XCTAssertEqual(DecimalParsing.parse("12,345,678.90"), Decimal(string: "12345678.90"))
    }

    func testHandlesNegativeViaParens() {
        XCTAssertEqual(DecimalParsing.parse("(12.34)"), Decimal(string: "-12.34"))
        XCTAssertEqual(DecimalParsing.parse("($1,234.56)"), Decimal(string: "-1234.56"))
    }

    func testTrimsWhitespace() {
        XCTAssertEqual(DecimalParsing.parse("   42.00  "), Decimal(string: "42.00"))
    }

    func testRejectsGarbage() {
        XCTAssertNil(DecimalParsing.parse("abc"))
        XCTAssertNil(DecimalParsing.parse("xyz123"))
        XCTAssertNil(DecimalParsing.parse(""))
        XCTAssertNil(DecimalParsing.parse(nil))
    }

    func testHandlesUSDSuffix() {
        XCTAssertEqual(DecimalParsing.parse("12.34 USD"), Decimal(string: "12.34"))
    }

    func testHandlesNBSP() {
        // Non-breaking space sometimes appears between currency and amount.
        XCTAssertEqual(DecimalParsing.parse("$\u{00A0}12.34"), Decimal(string: "12.34"))
    }

    func testZeroParses() {
        XCTAssertEqual(DecimalParsing.parse("0"), Decimal(0))
        XCTAssertEqual(DecimalParsing.parse("0.00"), Decimal(0))
        XCTAssertEqual(DecimalParsing.parse("$0.00"), Decimal(0))
    }

    func testLargeAwardAmount() {
        XCTAssertEqual(DecimalParsing.parse("34,000"), Decimal(34000))
    }
}
