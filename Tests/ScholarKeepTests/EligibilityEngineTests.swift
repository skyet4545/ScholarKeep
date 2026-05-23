import XCTest
@testable import ScholarKeep

/// Engine sanity tests against the 2026-27-v1 ruleset (built from the official
/// Step Up Purchasing Guides). Spec Appendix B has been superseded by the
/// rules-as-of-current-year — these are the up-to-date assertions.
final class EligibilityEngineTests: XCTestCase {
    private var engine: EligibilityEngine!

    override func setUpWithError() throws {
        engine = try TestRuleset.engine()
    }

    func testABATherapyOnFESUA_LikelyEligible() {
        let result = engine.evaluateFreeText("ABA therapy session, provider license #",
                                             amount: 200, program: .fesUA)
        XCTAssertEqual(result.status, .likelyEligible)
        XCTAssertTrue(result.requiresProviderCredentials)
        XCTAssertTrue(result.requiresFloridaLicensedProvider)
    }

    func testABATherapyOnPEP_Ineligible() {
        let result = engine.evaluateFreeText("ABA therapy session", amount: 200, program: .pep)
        XCTAssertEqual(result.status, .ineligible)
    }

    func testChromebookFESUA_NoPriorDevice_LikelyEligible() {
        let result = engine.evaluateFreeText("Chromebook for math lessons",
                                             amount: 350, program: .fesUA,
                                             studentHasDeviceWithinWindow: false)
        XCTAssertEqual(result.status, .likelyEligible)
    }

    func testChromebookFESUA_RecentDevice_NeedsPreAuth() {
        let result = engine.evaluateFreeText("Chromebook",
                                             amount: 350, program: .fesUA,
                                             studentHasDeviceWithinWindow: true)
        XCTAssertEqual(result.status, .needsPreAuth)
        XCTAssertTrue(result.requiresPreAuth)
    }

    func testChromebookPEP_HardIneligible() {
        let result = engine.evaluateFreeText("Chromebook for math lessons",
                                             amount: 350, program: .pep)
        XCTAssertEqual(result.status, .ineligible,
                       "PEP explicitly prohibits laptops/Chromebooks")
    }

    func testFloridaPrepaidReimbursement_FESUA_LikelyEligible() {
        // FES-UA Prepaid is the one that MUST go through reimbursement (no direct-pay option).
        let result = engine.evaluateFreeText("Florida Prepaid contribution",
                                             amount: 500, program: .fesUA,
                                             acquisitionPath: .reimbursement)
        XCTAssertEqual(result.status, .likelyEligible)
    }

    func testFlorida529_DirectPayOnly() {
        // 529 contributions go via direct-pay only — reimbursement is blocked.
        let result = engine.evaluateFreeText("529 college savings contribution",
                                             amount: 500, program: .fesUA,
                                             acquisitionPath: .reimbursement)
        XCTAssertEqual(result.status, .directPayOnly)
    }

    func testGasForCoOpDrive_Ineligible() {
        let result = engine.evaluateFreeText("Gas for co-op drive",
                                             amount: 40, program: .fesUA)
        XCTAssertEqual(result.status, .ineligible)
    }

    func testThemeParkAdmissionUnderCap_NeedsPreAuth() {
        let result = engine.evaluateFreeText("Magic Kingdom theme park admission $250",
                                             amount: 250, program: .pep)
        XCTAssertEqual(result.status, .needsPreAuth)
        XCTAssertTrue(result.requiresEducationalBenefitForm)
    }

    func testThemeParkOverCap_Ineligible() {
        let result = engine.evaluateFreeText("Universal Studios annual pass $480",
                                             amount: 480, program: .pep)
        XCTAssertEqual(result.status, .ineligible)
    }

    func testZooAdmission_GenericFieldTrip_LikelyEligible() {
        // Per 2025-26 guides, zoo/museum/aquarium are listed under generic Field Trips
        // (not the capped theme-park category) and are eligible for all programs.
        let result = engine.evaluateFreeText("Zoo admission for one student",
                                             amount: 25, program: .pep)
        XCTAssertEqual(result.status, .likelyEligible)
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
