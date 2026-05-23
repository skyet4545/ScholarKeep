import Foundation
import SwiftData

enum BalanceEntryType: String, Codable, CaseIterable, Identifiable {
    case initialAward            // starting award notification
    case disbursement            // quarterly/monthly fund deposit
    case claimSubmitted          // pending claim (deducted from "available")
    case claimPaid               // SFO reimbursed
    case claimReversedToPending  // SFO un-paid (rare)
    case refundReturned          // parent returned/refunded item
    case directPayDeduction      // MyScholarShop / direct-pay reduces balance
    case manualAdjustment        // parent reconciling with what they see in EMA

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .initialAward:           return "Initial award"
        case .disbursement:           return "Disbursement"
        case .claimSubmitted:         return "Claim submitted (pending)"
        case .claimPaid:              return "Claim paid / reimbursed"
        case .claimReversedToPending: return "Claim reversed"
        case .refundReturned:         return "Refund returned"
        case .directPayDeduction:     return "Direct-pay / MSS deduction"
        case .manualAdjustment:       return "Manual adjustment"
        }
    }

    /// True if this entry adds to the available balance.
    var increasesBalance: Bool {
        switch self {
        case .initialAward, .disbursement, .refundReturned, .claimReversedToPending:
            return true
        case .claimSubmitted, .claimPaid, .directPayDeduction:
            return false
        case .manualAdjustment:
            return true   // amount sign on the entry determines direction
        }
    }
}

/// Single entry in the per-student balance ledger. The parent maintains it
/// manually because the app doesn't connect to EMA/SMP.
@Model
final class BalanceEntry {
    @Attribute(.unique) var id: UUID
    var typeRaw: String
    var amount: Decimal             // always positive; type determines direction
    var date: Date
    var note: String
    var student: Student?
    var relatedClaimID: UUID?       // if tied to a Claim
    var createdAt: Date

    init(
        id: UUID = UUID(),
        type: BalanceEntryType,
        amount: Decimal,
        date: Date = .now,
        note: String = "",
        student: Student? = nil,
        relatedClaimID: UUID? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.typeRaw = type.rawValue
        self.amount = amount
        self.date = date
        self.note = note
        self.student = student
        self.relatedClaimID = relatedClaimID
        self.createdAt = createdAt
    }

    var type: BalanceEntryType {
        get { BalanceEntryType(rawValue: typeRaw) ?? .manualAdjustment }
        set { typeRaw = newValue.rawValue }
    }

    var signedAmount: Decimal {
        type.increasesBalance ? amount : -amount
    }
}

/// Computes balance summaries from a ledger.
enum BalanceLedger {
    struct Summary {
        var availableBalance: Decimal   // running net
        var pendingClaims: Decimal      // already submitted but not yet paid
        var paidClaims: Decimal
        var totalDisbursed: Decimal
    }

    static func summarize(entries: [BalanceEntry]) -> Summary {
        var summary = Summary(availableBalance: 0, pendingClaims: 0, paidClaims: 0, totalDisbursed: 0)
        for e in entries {
            summary.availableBalance += e.signedAmount
            switch e.type {
            case .initialAward, .disbursement:
                summary.totalDisbursed += e.amount
            case .claimSubmitted:
                summary.pendingClaims += e.amount
            case .claimPaid:
                summary.paidClaims += e.amount
                summary.pendingClaims -= e.amount
            case .claimReversedToPending:
                summary.pendingClaims += e.amount
                summary.paidClaims -= e.amount
            default:
                break
            }
        }
        // Pending claims can't go negative due to ordering quirks.
        if summary.pendingClaims < 0 { summary.pendingClaims = 0 }
        return summary
    }
}
