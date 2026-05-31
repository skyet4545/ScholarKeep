import Foundation
import SwiftData

/// A refund/return/rebate on a previous Expense. ESA rules forbid receiving any
/// payment, refund, or rebate of scholarship funds — tracking these lets the
/// parent reduce their claim amount or withdraw the claim entirely.
@Model
final class Refund {
    var id: UUID = UUID()
    var refundDate: Date = Date.now
    var refundAmount: Decimal = 0
    var reason: String = ""      // free text: "returned to store", "manufacturer rebate", etc.
    var notes: String = ""
    var expense: Expense?
    var createdAt: Date = Date.now

    init(
        id: UUID = UUID(),
        refundDate: Date = Date.now,
        refundAmount: Decimal,
        reason: String = "",
        notes: String = "",
        expense: Expense? = nil,
        createdAt: Date = Date.now
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
