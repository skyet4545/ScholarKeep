import XCTest
@testable import ScholarKeep

final class BalanceLedgerTests: XCTestCase {

    func testEmptyLedgerIsZero() {
        let summary = BalanceLedger.summarize(entries: [])
        XCTAssertEqual(summary.availableBalance, 0)
        XCTAssertEqual(summary.pendingClaims, 0)
        XCTAssertEqual(summary.paidClaims, 0)
        XCTAssertEqual(summary.totalDisbursed, 0)
    }

    func testInitialAwardAndDisbursementsAccumulate() {
        let entries = [
            BalanceEntry(type: .initialAward, amount: 10_000),
            BalanceEntry(type: .disbursement, amount: 2_500)
        ]
        let summary = BalanceLedger.summarize(entries: entries)
        XCTAssertEqual(summary.availableBalance, 12_500)
        XCTAssertEqual(summary.totalDisbursed, 12_500)
    }

    func testClaimSubmittedDeducts_PaidLeavesItPaidNotPending() {
        let entries = [
            BalanceEntry(type: .initialAward, amount: 10_000),
            BalanceEntry(type: .claimSubmitted, amount: 500),
            BalanceEntry(type: .claimPaid, amount: 500)
        ]
        let summary = BalanceLedger.summarize(entries: entries)
        XCTAssertEqual(summary.availableBalance, 9_000) // -500 submit, -500 paid
        XCTAssertEqual(summary.pendingClaims, 0)
        XCTAssertEqual(summary.paidClaims, 500)
    }

    func testPendingDoesntGoNegativeOnOutOfOrderEntries() {
        let entries = [
            BalanceEntry(type: .initialAward, amount: 10_000),
            BalanceEntry(type: .claimPaid, amount: 500)   // paid before recorded submission
        ]
        let summary = BalanceLedger.summarize(entries: entries)
        XCTAssertGreaterThanOrEqual(summary.pendingClaims, 0)
    }

    func testRefundReturnedAddsBack() {
        let entries = [
            BalanceEntry(type: .initialAward, amount: 1_000),
            BalanceEntry(type: .claimPaid, amount: 100),
            BalanceEntry(type: .refundReturned, amount: 100)
        ]
        let summary = BalanceLedger.summarize(entries: entries)
        XCTAssertEqual(summary.availableBalance, 1_000)
    }

    func testDirectPayDeducts() {
        let entries = [
            BalanceEntry(type: .initialAward, amount: 1_000),
            BalanceEntry(type: .directPayDeduction, amount: 150)
        ]
        let summary = BalanceLedger.summarize(entries: entries)
        XCTAssertEqual(summary.availableBalance, 850)
    }
}
