import XCTest
@testable import ScholarKeep

final class PreAuthorizationTests: XCTestCase {

    func testDraftIsNotCurrentlyValid() {
        let pa = PreAuthorization(itemDescription: "Adaptive bike")
        XCTAssertEqual(pa.status, .draft)
        XCTAssertFalse(pa.isCurrentlyValid)
    }

    func testApprovedWithoutExpirationIsValid() {
        let pa = PreAuthorization(itemDescription: "Adaptive bike")
        pa.status = .approved
        pa.approvedNumber = "PA-1234"
        XCTAssertTrue(pa.isCurrentlyValid)
    }

    func testApprovedExpiredIsNotValid() {
        let pa = PreAuthorization(itemDescription: "Adaptive bike")
        pa.status = .approved
        pa.expirationDate = Calendar.current.date(byAdding: .day, value: -1, to: .now)
        XCTAssertFalse(pa.isCurrentlyValid)
    }

    func testApprovedFutureExpirationIsValid() {
        let pa = PreAuthorization(itemDescription: "Adaptive bike")
        pa.status = .approved
        pa.expirationDate = Calendar.current.date(byAdding: .day, value: 30, to: .now)
        XCTAssertTrue(pa.isCurrentlyValid)
    }

    func testDeniedIsNotValid() {
        let pa = PreAuthorization(itemDescription: "Adaptive bike")
        pa.status = .denied
        XCTAssertFalse(pa.isCurrentlyValid)
    }
}
