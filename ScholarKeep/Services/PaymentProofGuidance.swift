import Foundation

/// Payment-method-aware guidance the UI shows next to the "Add proof of payment" button.
enum PaymentProofGuidance {
    static func tips(for method: PaymentMethod) -> [String] {
        switch method {
        case .card:
            return [
                "Capture the cardholder statement line showing date, amount, merchant, and the last 4 digits of the card.",
                "Missing card last-4 is the #1 cited reason claims get put on hold.",
                "A card receipt is NOT proof of payment by itself — it's a transaction receipt."
            ]
        case .check:
            return [
                "Cleared check image showing BOTH the front and the back (with bank's clearance stamp).",
                "Or: a screenshot from your online banking showing the check cleared, with date, amount, and payee."
            ]
        case .paypal:
            return [
                "PayPal transaction screenshot showing date, amount, payee name.",
                "PayPal can sometimes be reviewed more strictly — including the bank/card the PayPal balance was funded from helps."
            ]
        case .ach:
            return [
                "Bank statement line for the ACH transfer with date, amount, and recipient.",
                "Wire transfer confirmation works too."
            ]
        case .cash:
            return [
                "Most SFOs DO NOT reimburse cash purchases to private sellers.",
                "If the vendor is a business and you have an itemized receipt, attach it — but expect this to be reviewed manually."
            ]
        case .other:
            return [
                "Provide whatever documentation shows the payment cleared (date, amount, payee, payment source)."
            ]
        }
    }
}
