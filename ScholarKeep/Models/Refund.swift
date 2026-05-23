import Foundation
import SwiftData

/// A refund/return/rebate on a previous Expense. ESA rules forbid receiving any
/// payment, refund, or rebate of scholarship funds — tracking these lets the
/// parent reduce their claim amount or withdraw the claim entirely.
@Model
final class Refund {
    @Attribute(.unique) var id: UUID
    var refundDate: Date
    var refundAmount: Decimal
    var reason: String          // free text: "returned to store", "manufacturer rebate", etc.
    var notes: String
    var expense: Expense?
    var createdAt: Date

    init(
        id: UUID = UUID(),
        refundDate: Date = .now,
        refundAmount: Decimal,
        reason: String = "",
        notes: String = "",
        expense: Expense? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.refundDate = refundDate
        self.refundAmount = refundAmount
        self.reason = reason
        self.notes = notes
        self.expense = expense
        self.createdAt = createdAt
    }
}
