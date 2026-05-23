import XCTest
@testable import ScholarKeep

final class StudentSLPTests: XCTestCase {

    private func date(_ y: Int, _ m: Int, _ d: Int) -> Date {
        var c = DateComponents(); c.year = y; c.month = m; c.day = d; c.hour = 12
        return Calendar.current.date(from: c)!
    }

    func testNonPEPStudentAlwaysPassesSLPCheck() {
        for program: Program in [.fesUA, .fesEO] {
            let s = Student(displayName: "Test", program: program, sfo: .stepUp)
            XCTAssertTrue(s.slpApprovedBefore(date(2026, 10, 1)),
                          "\(program.shortName) doesn't have an SLP concept; check must pass")
        }
    }

    func testPEPStudentWithoutSLPFails() {
        let s = Student(displayName: "Test", program: .pep, sfo: .stepUp)
        XCTAssertFalse(s.slpApprovedBefore(date(2026, 10, 1)))
    }

    func testPEPStudentWithSLPBeforePurchasePasses() {
        let s = Student(displayName: "Test", program: .pep, sfo: .stepUp)
        s.slpApprovedDate = date(2026, 8, 1)
        XCTAssertTrue(s.slpApprovedBefore(date(2026, 10, 1)))
    }

    func testPEPStudentWithSLPAfterPurchaseFails() {
        let s = Student(displayName: "Test", program: .pep, sfo: .stepUp)
        s.slpApprovedDate = date(2026, 11, 1)
        XCTAssertFalse(s.slpApprovedBefore(date(2026, 10, 1)),
                       "Purchase predates SLP approval — permanently ineligible")
    }

    func testPEPStudentWithSLPOnSamePassesEdgeCase() {
        let s = Student(displayName: "Test", program: .pep, sfo: .stepUp)
        s.slpApprovedDate = date(2026, 10, 1)
        XCTAssertTrue(s.slpApprovedBefore(date(2026, 10, 1)))
    }
}
