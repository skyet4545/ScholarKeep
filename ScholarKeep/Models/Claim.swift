import Foundation
import SwiftData

@Model
final class Claim {
    var id: UUID = UUID()
    var title: String = ""
    var statusRaw: String = ClaimStatus.draft.rawValue
    var submittedDate: Date?
    var decisionDate: Date?
    var paidDate: Date?
    var onHoldStartedAt: Date?

    var reimbursementMethodRaw: String?
    var expectedPayout: Decimal?
    var actualPayout: Decimal?

    var denialReasonRaw: String?
    var denialNote: String = ""
    var appealNote: String = ""

    var createdAt: Date = Date.now

    var student: Student?
    @Relationship(deleteRule: .nullify, inverse: \Expense.claim) var expenses: [Expense] = []
    @Relationship(deleteRule: .cascade, inverse: \StatusEvent.claim) var statusEvents: [StatusEvent] = []

    init(
        id: UUID = UUID(),
        title: String,
        status: ClaimStatus = .draft,
        submittedDate: Date? = nil,
        decisionDate: Date? = nil,
        paidDate: Date? = nil,
        onHoldStartedAt: Date? = nil,
        reimbursementMethod: ReimbursementMethod? = nil,
        expectedPayout: Decimal? = nil,
        actualPayout: Decimal? = nil,
        denialReason: DenialReason? = nil,
        denialNote: String = "",
        appealNote: String = "",
        createdAt: Date = Date.now,
        student: Student? = nil,
        expenses: [Expense] = [],
        statusEvents: [StatusEvent] = []
    ) {
        self.id = id
        self.title = title
        self.statusRaw = status.rawValue
        self.submittedDate = submittedDate
        self.decisionDate = decisionDate
        self.paidDate = paidDate
        self.onHoldStartedAt = onHoldStartedAt
        self.reimbursementMethodRaw = reimbursementMethod?.rawValue
        self.expectedPayout = expectedPayout
        self.actualPayout = actualPayout
        self.denialReasonRaw = denialReason?.rawValue
        self.denialNote = denialNote
        self.appealNote = appealNote
        self.createdAt = createdAt
        self.student = student
        self.expenses = expenses
        self.statusEvents = statusEvents
    }

    var status: ClaimStatus {
        get { ClaimStatus(rawValue: statusRaw) ?? .draft }
        set { statusRaw = newValue.rawValue }
    }

    var reimbursementMethod: ReimbursementMethod? {
        get { reimbursementMethodRaw.flatMap(ReimbursementMethod.init(rawValue:)) }
        set { reimbursementMethodRaw = newValue?.rawValue }
    }

    var denialReason: DenialReason? {
        get { denialReasonRaw.flatMap(DenialReason.init(rawValue:)) }
        set { denialReasonRaw = newValue?.rawValue }
    }
}
