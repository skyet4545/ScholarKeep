import XCTest
@testable import ScholarKeep

final class ReadinessChecklistTests: XCTestCase {

    func testEmptyChecklistIsIncomplete() {
        let cl = ReadinessChecklist()
        XCTAssertFalse(cl.isComplete)
        XCTAssertEqual(cl.checkedCount, 0)
        XCTAssertEqual(cl.totalApplicable, 4) // only the four base fields
    }

    func testBaseFieldsComplete_WhenNoOptionalsApply() {
        var cl = ReadinessChecklist()
        cl.itemizedReceipt = true
        cl.proofOfPayment = true
        cl.studentNamePresent = true
        cl.noHandwrittenAlterations = true
        XCTAssertTrue(cl.isComplete)
        XCTAssertEqual(cl.checkedCount, 4)
        XCTAssertEqual(cl.totalApplicable, 4)
    }

    func testProviderRequiredButUnchecked_Incomplete() {
        var cl = ReadinessChecklist()
        cl.itemizedReceipt = true
        cl.proofOfPayment = true
        cl.studentNamePresent = true
        cl.noHandwrittenAlterations = true
        cl.providerCredentials = false
        XCTAssertFalse(cl.isComplete)
        XCTAssertEqual(cl.totalApplicable, 5)
        XCTAssertEqual(cl.checkedCount, 4)
    }

    func testProviderRequiredAndChecked_Complete() {
        var cl = ReadinessChecklist()
        cl.itemizedReceipt = true
        cl.proofOfPayment = true
        cl.studentNamePresent = true
        cl.noHandwrittenAlterations = true
        cl.providerCredentials = true
        XCTAssertTrue(cl.isComplete)
        XCTAssertEqual(cl.checkedCount, 5)
    }

    func testAllOptionalsApplicable_FullComplete() {
        var cl = ReadinessChecklist()
        cl.itemizedReceipt = true
        cl.proofOfPayment = true
        cl.studentNamePresent = true
        cl.noHandwrittenAlterations = true
        cl.providerCredentials = true
        cl.educationalBenefitForm = true
        cl.preAuthIfRequired = true
        XCTAssertTrue(cl.isComplete)
        XCTAssertEqual(cl.checkedCount, 7)
        XCTAssertEqual(cl.totalApplicable, 7)
    }

    func testNilOptionalDoesntCount() {
        var cl = ReadinessChecklist()
        cl.itemizedReceipt = true
        cl.proofOfPayment = true
        cl.studentNamePresent = true
        cl.noHandwrittenAlterations = true
        cl.providerCredentials = nil   // not applicable
        XCTAssertTrue(cl.isComplete, "Nil optionals should not block completion")
    }
}
