import XCTest
@testable import ScholarKeep

final class ExpenseReadinessTests: XCTestCase {

    private func expenseWithCompleteChecklist(payment: PaymentMethod = .ach) -> Expense {
        let e = Expense(total: 100, paymentMethod: payment)
        var cl = e.readinessChecklist
        cl.itemizedReceipt = true
        cl.proofOfPayment = true
        cl.studentNamePresent = true
        cl.noHandwrittenAlterations = true
        e.readinessChecklist = cl
        e.noDoubleDipConfirmed = true
        return e
    }

    func testReady_CompleteChecklist_NonCardPayment_DoubleDipConfirmed() {
        let e = expenseWithCompleteChecklist()
        XCTAssertTrue(e.isFullyReadyForSubmit)
    }

    func testNotReady_NoDoubleDipConfirmation() {
        let e = expenseWithCompleteChecklist()
        e.noDoubleDipConfirmed = false
        XCTAssertFalse(e.isFullyReadyForSubmit,
                       "Insurance/HSA double-dip confirmation is required before Ready-to-Submit")
    }

    func testNotReady_CardPaymentMissingLast4() {
        let e = expenseWithCompleteChecklist(payment: .card)
        e.cardLast4 = nil
        XCTAssertFalse(e.isFullyReadyForSubmit,
                       "Card-paid expenses must capture last 4 digits (#1 cited PoP denial reason)")
    }

    func testReady_CardPaymentWithLast4() {
        let e = expenseWithCompleteChecklist(payment: .card)
        e.cardLast4 = "1234"
        XCTAssertTrue(e.isFullyReadyForSubmit)
    }

    func testNotReady_ChecklistIncomplete() {
        let e = expenseWithCompleteChecklist()
        var cl = e.readinessChecklist
        cl.proofOfPayment = false
        e.readinessChecklist = cl
        XCTAssertFalse(e.isFullyReadyForSubmit)
    }

    func testRefundsReduceNetReimbursableAmount() {
        let e = Expense(total: 100)
        let r1 = Refund(refundDate: .now, refundAmount: 25, reason: "Returned book")
        let r2 = Refund(refundDate: .now, refundAmount: 10, reason: "Manufacturer rebate")
        e.refunds.append(r1)
        e.refunds.append(r2)
        XCTAssertEqual(e.refundedAmount, 35)
        XCTAssertEqual(e.netReimbursableAmount, 65)
    }
}
