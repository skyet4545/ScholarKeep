import Foundation
import SwiftData

enum PreAuthStatus: String, Codable, CaseIterable, Identifiable {
    case draft
    case requested
    case approved
    case denied
    case expired

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .draft:     return "Draft"
        case .requested: return "Requested — waiting"
        case .approved:  return "Approved"
        case .denied:    return "Denied"
        case .expired:   return "Expired"
        }
    }
    var systemImageName: String {
        switch self {
        case .draft:     return "doc.text"
        case .requested: return "hourglass"
        case .approved:  return "checkmark.seal.fill"
        case .denied:    return "xmark.octagon.fill"
        case .expired:   return "clock.badge.xmark"
        }
    }
}

/// A pre-authorization request the parent submitted (or is preparing) to the SFO portal.
/// Not all expenses need one — only those flagged by the eligibility engine.
@Model
final class PreAuthorization {
    @Attribute(.unique) var id: UUID
    var statusRaw: String
    var requestedDate: Date?
    var approvedDate: Date?
    var deniedDate: Date?
    var approvedNumber: String        // the number issued by the SFO
    var expirationDate: Date?         // typically end of school year
    var itemDescription: String       // what the parent plans to buy
    var estimatedAmount: Decimal?
    var categoryKey: String?          // RuleCategory key
    var notes: String                 // free text for the parent's own records
    var sfoResponseNote: String       // what the SFO said (denial reason or extra info)
    var createdAt: Date

    var student: Student?
    @Relationship(deleteRule: .nullify, inverse: \Expense.preAuthorization) var expenses: [Expense]

    init(
        id: UUID = UUID(),
        status: PreAuthStatus = .draft,
        requestedDate: Date? = nil,
        approvedDate: Date? = nil,
        deniedDate: Date? = nil,
        approvedNumber: String = "",
        expirationDate: Date? = nil,
        itemDescription: String,
        estimatedAmount: Decimal? = nil,
        categoryKey: String? = nil,
        notes: String = "",
        sfoResponseNote: String = "",
        createdAt: Date = .now,
        student: Student? = nil,
        expenses: [Expense] = []
    ) {
        self.id = id
        self.statusRaw = status.rawValue
        self.requestedDate = requestedDate
        self.approvedDate = approvedDate
        self.deniedDate = deniedDate
        self.approvedNumber = approvedNumber
        self.expirationDate = expirationDate
        self.itemDescription = itemDescription
        self.estimatedAmount = estimatedAmount
        self.categoryKey = categoryKey
        self.notes = notes
        self.sfoResponseNote = sfoResponseNote
        self.createdAt = createdAt
        self.student = student
        self.expenses = expenses
    }

    var status: PreAuthStatus {
        get { PreAuthStatus(rawValue: statusRaw) ?? .draft }
        set { statusRaw = newValue.rawValue }
    }

    var isCurrentlyValid: Bool {
        guard status == .approved else { return false }
        if let exp = expirationDate { return exp >= .now }
        return true
    }
}
