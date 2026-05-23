import Foundation
import SwiftData

@Model
final class DevicePurchase {
    @Attribute(.unique) var id: UUID
    var deviceType: String
    var purchaseDate: Date
    var amount: Decimal
    var notes: String
    var student: Student?
    var expense: Expense?

    init(
        id: UUID = UUID(),
        deviceType: String,
        purchaseDate: Date,
        amount: Decimal,
        notes: String = "",
        student: Student? = nil,
        expense: Expense? = nil
    ) {
        self.id = id
        self.deviceType = deviceType
        self.purchaseDate = purchaseDate
        self.amount = amount
        self.notes = notes
        self.student = student
        self.expense = expense
    }

    /// Next eligible date under the 2-year device rule.
    func nextEligibleDate(years: Int) -> Date {
        Calendar.current.date(byAdding: .year, value: years, to: purchaseDate) ?? purchaseDate
    }
}
