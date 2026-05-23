import Foundation

enum AcquisitionPath: String, Codable, CaseIterable, Identifiable {
    case reimbursement
    case marketplaceDirectPay
    case providerDirectPay

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .reimbursement:        return "Reimbursement"
        case .marketplaceDirectPay: return "Marketplace (direct-pay)"
        case .providerDirectPay:    return "Provider direct-pay"
        }
    }
    var shortName: String {
        switch self {
        case .reimbursement:        return "Reimbursement"
        case .marketplaceDirectPay: return "MSS"
        case .providerDirectPay:    return "Provider"
        }
    }
}

enum PaymentMethod: String, Codable, CaseIterable, Identifiable {
    case card
    case ach
    case check
    case paypal
    case cash
    case other

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .card:   return "Credit / debit card"
        case .ach:    return "Bank transfer (ACH)"
        case .check:  return "Check"
        case .paypal: return "PayPal"
        case .cash:   return "Cash"
        case .other:  return "Other"
        }
    }
}

enum AttachmentType: String, Codable, CaseIterable, Identifiable {
    case receipt
    case proofOfPayment
    case educationalBenefitForm
    case credential
    case other

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .receipt:                return "Receipt / invoice"
        case .proofOfPayment:         return "Proof of payment"
        case .educationalBenefitForm: return "Educational Benefit Form"
        case .credential:             return "Provider credential"
        case .other:                  return "Other"
        }
    }
}

enum EligibilityStatus: String, Codable, CaseIterable {
    case eligible
    case likelyEligible
    case needsPreAuth
    case directPayOnly
    case likelyIneligible
    case ineligible
    case unknown

    var displayName: String {
        switch self {
        case .eligible:         return "Eligible"
        case .likelyEligible:   return "Likely eligible"
        case .needsPreAuth:     return "Needs pre-authorization"
        case .directPayOnly:    return "Direct-pay only"
        case .likelyIneligible: return "Likely ineligible"
        case .ineligible:       return "Ineligible"
        case .unknown:          return "Unknown — verify"
        }
    }

    var systemImageName: String {
        switch self {
        case .eligible, .likelyEligible:      return "checkmark.seal.fill"
        case .needsPreAuth:                   return "exclamationmark.triangle.fill"
        case .directPayOnly:                  return "creditcard.fill"
        case .likelyIneligible, .ineligible:  return "xmark.octagon.fill"
        case .unknown:                        return "questionmark.circle.fill"
        }
    }
}

/// Per-expense readiness checklist (§3.7).
struct ReadinessChecklist: Codable, Hashable {
    var itemizedReceipt: Bool = false
    var proofOfPayment: Bool = false
    var studentNamePresent: Bool = false
    var providerCredentials: Bool? = nil      // nil = not applicable
    var educationalBenefitForm: Bool? = nil   // nil = not applicable
    var preAuthIfRequired: Bool? = nil        // nil = not applicable
    var noHandwrittenAlterations: Bool = false

    /// All applicable items are true.
    var isComplete: Bool {
        itemizedReceipt && proofOfPayment && studentNamePresent && noHandwrittenAlterations
            && (providerCredentials ?? true)
            && (educationalBenefitForm ?? true)
            && (preAuthIfRequired ?? true)
    }

    var totalApplicable: Int {
        4 + (providerCredentials == nil ? 0 : 1)
          + (educationalBenefitForm == nil ? 0 : 1)
          + (preAuthIfRequired == nil ? 0 : 1)
    }

    var checkedCount: Int {
        var n = 0
        if itemizedReceipt { n += 1 }
        if proofOfPayment { n += 1 }
        if studentNamePresent { n += 1 }
        if noHandwrittenAlterations { n += 1 }
        if let v = providerCredentials, v { n += 1 }
        if let v = educationalBenefitForm, v { n += 1 }
        if let v = preAuthIfRequired, v { n += 1 }
        return n
    }
}
