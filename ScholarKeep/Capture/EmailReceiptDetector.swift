import Foundation

struct EmailReceiptDetection: Equatable {
    let score: Int
    let reasons: [String]

    var isLikelyReceipt: Bool { score >= 4 }
}

enum EmailReceiptDetector {
    private static let strongSubjectTerms = [
        "receipt", "invoice", "order confirmation", "payment confirmation",
        "payment received", "your order", "purchase confirmation"
    ]

    private static let supportingTerms = [
        "order number", "order #", "amount paid", "total paid", "subtotal",
        "tax", "payment method", "paid in full", "billing", "transaction"
    ]

    private static let negativeTerms = [
        "password reset", "security alert", "verify your email", "newsletter",
        "weekly digest", "unsubscribe preferences", "job alert"
    ]

    static func evaluate(
        subject: String,
        sender: String,
        snippet: String,
        bodyText: String,
        hasReceiptAttachment: Bool
    ) -> EmailReceiptDetection {
        let normalizedSubject = subject.lowercased()
        let combined = ([subject, sender, snippet, bodyText].joined(separator: "\n")).lowercased()
        var score = 0
        var reasons: [String] = []

        if let term = strongSubjectTerms.first(where: normalizedSubject.contains) {
            score += 4
            reasons.append("Subject contains “\(term)”")
        }

        let supportingMatches = supportingTerms.filter(combined.contains)
        if !supportingMatches.isEmpty {
            score += min(3, supportingMatches.count)
            reasons.append("Contains purchase details")
        }

        if containsCurrencyAmount(combined) {
            score += 2
            reasons.append("Contains a currency amount")
        }

        if hasReceiptAttachment {
            score += 2
            reasons.append("Includes an image or PDF")
        }

        if let negative = negativeTerms.first(where: normalizedSubject.contains) {
            score -= 5
            reasons.append("Looks unrelated: \(negative)")
        }

        return EmailReceiptDetection(score: score, reasons: reasons)
    }

    static func inferredVendor(sender: String, subject: String) -> String {
        if let displayName = senderDisplayName(sender), !displayName.isEmpty {
            return displayName
        }
        if let domain = senderDomain(sender) {
            let root = domain
                .replacingOccurrences(of: "mail.", with: "")
                .replacingOccurrences(of: "email.", with: "")
                .split(separator: ".")
                .first
                .map(String.init) ?? ""
            if !root.isEmpty {
                return root.replacingOccurrences(of: "-", with: " ").capitalized
            }
        }
        let cleaned = strongSubjectTerms.reduce(subject) {
            $0.replacingOccurrences(of: $1, with: "", options: .caseInsensitive)
        }
        return cleaned.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    static func inferredAmounts(from text: String) -> (subtotal: Decimal?, tax: Decimal?, total: Decimal?) {
        let lines = text.components(separatedBy: .newlines)
        var subtotal: Decimal?
        var tax: Decimal?
        var total: Decimal?

        for line in lines {
            let lower = line.lowercased()
            guard let amount = lastCurrencyAmount(in: line) else { continue }
            if subtotal == nil, lower.contains("subtotal") {
                subtotal = amount
            } else if tax == nil, lower.range(of: #"\btax\b"#, options: .regularExpression) != nil {
                tax = amount
            } else if total == nil,
                      ["grand total", "amount paid", "total paid", "order total", "total"]
                        .contains(where: lower.contains) {
                total = amount
            }
        }

        return (subtotal, tax, total)
    }

    static func inferredDate(from text: String) -> Date? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue)
        else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        return detector.matches(in: text, range: range)
            .compactMap(\.date)
            .first(where: { $0 <= Date().addingTimeInterval(86_400) })
    }

    private static func senderDisplayName(_ sender: String) -> String? {
        guard let bracket = sender.firstIndex(of: "<") else { return nil }
        let value = sender[..<bracket]
            .trimmingCharacters(in: CharacterSet(charactersIn: "\" ").union(.whitespacesAndNewlines))
        return value.isEmpty ? nil : value
    }

    private static func senderDomain(_ sender: String) -> String? {
        guard let at = sender.lastIndex(of: "@") else { return nil }
        let suffix = sender[sender.index(after: at)...]
        let domain = suffix.prefix { $0 != ">" && !$0.isWhitespace }
        return domain.isEmpty ? nil : String(domain).lowercased()
    }

    private static func containsCurrencyAmount(_ text: String) -> Bool {
        text.range(of: #"(?:USD\s*)?\$\s?\d{1,6}(?:,\d{3})*(?:\.\d{2})"#,
                   options: .regularExpression) != nil
    }

    private static func lastCurrencyAmount(in line: String) -> Decimal? {
        let pattern = #"(?:USD\s*)?\$?\s?(\d{1,6}(?:,\d{3})*\.\d{2})"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let matches = regex.matches(in: line, range: NSRange(line.startIndex..., in: line))
        guard let last = matches.last,
              let range = Range(last.range(at: 1), in: line)
        else { return nil }
        return Decimal(string: line[range].replacingOccurrences(of: ",", with: ""))
    }
}
