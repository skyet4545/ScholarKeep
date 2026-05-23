import XCTest
@testable import ScholarKeep

/// Verifies the engine returns sensible results for every program × category
/// combination defined in the ruleset. Aligned with the 2026-27-v1 ruleset built
/// from the official 2025-2026 Step Up FES-UA, PEP, and FES-EO Purchasing Guides.
final class ProgramCoverageTests: XCTestCase {
    private var engine: EligibilityEngine!

    override func setUpWithError() throws {
        engine = try TestRuleset.engine()
    }

    // MARK: Schema integrity

    func testEveryProgramIsRepresentedInRuleset() {
        let programsInRuleset = Set(engine.ruleset.categories.flatMap { $0.programs })
        for program in Program.allCases {
            XCTAssertTrue(
                programsInRuleset.contains(program.rawValue),
                "Program \(program.rawValue) (\(program.displayName)) has no categories in the ruleset"
            )
        }
    }

    func testEveryCategoryHasASourceCitation() {
        for cat in engine.ruleset.categories {
            XCTAssertFalse(cat.sourceCitation.isEmpty, "Category \(cat.key) is missing a source citation")
        }
    }

    func testEveryCategoryHasAValidEligibilityStatus() {
        for cat in engine.ruleset.categories {
            let status = EligibilityStatus(rawValue: cat.eligibility)
            XCTAssertNotNil(status, "Category \(cat.key) has an unparseable eligibility status '\(cat.eligibility)'")
        }
    }

    // MARK: Devices — biggest divergence between programs

    func testDevices_FESUA_Eligible() {
        let result = engine.evaluateFreeText("Chromebook for math lessons", amount: 350, program: .fesUA)
        XCTAssertEqual(result.status, .likelyEligible)
    }

    func testDevices_FESUA_RecentPurchase_NeedsPreAuth() {
        let result = engine.evaluateFreeText("Chromebook", amount: 350, program: .fesUA,
                                             studentHasDeviceWithinWindow: true)
        XCTAssertEqual(result.status, .needsPreAuth)
        XCTAssertTrue(result.requiresPreAuth)
    }

    func testDevices_PEP_HardIneligible() {
        let result = engine.evaluateFreeText("Chromebook for math lessons", amount: 350, program: .pep)
        XCTAssertEqual(result.status, .ineligible,
                       "PEP explicitly prohibits laptops, Chromebooks, tablets, phones, etc.")
    }

    func testDevices_FESEO_HardIneligible() {
        let result = engine.evaluateFreeText("Laptop computer", amount: 500, program: .fesEO)
        XCTAssertEqual(result.status, .ineligible,
                       "FES-EO explicitly prohibits laptops since students are full-time at private school.")
    }

    // MARK: Specialized therapy — FES-UA only

    func testSpecializedTherapy_FESUA_Eligible() {
        let result = engine.evaluateFreeText("ABA therapy session with BCBA",
                                             amount: 200, program: .fesUA)
        XCTAssertEqual(result.status, .likelyEligible)
        XCTAssertTrue(result.requiresProviderCredentials)
        XCTAssertTrue(result.requiresFloridaLicensedProvider)
    }

    func testSpecializedTherapy_PEP_Ineligible() {
        let result = engine.evaluateFreeText("ABA therapy session", amount: 200, program: .pep)
        XCTAssertEqual(result.status, .ineligible)
    }

    func testSpecializedTherapy_FESEO_Ineligible() {
        let result = engine.evaluateFreeText("Speech-language therapy", amount: 150, program: .fesEO)
        XCTAssertEqual(result.status, .ineligible)
    }

    // MARK: Private school tuition

    func testPrivateSchoolTuition_FESUA_Eligible() {
        let result = engine.evaluateFreeText("Private school tuition", amount: 8500, program: .fesUA)
        XCTAssertEqual(result.status, .likelyEligible)
        XCTAssertTrue(result.requiresStudentName)
    }

    func testPrivateSchoolTuition_FESEO_Eligible() {
        let result = engine.evaluateFreeText("Private school tuition", amount: 8500, program: .fesEO)
        XCTAssertEqual(result.status, .likelyEligible)
    }

    func testPrivateSchoolTuition_PEP_Ineligible() {
        let result = engine.evaluateFreeText("Private school tuition", amount: 8500, program: .pep)
        XCTAssertEqual(result.status, .ineligible,
                       "PEP is for students NOT enrolled full-time in private school")
    }

