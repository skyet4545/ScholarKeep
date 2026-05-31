import Foundation
import SwiftData

@Model
final class Student {
    // v0.7: dropped @Attribute(.unique) — CloudKit can't enforce. UUIDs are
    // unique by nature so behaviourally equivalent.
    var id: UUID = UUID()
    var displayName: String = ""
    var programRaw: String = Program.fesUA.rawValue
    var sfoRaw: String = SFO.stepUp.rawValue
    var gradeLevel: String = ""
    var county: String = ""
    var schoolYear: String = ""
    var awardAmount: Decimal?
    var notes: String = ""
    var createdAt: Date = Date.now

    /// PEP-only: date the Student Learning Plan was approved. Purchases before
    /// this date are permanently ineligible under PEP — no appeals.
    var slpApprovedDate: Date?

    @Relationship(deleteRule: .cascade, inverse: \Expense.student) var expenses: [Expense] = []
    @Relationship(deleteRule: .cascade, inverse: \Claim.student) var claims: [Claim] = []
    @Relationship(deleteRule: .cascade, inverse: \DevicePurchase.student) var devicePurchases: [DevicePurchase] = []
    @Relationship(deleteRule: .cascade, inverse: \Provider.student) var providers: [Provider] = []
    @Relationship(deleteRule: .cascade, inverse: \PreAuthorization.student) var preAuthorizations: [PreAuthorization] = []
    @Relationship(deleteRule: .cascade, inverse: \BalanceEntry.student) var balanceEntries: [BalanceEntry] = []
    @Relationship(deleteRule: .cascade, inverse: \RecurringTask.student) var recurringTasks: [RecurringTask] = []

    init(
        id: UUID = UUID(),
        displayName: String,
        program: Program,
        sfo: SFO,
        gradeLevel: String = "",
        county: String = "",
        schoolYear: String = SchoolYear.label(),
        awardAmount: Decimal? = nil,
        notes: String = "",
        slpApprovedDate: Date? = nil,
        createdAt: Date = Date.now
    ) {
        self.id = id
        self.displayName = displayName
        self.programRaw = program.rawValue
        self.sfoRaw = sfo.rawValue
        self.gradeLevel = gradeLevel
        self.county = county
        self.schoolYear = schoolYear
        self.awardAmount = awardAmount
        self.notes = notes
        self.slpApprovedDate = slpApprovedDate
        self.createdAt = createdAt
    }

    var program: Program {
        get { Program(rawValue: programRaw) ?? .fesUA }
        set { programRaw = newValue.rawValue }
    }

    var sfo: SFO {
        get { SFO(rawValue: sfoRaw) ?? .stepUp }
        set { sfoRaw = newValue.rawValue }
    }

    /// Convenience: does this PEP student have an approved SLP that pre-dates `purchaseDate`?
    /// Always true for non-PEP students.
    func slpApprovedBefore(_ purchaseDate: Date) -> Bool {
        guard program == .pep else { return true }
        guard let approved = slpApprovedDate else { return false }
        return approved <= purchaseDate
    }
}
