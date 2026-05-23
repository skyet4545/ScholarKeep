import XCTest
@testable import ScholarKeep

/// Verifies the engine returns sensible results for every program × category
/// combination defined in the ruleset. Catches drift between Program enum
/// additions and ruleset JSON.
final class ProgramCoverageTests: XCTestCase {
    private var engine: EligibilityEngine!

    override func setUpWithError() throws {
        engine = try TestRuleset.engine()
    }

    func testEveryProgramIsRepresentedInRuleset() {
        let programsInRuleset = Set(engine.ruleset.categories.flatMap { $0.programs })
        for program in Program.allCases {
            XCTAssertTrue(
                programsInRuleset.contains(program.rawValue),
                "Program \(program.rawValue) (\(program.displayName)) has no eligible categories in the ruleset"
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

    func testFESEOExcludesSpecializedTherapy() {
        let result = engine.evaluateFreeText("ABA therapy session", amount: 200, program: .fesEO)
        XCTAssertEqual(result.status, .ineligible, "FES-EO should not cover specialized therapies")
    }

    func testFESEOAllowsPrivateSchoolTuition() {
        let result = engine.evaluateFreeText("Private school tuition", amount: 8500, program: .fesEO)
        XCTAssertTrue(
            [EligibilityStatus.likelyEligible, .eligible].contains(result.status),
            "FES-EO should allow private school tuition, got \(result.status)"
        )
        XCTAssertTrue(result.requiresStudentName)
    }

    func testPEPExcludesPrivateSchoolTuition() {
        let result = engine.evaluateFreeText("Private school tuition", amount: 8500, program: .pep)
        XCTAssertEqual(result.status, .ineligible)
    }

    func testFESEOAllowsDevices() {
        let result = engine.evaluateFreeText("iPad", amount: 600, program: .fesEO,
                                             studentHasDeviceWithinWindow: false)
        XCTAssertEqual(result.status, .likelyEligible)
    }

    func testFESEODeviceRecentlyPurchased_NeedsPreAuth() {
        let result = engine.evaluateFreeText("iPad", amount: 600, program: .fesEO,
                                             studentHasDeviceWithinWindow: true)
        XCTAssertEqual(result.status, .needsPreAuth)
    }

    /// Cap-driven ineligibility applies regardless of program.
    func testThemeParkOverCap_FailsForAllPrograms() {
        for program in Program.allCases {
            let result = engine.evaluateFreeText("Zoo admission", amount: 350, program: program)
            XCTAssertEqual(result.status, .ineligible,
                           "Theme park over cap should be ineligible for \(program.shortName)")
        }
    }

    func testThemeParkUnderCap_NeedsPreAuthForAllPrograms() {
        for program in Program.allCases {
            let result = engine.evaluateFreeText("Zoo admission", amount: 250, program: program)
            XCTAssertEqual(result.status, .needsPreAuth,
                           "Theme park under cap should need pre-auth for \(program.shortName)")
            XCTAssertTrue(result.requiresEducationalBenefitForm,
                          "Theme park needs Educational Benefit Form for \(program.shortName)")
        }
    }

    func testTransportationIneligibleForEveryProgram() {
        for program in Program.allCases {
            let result = engine.evaluateFreeText("Gas for trip", amount: 40, program: program)
            XCTAssertEqual(result.status, .ineligible,
                           "Gas should be ineligible for \(program.shortName)")
        }
    }

    func testFoodAndLodgingIneligibleForEveryProgram() {
        for program in Program.allCases {
            let result = engine.evaluateFreeText("Hotel for field trip", amount: 200, program: program)
            XCTAssertEqual(result.status, .ineligible)
        }
    }

    func testFloridaPrepaid_DirectPayOnlyForEveryProgram() {
        for program in Program.allCases {
            let result = engine.evaluateFreeText("Florida Prepaid contribution",
                                                 amount: 500, program: program,
                                                 acquisitionPath: .reimbursement)
            XCTAssertEqual(result.status, .directPayOnly)
        }
    }

    func testFloridaPrepaid_AllowedOnDirectPay() {
        for program in Program.allCases {
            let result = engine.evaluateFreeText("Florida Prepaid contribution",
                                                 amount: 500, program: program,
                                                 acquisitionPath: .providerDirectPay)
            // Engine returns based on category baseEligibility .directPayOnly even when
            // not reimbursing — the direct-pay return only fires when reimbursing.
            // For provider direct-pay path, it should not short-circuit as "directPayOnly"
            // since that status is specifically about "you tried to reimburse".
            // The current engine returns the category baseEligibility for direct-pay path → likelyEligible.
            XCTAssertNotEqual(result.status, .ineligible,
                              "Florida Prepaid via direct-pay path shouldn't be flat ineligible")
        }
    }

    func testCurriculumEligibleAllPrograms() {
        for program in Program.allCases {
            let result = engine.evaluateFreeText("Math curriculum workbook", amount: 30, program: program)
            XCTAssertEqual(result.status, .likelyEligible,
                           "Curriculum should be eligible for \(program.shortName)")
        }
    }

    func testTutoringRequiresCredentialsAllPrograms() {
        for program in Program.allCases {
            let result = engine.evaluateFreeText("Math tutoring session", amount: 80, program: program)
            XCTAssertEqual(result.status, .likelyEligible)
            XCTAssertTrue(result.requiresProviderCredentials,
                          "Tutoring should require credentials for \(program.shortName)")
            XCTAssertTrue(result.requiresStudentName,
                          "Tutoring should require student name for \(program.shortName)")
        }
    }
}
