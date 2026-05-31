import Foundation
import SwiftData

@Model
final class LineItem {
    var id: UUID = UUID()
    var descriptionText: String = ""
    var quantity: Int = 1
    var unitPrice: Decimal = 0
    var amount: Decimal = 0
    var eligibilityFlagRaw: String?
    var matchedRuleKey: String?
    var expense: Expense?

    init(
        id: UUID = UUID(),
        descriptionText: String,
        quantity: Int = 1,
        unitPrice: Decimal = 0,
        amount: Decimal = 0,
        eligibilityFlag: EligibilityStatus? = nil,
        matchedRuleKey: String? = nil,
        expense: Expense? = nil
    ) {
        self.id = id
        self.descriptionText = descriptionText
        self.quantity = quantity
        self.unitPrice = unitPrice
        self.amount = amount
        self.eligibilityFlagRaw = eligibilityFlag?.rawValue
        self.matchedRuleKey = matchedRuleKey
        self.expense = expense
    }

    var eligibilityFlag: EligibilityStatus? {
        get { eligibilityFlagRaw.flatMap(EligibilityStatus.init(rawValue:)) }
        set { eligibilityFlagRaw = newValue?.rawValue }
    }
}
