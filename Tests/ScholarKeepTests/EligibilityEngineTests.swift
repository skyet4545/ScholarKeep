import XCTest
@testable import ScholarKeep

/// Drives the Appendix B test table through the engine using the bundled ruleset.
final class EligibilityEngineTests: XCTestCase {
    private var engine: EligibilityEngine!

    override func setUpWithError() throws {
        engine = try TestRuleset.engine()
    }

    // Appendix B test cases (descriptions + expected verdicts).
    func testABATherapyOnFESUA_LikelyEligible() {
        let result = engine.evaluateFreeText("ABA therapy session, provider license #",
                                             amount: 200, program: .fesUA)
        XCTAssertEqual(result.status, .likelyEligible)
        XCTAssertTrue(result.requiresProviderCredentials)
    }

    func testABATherapyOnPEP_Ineligible() {
        let result = engine.evaluateFreeText("ABA therapy session",
                                             amount: 200, program: .pep)
        XCTAssertEqual(result.status, .ineligible)
    }

    func testChromebookNoPriorDevice_LikelyEligible() {
        let result = engine.evaluateFreeText("Chromebook",
                                             amount: 350, program: .pep,
                                             studentHasDeviceWithinWindow: false)
        XCTAssertEqual(result.status, .likelyEligible)
    }

    func testChromebookRecentDevice_NeedsPreAuth() {
        let result = engine.evaluateFreeText("Chromebook",
                                             amount: 350, program: .pep,
                                             studentHasDeviceWithinWindow: true)
        XCTAssertEqual(result.status, .needsPreAuth)
        XCTAssertTrue(result.requiresPreAuth)
    }

    func testFloridaPrepaidReimbursement_DirectPayOnly() {
        let result = engine.evaluateFreeText("Florida Prepaid contribution",
                                             amount: 500, program: .fesUA,
                                             acquisitionPath: .reimbursement)
        XCTAssertEqual(result.status, .directPayOnly)
    }

    func testGasForCoOpDrive_Ineligible() {
        let result = engine.evaluateFreeText("Gas for co-op drive",
                                             amount: 40, program: .fesUA)
        XCTAssertEqual(result.status, .ineligible)
    }

    func testZooAdmissionUnderCap_NeedsPreAuth() {
        let result = engine.evaluateFreeText("Zoo admission $250, one student",
                                             amount: 250, program: .pep)
        XCTAssertEqual(result.status, .needsPreAuth)
        XCTAssertTrue(result.requiresEducationalBenefitForm)
    }

    func testThemeParkOverCap_Ineligible() {
        let result = engine.evaluateFreeText("Theme park annual pass",
                                             amount: 480, program: .pep)
        XCTAssertEqual(result.status, .ineligible)
    }

    func testMathCurriculumWorkbook_LikelyEligible() {
        let result = engine.evaluateFreeText("Math curriculum workbook",
                                             amount: 30, program: .pep)
        XCTAssertEqual(result.status, .likelyEligible)
    }

    func testSchoolLunchFee_Ineligible() {
        let result = engine.evaluateFreeText("School lunch fee",
                                             amount: 12, program: .fesUA)
        XCTAssertEqual(result.status, .ineligible)
    }

    func testUnknownDescription_Unknown() {
        let result = engine.evaluateFreeText("Mysterious purchase",
                                             amount: 10, program: .fesUA)
        XCTAssertEqual(result.status, .unknown)
    }
}