    // MARK: Theme parks — capped, per-student-per-year

    func testThemeParkUnderCap_NeedsPreAuthForAllPrograms() {
        for program in Program.allCases {
            let result = engine.evaluateFreeText("Magic Kingdom theme park admission",
                                                 amount: 250, program: program)
            XCTAssertEqual(result.status, .needsPreAuth,
                           "Theme park under cap should need pre-auth for \(program.shortName)")
            XCTAssertTrue(result.requiresEducationalBenefitForm,
                          "Theme park needs Educational Benefit Form for \(program.shortName)")
        }
    }

    func testThemeParkOverCap_IneligibleForAllPrograms() {
        for program in Program.allCases {
            let result = engine.evaluateFreeText("Universal Studios annual pass",
                                                 amount: 480, program: program)
            XCTAssertEqual(result.status, .ineligible,
                           "Theme park over $299 cap should be ineligible for \(program.shortName)")
        }
    }

    // MARK: Universal ineligibles

    func testTransportationIneligibleForEveryProgram() {
        for program in Program.allCases {
            let result = engine.evaluateFreeText("Gas for co-op trip", amount: 40, program: program)
            XCTAssertEqual(result.status, .ineligible,
                           "Gas should be ineligible for \(program.shortName)")
        }
    }

    func testFoodIneligibleForEveryProgram() {
        for program in Program.allCases {
            let result = engine.evaluateFreeText("School lunch fee", amount: 12, program: program)
            XCTAssertEqual(result.status, .ineligible)
        }
    }

    func testMedicalIneligibleForEveryProgram() {
        for program in Program.allCases {
            let result = engine.evaluateFreeText("Mobility aid wheelchair",
                                                 amount: 800, program: program)
            XCTAssertEqual(result.status, .ineligible)
        }
    }

    // MARK: Universal eligibles

    func testCurriculumEligibleAllPrograms() {
        for program in Program.allCases {
            let result = engine.evaluateFreeText("Math curriculum workbook",
                                                 amount: 30, program: program)
            XCTAssertEqual(result.status, .likelyEligible,
                           "Curriculum should be eligible for \(program.shortName)")
        }
    }

    func testTutoringRequiresCredentialsAllPrograms() {
        for program in Program.allCases {
            let result = engine.evaluateFreeText("Math tutoring session",
                                                 amount: 80, program: program)
            XCTAssertEqual(result.status, .likelyEligible)
            XCTAssertTrue(result.requiresProviderCredentials,
                          "Tutoring should require credentials for \(program.shortName)")
            XCTAssertTrue(result.requiresStudentName,
                          "Tutoring should require student name for \(program.shortName)")
        }
    }

    // MARK: Insurance / HSA double-dip gate

    func testInsuranceDoubleDip_BlocksEverything() {
        let result = engine.evaluateFreeText("Math curriculum workbook",
                                             amount: 30, program: .fesUA,
                                             hasInsuranceDoubleDip: true)
        XCTAssertEqual(result.status, .ineligible)
        XCTAssertTrue(result.reasons.contains(where: { $0.lowercased().contains("insurance") }))
    }

    // MARK: PEP-specific Student Learning Plan gate

    func testPEP_PurchaseBeforeSLPApproved_PermanentlyIneligible() {
        let result = engine.evaluateFreeText("Math curriculum",
                                             amount: 30, program: .pep,
                                             slpApprovedBeforePurchase: false)
        XCTAssertEqual(result.status, .ineligible)
        XCTAssertTrue(result.reasons.contains(where: { $0.lowercased().contains("slp") || $0.lowercased().contains("student learning plan") }))
    }

    func testPEP_PurchaseAfterSLPApproved_NormalEvaluation() {
        let result = engine.evaluateFreeText("Math curriculum",
                                             amount: 30, program: .pep,
                                             slpApprovedBeforePurchase: true)
        XCTAssertEqual(result.status, .likelyEligible)
    }

    func testFESUA_SLPNotRequired() {
        // FES-UA has no SLP concept; slpApprovedBeforePurchase=false should be ignored.
        let result = engine.evaluateFreeText("Math curriculum",
                                             amount: 30, program: .fesUA,
                                             slpApprovedBeforePurchase: false)
        XCTAssertEqual(result.status, .likelyEligible)
    }
}
