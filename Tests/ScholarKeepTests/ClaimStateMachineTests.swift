import XCTest
import SwiftData
@testable import ScholarKeep

final class ClaimStateMachineTests: XCTestCase {

    func testHappyPathFromDraftToPaid() throws {
        let claim = makeClaim(status: .draft)
        // Make the readiness checklist green on attached expense so readyToSubmit is allowed.
        markExpensesReady(claim)
        _ = try ClaimStateMachine.transition(claim, to: .readyToSubmit)
        XCTAssertEqual(claim.status, .readyToSubmit)
        _ = try ClaimStateMachine.transition(claim, to: .submitted)
        XCTAssertNotNil(claim.submittedDate)
        _ = try ClaimStateMachine.transition(claim, to: .pendingReview)
        _ = try ClaimStateMachine.transition(claim, to: .approved)
        XCTAssertNotNil(claim.decisionDate)
        _ = try ClaimStateMachine.transition(claim, to: .paidReimbursed)
        XCTAssertNotNil(claim.paidDate)
        XCTAssertEqual(claim.status, .paidReimbursed)
        XCTAssertEqual(claim.statusEvents.count, 5)
    }

    func testReadyToSubmitGatedByChecklist() {
        let claim = makeClaim(status: .draft)
        // Leave checklist incomplete.
        XCTAssertThrowsError(try ClaimStateMachine.transition(claim, to: .readyToSubmit)) { error in
            XCTAssertEqual(error as? ClaimStateMachine.TransitionError, .checklistIncomplete)
        }
    }

    func testInvalidJumpRejected() {
        let claim = makeClaim(status: .draft)
        XCTAssertThrowsError(try ClaimStateMachine.transition(claim, to: .paidReimbursed))
    }

    func testOnHoldFromSubmittedStartsClock() throws {
        let claim = makeClaim(status: .draft)
        markExpensesReady(claim)
        _ = try ClaimStateMachine.transition(claim, to: .readyToSubmit)
        _ = try ClaimStateMachine.transition(claim, to: .submitted)
        _ = try ClaimStateMachine.transition(claim, to: .onHold)
        XCTAssertEqual(claim.status, .onHold)
        XCTAssertNotNil(claim.onHoldStartedAt)
    }

    func testOnHoldBackToSubmittedClearsClock() throws {
        let claim = makeClaim(status: .draft)
        markExpensesReady(claim)
        _ = try ClaimStateMachine.transition(claim, to: .readyToSubmit)
        _ = try ClaimStateMachine.transition(claim, to: .submitted)
        _ = try ClaimStateMachine.transition(claim, to: .onHold)
        _ = try ClaimStateMachine.transition(claim, to: .submitted)
        XCTAssertNil(claim.onHoldStartedAt)
    }

    func testDeniedCanGoBackToSubmittedForResubmit() throws {
        let claim = makeClaim(status: .draft)
        markExpensesReady(claim)
        _ = try ClaimStateMachine.transition(claim, to: .readyToSubmit)
        _ = try ClaimStateMachine.transition(claim, to: .submitted)
        _ = try ClaimStateMachine.transition(claim, to: .onHold)
        _ = try ClaimStateMachine.transition(claim, to: .denied)
        _ = try ClaimStateMachine.transition(claim, to: .submitted)
        XCTAssertEqual(claim.status, .submitted)
    }

    func testAnyStateBackToDraftAllowed() throws {
        let claim = makeClaim(status: .draft)
        markExpensesReady(claim)
        _ = try ClaimStateMachine.transition(claim, to: .readyToSubmit)
        _ = try ClaimStateMachine.transition(claim, to: .submitted)
        _ = try ClaimStateMachine.transition(claim, to: .pendingReview)
        _ = try ClaimStateMachine.transition(claim, to: .approved)
        _ = try ClaimStateMachine.transition(claim, to: .draft)
        XCTAssertEqual(claim.status, .draft)
    }

    // MARK: helpers

    private func makeClaim(status: ClaimStatus) -> Claim {
        let claim = Claim(title: "Test claim", status: status)
        let expense = Expense(vendorName: "Test vendor", total: 100)
        expense.claim = claim
        claim.expenses.append(expense)
        return claim
    }

    private func markExpensesReady(_ claim: Claim) {
        for e in claim.expenses {
            var cl = e.readinessChecklist
            cl.itemizedReceipt = true
            cl.proofOfPayment = true
            cl.studentNamePresent = true
            cl.noHandwrittenAlterations = true
            e.readinessChecklist = cl
        }
    }
}
