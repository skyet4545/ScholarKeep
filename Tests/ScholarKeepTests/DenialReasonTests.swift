import XCTest
@testable import ScholarKeep

final class DenialReasonTests: XCTestCase {

    func testEveryReasonHasASuggestedFix() {
        for reason in DenialReason.allCases {
            XCTAssertFalse(reason.suggestedFix.isEmpty,
                           "Denial reason \(reason.rawValue) has no suggested fix")
            XCTAssertGreaterThan(reason.suggestedFix.count, 20,
                                 "Suggested fix for \(reason.rawValue) is suspiciously short")
        }
    }

    func testChecklistKeyMappingsAreSensible() {
        // Reasons that point at a specific doc must map to that doc.
        XCTAssertEqual(DenialReason.missingProofOfPayment.checklistKey, .proofOfPayment)
        XCTAssertEqual(DenialReason.notItemized.checklistKey, .itemizedReceipt)
        XCTAssertEqual(DenialReason.missingPriceBreakdown.checklistKey, .itemizedReceipt)
        XCTAssertEqual(DenialReason.missingVendorName.checklistKey, .itemizedReceipt)
        XCTAssertEqual(DenialReason.studentNameMismatch.checklistKey, .studentNamePresent)
        XCTAssertEqual(DenialReason.missingProviderCredentials.checklistKey, .providerCredentials)
        XCTAssertEqual(DenialReason.missingDatesOfService.checklistKey, .providerCredentials)
        XCTAssertEqual(DenialReason.missingEducationalBenefitForm.checklistKey, .educationalBenefitForm)
        XCTAssertEqual(DenialReason.missingPreAuth.checklistKey, .preAuthIfRequired)
        XCTAssertEqual(DenialReason.handwrittenAlteration.checklistKey, .noHandwrittenAlterations)
    }

    func testStructuralReasonsDontResetTheChecklist() {
        // These are about the claim's structure or status, not a doc to swap.
        XCTAssertNil(DenialReason.ineligibleItem.checklistKey)
        XCTAssertNil(DenialReason.multipleProvidersOneClaim.checklistKey)
        XCTAssertNil(DenialReason.overPriceCap.checklistKey)
        XCTAssertNil(DenialReason.duplicateClaim.checklistKey)
        XCTAssertNil(DenialReason.pastDeadline.checklistKey)
        XCTAssertNil(DenialReason.illegibleImage.checklistKey)
        XCTAssertNil(DenialReason.other.checklistKey)
    }

    func testEveryReasonHasADisplayName() {
        for reason in DenialReason.allCases {
            XCTAssertFalse(reason.displayName.isEmpty,
                           "Denial reason \(reason.rawValue) is missing a display name")
        }
    }
}
