import Foundation

enum ClaimStatus: String, Codable, CaseIterable, Identifiable {
    case draft
    case readyToSubmit
    case submitted
    case pendingReview
    case onHold
    case approved
    case paidReimbursed
    case denied

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .draft:          return "Draft"
        case .readyToSubmit:  return "Ready to submit"
        case .submitted:      return "Submitted"
        case .pendingReview:  return "Pending review"
        case .onHold:         return "On hold"
        case .approved:       return "Approved"
        case .paidReimbursed: return "Paid / reimbursed"
        case .denied:         return "Denied"
        }
    }

    var systemImageName: String {
        switch self {
        case .draft:          return "doc.text"
        case .readyToSubmit:  return "tray.and.arrow.up"
        case .submitted:      return "paperplane.fill"
        case .pendingReview:  return "hourglass"
        case .onHold:         return "exclamationmark.circle.fill"
        case .approved:       return "checkmark.seal.fill"
        case .paidReimbursed: return "dollarsign.circle.fill"
        case .denied:         return "xmark.octagon.fill"
        }
    }

    /// Board column groupings used by the Kanban view.
    static let boardColumns: [ClaimStatus] = [
        .draft, .readyToSubmit, .submitted, .pendingReview, .onHold, .approved, .paidReimbursed, .denied
    ]
}

enum ReimbursementMethod: String, Codable, CaseIterable, Identifiable {
    case ach
    case check
    case paypal

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .ach:    return "ACH / direct deposit"
        case .check:  return "Check"
        case .paypal: return "PayPal"
        }
    }
}

enum DenialReason: String, Codable, CaseIterable, Identifiable {
    case missingVendorName
    case notItemized
    case missingPriceBreakdown
    case missingProofOfPayment
    case studentNameMismatch
    case missingProviderCredentials
    case missingDatesOfService
    case handwrittenAlteration
    case ineligibleItem
    case multipleProvidersOneClaim
    case overPriceCap
    case missingEducationalBenefitForm
    case missingPreAuth
    case duplicateClaim
    case pastDeadline
    case illegibleImage
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .missingVendorName:            return "Missing vendor / provider name"
        case .notItemized:                  return "Not itemized"
        case .missingPriceBreakdown:        return "Missing price breakdown"
        case .missingProofOfPayment:        return "Missing proof of payment"
        case .studentNameMismatch:          return "Student name doesn't match"
        case .missingProviderCredentials:   return "Missing provider credentials"
        case .missingDatesOfService:        return "Missing dates of service"
        case .handwrittenAlteration:        return "Handwritten alteration"
        case .ineligibleItem:               return "Ineligible item"
        case .multipleProvidersOneClaim:    return "Multiple providers in one claim"
        case .overPriceCap:                 return "Over price cap"
        case .missingEducationalBenefitForm:return "Missing Educational Benefit Form"
        case .missingPreAuth:               return "Missing pre-authorization"
        case .duplicateClaim:               return "Duplicate claim"
        case .pastDeadline:                 return "Past deadline"
        case .illegibleImage:               return "Illegible image"
        case .other:                        return "Other"
        }
    }

    /// Plain-language fix the parent should apply (drives the checklist reset).
    var suggestedFix: String {
        switch self {
        case .missingVendorName:
            return "Get an invoice from the vendor that clearly shows their business name at the top."
        case .notItemized:
            return "Ask the vendor for an itemized receipt that lists each product or service on its own line."
        case .missingPriceBreakdown:
            return "Replace the receipt with one that shows subtotal, tax, shipping, and grand total."
        case .missingProofOfPayment:
            return "Attach a bank or card statement line, a cleared-check screenshot, or a paid-in-full confirmation — separate from the invoice."
        case .studentNameMismatch:
            return "Have the vendor reissue the invoice/receipt with the student's name exactly as it appears on the scholarship record."
        case .missingProviderCredentials:
            return "Ask the provider to add their license number and dates of service to the invoice."
        case .missingDatesOfService:
            return "Add the dates of service to each provider invoice."
        case .handwrittenAlteration:
            return "Request a freshly printed/typed invoice — no handwritten changes."
        case .ineligibleItem:
            return "Remove the ineligible item from this claim. Check the Purchasing Guide to confirm what's allowed."
        case .multipleProvidersOneClaim:
            return "Split this into separate claims — one provider/service per claim."
        case .overPriceCap:
            return "Lower the amount, switch to a compliant option, or apply for pre-authorization where allowed."
        case .missingEducationalBenefitForm:
            return "Complete and attach the Educational Benefit Form for this category (e.g., field trips, theme parks)."
        case .missingPreAuth:
            return "Request pre-authorization for this item through your scholarship portal, then resubmit."
        case .duplicateClaim:
            return "Confirm this expense wasn't already submitted; if it was, withdraw the duplicate."
        case .pastDeadline:
            return "The reimbursement deadline has passed. This may not be recoverable — check with your SFO."
        case .illegibleImage:
            return "Recapture the receipt with better lighting and focus, or scan it as a PDF."
        case .other:
            return "Address the SFO's note, then mark the claim Ready to Submit again."
        }
    }

    /// Which readiness checklist field should reset to unchecked when this reason is set.
    var checklistKey: ChecklistField? {
        switch self {
        case .notItemized, .missingPriceBreakdown, .missingVendorName: return .itemizedReceipt
        case .missingProofOfPayment:                                   return .proofOfPayment
        case .studentNameMismatch:                                     return .studentNamePresent
        case .missingProviderCredentials, .missingDatesOfService:      return .providerCredentials
        case .missingEducationalBenefitForm:                           return .educationalBenefitForm
        case .missingPreAuth:                                          return .preAuthIfRequired
        case .handwrittenAlteration:                                   return .noHandwrittenAlterations
        default:                                                       return nil
        }
    }
}

enum ChecklistField: String, CaseIterable {
    case itemizedReceipt
    case proofOfPayment
    case studentNamePresent
    case providerCredentials
    case educationalBenefitForm
    case preAuthIfRequired
    case noHandwrittenAlterations
}
