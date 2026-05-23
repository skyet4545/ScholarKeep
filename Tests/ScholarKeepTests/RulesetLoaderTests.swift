import XCTest
@testable import ScholarKeep

final class RulesetLoaderTests: XCTestCase {

    func testBundledRulesetLoads() throws {
        let ruleset = try TestRuleset.load()
        XCTAssertFalse(ruleset.schoolYear.isEmpty)
        XCTAssertFalse(ruleset.sourceVersion.isEmpty)
        XCTAssertFalse(ruleset.categories.isEmpty)
        XCTAssertGreaterThan(ruleset.globalRules.deviceReplacementYears, 0)
        XCTAssertGreaterThan(ruleset.globalRules.peripheralPreAuthOver, 0)
    }

    func testRulesetHasAtLeastOneIneligibleCategory() throws {
        let ruleset = try TestRuleset.load()
        let ineligible = ruleset.categories.filter { $0.baseEligibility == .ineligible }
        XCTAssertGreaterThan(ineligible.count, 3, "Expected multiple ineligible categories (gas, food, medical, tickets, household)")
    }

    func testEveryCategoryProgramCodeIsValid() throws {
        let ruleset = try TestRuleset.load()
        let validRawValues = Set(Program.allCases.map { $0.rawValue })
        for cat in ruleset.categories {
            for code in cat.programs {
                XCTAssertTrue(validRawValues.contains(code),
                              "Category \(cat.key) references unknown program code '\(code)'")
            }
        }
    }

    func testDeadlinesParseable() throws {
        let ruleset = try TestRuleset.load()
        // The repeating-date format starts with "--MM-DD"
        XCTAssertTrue(ruleset.deadlines.reimbursementSubmissionDeadline.hasPrefix("--"))
        XCTAssertGreaterThan(ruleset.deadlines.reviewDaysMax, 0)
        // Pre-auth deadline is optional but should exist in current ruleset.
        XCTAssertNotNil(ruleset.deadlines.preAuthDeadline)
    }
}
