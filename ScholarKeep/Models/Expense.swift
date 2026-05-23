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

    var eligibilityResultRaw: String?
    var eligibilityReason: String
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
    @Relationship(deleteRule: .cascade, inverse: \LineItem.expense) var lineItems: [LineItem]
    @Relationship(deleteRule: .cascade, inverse: \Attachment.expense) var attachments: [Attachment]
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
        eligibilityResult: EligibilityStatus? = nil,
        eligibilityReason: String = "",
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
        lineItems: [LineItem] = [],
        attachments: [Attachment] = [],
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
        self.eligibilityResultRaw = eligibilityResult?.rawValue
        self.eligibilityReason = eligibilityReason
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
        self.lineItems = lineItems
        self.attachments = attachments
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
}
