import XCTest
import PDFKit
@testable import ScholarKeep

final class ExportServiceTests: XCTestCase {

    // MARK: CSV

    func testCSVRoundtrip() throws {
        let student = Student(displayName: "Alex Garcia", program: .fesUA, sfo: .stepUp)
        let e1 = Expense(vendorName: "ABC Tutoring", purchaseDate: .now,
                         subtotal: 80, tax: 0, total: 80, currency: "USD",
                         student: student)
        let e2 = Expense(vendorName: "Best Buy, Inc.", purchaseDate: .now,
                         subtotal: 350, tax: 24.5, total: 374.5, currency: "USD",
                         categoryKey: "device",
                         student: student)
        let url = try CSVExportService.exportExpenses([e1, e2])
        let csv = try String(contentsOf: url)
        XCTAssertTrue(csv.contains("ABC Tutoring"))
        // Vendor with comma must be quoted
        XCTAssertTrue(csv.contains("\"Best Buy, Inc.\""))
        XCTAssertTrue(csv.contains("Alex Garcia"))
        XCTAssertTrue(csv.contains("FES-UA"))
        // Two data rows plus header
        XCTAssertEqual(csv.components(separatedBy: "\n").count, 3)
    }

    func testCSVEscapesQuotes() throws {
        let s = Student(displayName: "Test", program: .pep, sfo: .stepUp)
        let e = Expense(vendorName: "He said \"hi\"", total: 10, student: s)
        let url = try CSVExportService.exportExpenses([e])
        let csv = try String(contentsOf: url)
        XCTAssertTrue(csv.contains("\"He said \"\"hi\"\"\""))
    }

    func testCSVEscapesNewlines() throws {
        let s = Student(displayName: "Test", program: .pep, sfo: .stepUp)
        let e = Expense(vendorName: "Multi\nLine", total: 10, student: s)
        let url = try CSVExportService.exportExpenses([e])
        let csv = try String(contentsOf: url)
        XCTAssertTrue(csv.contains("\"Multi\nLine\""))
    }

    // MARK: PDF

    func testExpensePDFGeneratesValidPDF() throws {
        let s = Student(displayName: "Sam Lee", program: .fesUA, sfo: .stepUp)
        var checklist = ReadinessChecklist()
        checklist.itemizedReceipt = true
        checklist.proofOfPayment = false
        checklist.studentNamePresent = true
        let expense = Expense(
            vendorName: "Local Tutor LLC",
            purchaseDate: .now,
            subtotal: 80,
            tax: 0,
            total: 80,
            categoryKey: "tutoring",
            paymentMethod: .ach,
            acquisitionPath: .reimbursement,
            eligibilityResult: .likelyEligible,
            eligibilityReason: "Tutoring is eligible.",
            matchedRuleKeys: ["tutoring"],
            notes: "Weekly math session.",
            student: s
        )
        expense.readinessChecklist = checklist
        let url = try PDFExportService.exportExpense(expense)
        let pdf = PDFDocument(url: url)
        XCTAssertNotNil(pdf)
        XCTAssertGreaterThan(pdf!.pageCount, 0)
        let text = pdf?.string ?? ""
        XCTAssertTrue(text.contains("Local Tutor LLC"))
        XCTAssertTrue(text.contains("Sam Lee"))
        XCTAssertTrue(text.contains("FES-UA"))
    }

    func testClaimPDFWithMultipleExpensesGeneratesPages() throws {
        let s = Student(displayName: "Sam Lee", program: .pep, sfo: .stepUp)
        let e1 = Expense(vendorName: "Vendor A", total: 50, student: s)
        let e2 = Expense(vendorName: "Vendor B", total: 75, student: s)
        let claim = Claim(title: "April reimbursements", status: .draft, student: s,
                          expenses: [e1, e2])
        e1.claim = claim
        e2.claim = claim
        let url = try PDFExportService.exportClaim(claim)
        let pdf = PDFDocument(url: url)
        XCTAssertNotNil(pdf)
        // Claim summary + 2 expense pages, at least
        XCTAssertGreaterThanOrEqual(pdf!.pageCount, 3)
    }

    func testPDFLongContentPaginates() throws {
        // Make an expense with many line items so it overflows a page
        let s = Student(displayName: "Sam Lee", program: .pep, sfo: .stepUp)
        var items: [LineItem] = []
        for i in 0..<80 {
            items.append(LineItem(descriptionText: "Item \(i) description that takes up space",
                                  amount: Decimal(i)))
        }
        let expense = Expense(vendorName: "Big Vendor", total: 1000,
                              student: s, lineItems: items)
        let url = try PDFExportService.exportExpense(expense)
        let pdf = PDFDocument(url: url)
        XCTAssertNotNil(pdf)
        XCTAssertGreaterThanOrEqual(pdf!.pageCount, 2,
                                    "Long content should paginate to more than 1 page")
    }
}
