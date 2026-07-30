import Foundation
import SwiftData

/// Seeds realistic sample data for App Store screenshots and in-person demos
/// (FPEA booth). Activated by the `--demo` launch argument, which also forces
/// an in-memory store so demo data never touches real records.
enum DemoSeed {

    static var isActive: Bool {
        CommandLine.arguments.contains("--demo")
    }

    static func seed(into context: ModelContext, settings: AppSettings) {
        let cal = Calendar.current
        func daysAgo(_ n: Int) -> Date { cal.date(byAdding: .day, value: -n, to: .now) ?? .now }

        // MARK: Students
        let maya = Student(
            displayName: "Maya",
            program: .fesUA,
            sfo: .stepUp,
            gradeLevel: "3rd",
            county: "Hillsborough",
            awardAmount: 9997,
            slpApprovedDate: nil
        )
        let ezra = Student(
            displayName: "Ezra",
            program: .pep,
            sfo: .stepUp,
            gradeLevel: "1st",
            county: "Hillsborough",
            awardAmount: 8000,
            slpApprovedDate: daysAgo(220)
        )
        context.insert(maya)
        context.insert(ezra)

        // MARK: Expenses (Maya)
        let officeDepot = Expense(
            vendorName: "Office Depot #1247",
            purchaseDate: daysAgo(8),
            subtotal: 79.42, tax: 5.55, total: 84.97,
            categoryKey: "curriculum",
            eligibilityResult: .likelyEligible,
            eligibilityReason: "Curriculum and instructional materials are eligible under FES-UA §4.2."
        )
        officeDepot.student = maya

        let lakeshore = Expense(
            vendorName: "Lakeshore Learning",
            purchaseDate: daysAgo(19),
            subtotal: 146.17, tax: 10.23, total: 156.40,
            categoryKey: "curriculum",
            eligibilityResult: .eligible,
            eligibilityReason: "Instructional materials, itemized receipt on file."
        )
        lakeshore.student = maya

        let aba = Expense(
            vendorName: "Bright Path ABA · Dr. Patel, BCBA",
            purchaseDate: daysAgo(25),
            subtotal: 540, tax: 0, total: 540,
            categoryKey: "therapy",
            eligibilityResult: .eligible,
            eligibilityReason: "ABA services from a BCBA are eligible under FES-UA §3.4."
        )
        aba.student = maya

        let mathUSee = Expense(
            vendorName: "Math-U-See (Amazon)",
            purchaseDate: daysAgo(2),
            subtotal: 174.77, tax: 12.23, total: 187.00,
            categoryKey: "curriculum",
            eligibilityResult: .likelyEligible,
            eligibilityReason: "Curriculum bundle, imported from Mail."
        )
        mathUSee.student = maya

        // Expense (Ezra)
        let bookshark = Expense(
            vendorName: "BookShark",
            purchaseDate: daysAgo(34),
            subtotal: 176.64, tax: 12.36, total: 189.00,
            categoryKey: "curriculum",
            eligibilityResult: .eligible,
            eligibilityReason: "Eligible digital + print instructional materials under PEP."
        )
        bookshark.student = ezra

        for e in [officeDepot, lakeshore, aba, mathUSee, bookshark] {
            context.insert(e)
        }

        // MARK: Claims (Maya)
        let mayClaim = Claim(title: "May submission package", status: .submitted,
                             submittedDate: daysAgo(9), createdAt: daysAgo(12))
        mayClaim.student = maya
        mayClaim.expenses = [lakeshore, aba]
        context.insert(mayClaim)
        context.insert(StatusEvent(status: .draft, date: daysAgo(12), note: "Created.", claim: mayClaim))
        context.insert(StatusEvent(status: .submitted, date: daysAgo(9), note: "Uploaded to EMA.", claim: mayClaim))

        let aprilClaim = Claim(title: "April therapy claim", status: .onHold,
                               submittedDate: daysAgo(40), onHoldStartedAt: daysAgo(30),
                               createdAt: daysAgo(45))
        aprilClaim.student = maya
        context.insert(aprilClaim)
        context.insert(StatusEvent(status: .onHold, date: daysAgo(30),
                                   note: "SFO requested BCBA credentials.", claim: aprilClaim))

        let marchClaim = Claim(title: "March curriculum batch", status: .paidReimbursed,
                               submittedDate: daysAgo(80), paidDate: daysAgo(62),
                               createdAt: daysAgo(85))
        marchClaim.student = maya
        context.insert(marchClaim)
        context.insert(StatusEvent(status: .paidReimbursed, date: daysAgo(62),
                                   note: "Reimbursed via ACH.", claim: marchClaim))

        // MARK: Balance ledger (Maya)
        let entries: [BalanceEntry] = [
            BalanceEntry(type: .initialAward, amount: 9997, date: daysAgo(280),
                         note: "2026-27 award", student: maya),
            BalanceEntry(type: .claimPaid, amount: 326.50, date: daysAgo(62),
                         note: "March curriculum batch", student: maya),
            BalanceEntry(type: .claimSubmitted, amount: 696.40, date: daysAgo(9),
                         note: "May submission package", student: maya),
            BalanceEntry(type: .directPayDeduction, amount: 5_126.90, date: daysAgo(120),
                         note: "MyScholarShop + direct-pay YTD", student: maya)
        ]
        for entry in entries { context.insert(entry) }

        // MARK: Recurring tasks
        let evalTask = RecurringTask(
            title: "Annual evaluation by certified teacher",
            schedule: .annually,
            nextDueDate: cal.date(byAdding: .day, value: 24, to: .now) ?? .now,
            student: maya
        )
        let receiptsTask = RecurringTask(
            title: "Bundle quarterly receipts for submission",
            schedule: .quarterly,
            nextDueDate: cal.date(byAdding: .day, value: 11, to: .now) ?? .now,
            student: maya
        )
        context.insert(evalTask)
        context.insert(receiptsTask)

        // MARK: Receipt inbox
        let receiptCandidate = ReceiptCandidate(
            source: .gmail,
            sourceMessageID: "demo-gmail-receipt-1",
            sender: "Rainbow Resource Center <orders@rainbowresource.com>",
            subject: "Your Rainbow Resource receipt",
            receivedAt: daysAgo(1),
            snippet: "Order RR-48291 · Total $64.72",
            bodyText: """
            Thank you for your order.
            Order RR-48291
            Math manipulatives $34.95
            Science activity kit $25.00
            Subtotal $59.95
            Tax $4.77
            Total $64.72
            """,
            suggestedVendor: "Rainbow Resource Center",
            suggestedPurchaseDate: daysAgo(1),
            suggestedSubtotal: 59.95,
            suggestedTax: 4.77,
            suggestedTotal: 64.72,
            suggestedLineItems: [
                ParsedLineItem(descriptionText: "Math manipulatives", amount: 34.95),
                ParsedLineItem(descriptionText: "Science activity kit", amount: 25.00)
            ],
            detectionScore: 8,
            detectionReasons: [
                "Subject contains “receipt”",
                "Contains purchase details",
                "Contains a currency amount"
            ]
        )
        context.insert(receiptCandidate)

        try? context.save()
        settings.activeStudentID = maya.id
    }
}
