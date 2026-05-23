import XCTest
@testable import ScholarKeep

final class SchoolYearTests: XCTestCase {
    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        var c = DateComponents()
        c.year = y; c.month = m; c.day = d; c.hour = 12
        return Calendar.current.date(from: c)!
    }

    func testJuneIsPreviousSchoolYear() {
        XCTAssertEqual(SchoolYear.label(for: date(2026, 6, 30)), "2025-26")
    }

    func testJulyFirstStartsNewSchoolYear() {
        XCTAssertEqual(SchoolYear.label(for: date(2026, 7, 1)), "2026-27")
    }

    func testJanuaryIsCurrentSchoolYear() {
        XCTAssertEqual(SchoolYear.label(for: date(2027, 1, 15)), "2026-27")
    }

    func testDecemberIsCurrentSchoolYear() {
        XCTAssertEqual(SchoolYear.label(for: date(2026, 12, 31)), "2026-27")
    }

    func testCenturyRolloverFormatsWithLeadingZero() {
        XCTAssertEqual(SchoolYear.label(for: date(2099, 8, 1)), "2099-00")
        XCTAssertEqual(SchoolYear.label(for: date(2100, 1, 1)), "2099-00")
    }
}
