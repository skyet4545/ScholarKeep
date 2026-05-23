import Foundation

/// Tolerant Decimal parser used everywhere a parent might paste/type money.
/// Strips $, commas, spaces, NBSPs, parentheses (negative); empty → nil.
enum DecimalParsing {
    static func parse(_ raw: String?) -> Decimal? {
        guard var s = raw?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty else { return nil }
        var negative = false
        if s.hasPrefix("(") && s.hasSuffix(")") {
            negative = true
            s.removeFirst()
            s.removeLast()
        }
        s = s.replacingOccurrences(of: "$", with: "")
        s = s.replacingOccurrences(of: ",", with: "")
        s = s.replacingOccurrences(of: " ", with: "")
        s = s.replacingOccurrences(of: "\u{00A0}", with: "")    // NBSP
        s = s.replacingOccurrences(of: "USD", with: "")
        guard let value = Decimal(string: s) else { return nil }
        return negative ? -value : value
    }
}
