import Foundation
import SwiftData

@Model
final class Expense {
    @Attribute(.unique) var id: UUID
    var vendorName: String
    var purchaseDate: Date
    var subtotal: Decimal
    var tax: Decimal
    var shipping: Decimal
    var total: Decimal
    var currency: String

    var categoryKey: String?
    var subcategory: String
    var paymentMethodRaw: String
    var acquisitionPathRaw: String

    // NEW v0.2 fields
    /// Last 4 digits of the card used (most-cited PoP denial reason).
    var cardLast4: String?
    /// Parent confirmed no insurance/HSA/School Readiness paid any portion.
    var noDoubleDipConfirmed: Bool
    /// PaidInFull flag for theme-park-style claims.
    var paidInFull: Bool
    /// Total refund amount applied (derived from refunds[]).
    var refundedAmount: Decimal { refunds.reduce(0) { $0 + $1.refundAmount } }
    /// Net amount eligible for reimbursement after refunds.
    var netReimbursableAmount: Decimal { total - refundedAmount }

    var eligibilityResultRaw: String?
    var eligibilityReason: String
    var eligibilityReasonsList: [String]
    var matchedRuleKeys: [String]
    var eligibilityCheckedAt: Date?
    var rulesetVersion: String?

    var educationalBenefitNote: String
    var requiresPreAuth: Bool
    var preAuthNumber: String?

    var readinessChecklistData: Data?

    var notes: String
    var createdAt: Date

    var student: Student?
    var provider: Provider?
    var preAuthorization: PreAuthorization?
    @Relationship(deleteRule: .cascade, inverse: \LineItem.expense) var lineItems: [LineItem]
    @Relationship(deleteRule: .cascade, inverse: \Attachment.expense) var attachments: [Attachment]
    @Relationship(deleteRule: .cascade, inverse: \Refund.expense) var refunds: [Refund]
    var claim: Claim?

    init(
        id: UUID = UUID(),
        vendorName: String = "",
        purchaseDate: Date = .now,
        subtotal: Decimal = 0,
        tax: Decimal = 0,
        shipping: Decimal = 0,
        total: Decimal = 0,
        currency: String = "USD",
        categoryKey: String? = nil,
        subcategory: String = "",
        paymentMethod: PaymentMethod = .card,
        acquisitionPath: AcquisitionPath = .reimbursement,
        cardLast4: String? = nil,
        noDoubleDipConfirmed: Bool = false,
        paidInFull: Bool = true,
        eligibilityResult: EligibilityStatus? = nil,
        eligibilityReason: String = "",
        eligibilityReasonsList: [String] = [],
        matchedRuleKeys: [String] = [],
        eligibilityCheckedAt: Date? = nil,
        rulesetVersion: String? = nil,
        educationalBenefitNote: String = "",
        requiresPreAuth: Bool = false,
        preAuthNumber: String? = nil,
        readinessChecklist: ReadinessChecklist = ReadinessChecklist(),
        notes: String = "",
        createdAt: Date = .now,
        student: Student? = nil,
        provider: Provider? = nil,
        preAuthorization: PreAuthorization? = nil,
        lineItems: [LineItem] = [],
        attachments: [Attachment] = [],
        refunds: [Refund] = [],
        claim: Claim? = nil
    ) {
        self.id = id
        self.vendorName = vendorName
        self.purchaseDate = purchaseDate
        self.subtotal = subtotal
        self.tax = tax
        self.shipping = shipping
        self.total = total
        self.currency = currency
        self.categoryKey = categoryKey
        self.subcategory = subcategory
        self.paymentMethodRaw = paymentMethod.rawValue
        self.acquisitionPathRaw = acquisitionPath.rawValue
        self.cardLast4 = cardLast4
        self.noDoubleDipConfirmed = noDoubleDipConfirmed
        self.paidInFull = paidInFull
        self.eligibilityResultRaw = eligibilityResult?.rawValue
        self.eligibilityReason = eligibilityReason
        self.eligibilityReasonsList = eligibilityReasonsList
        self.matchedRuleKeys = matchedRuleKeys
        self.eligibilityCheckedAt = eligibilityCheckedAt
        self.rulesetVersion = rulesetVersion
        self.educationalBenefitNote = educationalBenefitNote
        self.requiresPreAuth = requiresPreAuth
        self.preAuthNumber = preAuthNumber
        self.readinessChecklistData = try? JSONEncoder().encode(readinessChecklist)
        self.notes = notes
        self.createdAt = createdAt
        self.student = student
        self.provider = provider
        self.preAuthorization = preAuthorization
        self.lineItems = lineItems
        self.attachments = attachments
        self.refunds = refunds
        self.claim = claim
    }

    var paymentMethod: PaymentMethod {
        get { PaymentMethod(rawValue: paymentMethodRaw) ?? .card }
        set { paymentMethodRaw = newValue.rawValue }
    }

    var acquisitionPath: AcquisitionPath {
        get { AcquisitionPath(rawValue: acquisitionPathRaw) ?? .reimbursement }
        set { acquisitionPathRaw = newValue.rawValue }
    }

    var eligibilityResult: EligibilityStatus? {
        get { eligibilityResultRaw.flatMap(EligibilityStatus.init(rawValue:)) }
        set { eligibilityResultRaw = newValue?.rawValue }
    }

    var readinessChecklist: ReadinessChecklist {
        get {
            guard let data = readinessChecklistData,
                  let decoded = try? JSONDecoder().decode(ReadinessChecklist.self, from: data)
            else { return ReadinessChecklist() }
            return decoded
        }
        set {
            readinessChecklistData = try? JSONEncoder().encode(newValue)
        }
    }

    /// True when the parent has completed every applicable readiness item AND confirmed
    /// no double-billing AND, if a card was used, supplied the last 4 digits.
    var isFullyReadyForSubmit: Bool {
        let checklist = readinessChecklist
        let cardOK: Bool
        switch paymentMethod {
        case .card:
            cardOK = (cardLast4?.count == 4)
        default:
            cardOK = true
        }
        return checklist.isComplete && noDoubleDipConfirmed && cardOK
    }
}
