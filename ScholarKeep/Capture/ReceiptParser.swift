import Foundation

/// Heuristic parse of OCR lines into receipt fields.
struct ParsedReceipt: Sendable {
    var vendorName: String = ""
    var purchaseDate: Date? = nil
    var subtotal: Decimal? = nil
    var tax: Decimal? = nil
    var total: Decimal? = nil
    var lineItems: [ParsedLineItem] = []
    var rawText: String = ""
}

struct ParsedLineItem: Sendable {
    var descriptionText: String
    var amount: Decimal
}

enum ReceiptParser {

    /// Parse OCR lines, top-to-bottom (Vision coords have y=0 at bottom).
    static func parse(lines: [OCRLine]) -> ParsedReceipt {
        let ordered = lines.sorted { $0.boundingBox.midY > $1.boundingBox.midY }
        let plainLines = ordered.map { $0.text }
        var result = ParsedReceipt()
        result.rawText = plainLines.joined(separator: "\n")

        result.vendorName = inferVendor(from: plainLines) ?? ""
        result.purchaseDate = inferDate(from: result.rawText)
        let amounts = inferAmounts(from: plainLines)
        result.total = amounts.total
        result.subtotal = amounts.subtotal
        result.tax = amounts.tax
        result.lineItems = inferLineItems(from: plainLines)
        return result
    }

    // MARK: Vendor

    private static func inferVendor(from lines: [String]) -> String? {
        // First few non-empty lines that aren't pure numbers / known headers.
        let skipPrefixes = ["receipt", "invoice", "store #", "tel:", "phone", "www.", "http"]
        for raw in lines.prefix(6) {
            let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !trimmed.isEmpty else { continue }
            let lower = trimmed.lowercased()
            if skipPrefixes.contains(where: { lower.hasPrefix($0) }) { continue }
            if trimmed.range(of: "^[\\d\\s\\-\\.,$#]+$", options: .regularExpression) != nil { continue }
            return trimmed
        }
        return lines.first?.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    // MARK: Date

    private static func inferDate(from text: String) -> Date? {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.date.rawValue) else { return nil }
        let range = NSRange(text.startIndex..., in: text)
        let matches = detector.matches(in: text, options: [], range: range)
        // Prefer earliest match (typically the printed transaction date sits near the top).
        return matches.compactMap { $0.date }.min(by: { abs($0.timeIntervalSinceNow) < abs($1.timeIntervalSinceNow) })
    }

    // MARK: Amounts

    private struct InferredAmounts { var total: Decimal?; var subtotal: Decimal?; var tax: Decimal? }

    private static func inferAmounts(from lines: [String]) -> InferredAmounts {
        var amounts = InferredAmounts()
        for line in lines {
            let lower = line.lowercased()
            let value = extractAmount(from: line)
            guard let value else { continue }
            if amounts.total == nil,
               (lower.contains("grand total") || lower.contains("total due") || lower.contains("amount due") || lower.contains("balance due")) {
                amounts.total = value
                continue
            }
            if amounts.subtotal == nil, lower.contains("subtotal") {
                amounts.subtotal = value
                continue
            }
            if amounts.tax == nil, lower.contains("tax") {
                amounts.tax = value
                continue
            }
            if amounts.total == nil, lower.contains("total") {
                amounts.total = value
            }
        }
        // Fallback: total = largest currency value found anywhere.
        if amounts.total == nil {
            let allAmounts = lines.compactMap { extractAmount(from: $0) }
            amounts.total = allAmounts.max(by: { $0 < $1 })
        }
        return amounts
    }

    /// Find the last currency-like number on a line and parse it.
    private static func extractAmount(from line: String) -> Decimal? {
        // Match patterns like 12.34, $12.34, 1,234.56, -12.34
        let pattern = #"(-?\$?\s?\d{1,3}(?:[,\d]{0,12})?\.\d{2})"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return nil }
        let range = NSRange(line.startIndex..., in: line)
        let matches = regex.matches(in: line, options: [], range: range)
        guard let last = matches.last, let r = Range(last.range, in: line) else { return nil }
        var s = String(line[r])
        s = s.replacingOccurrences(of: "$", with: "")
        s = s.replacingOccurrences(of: ",", with: "")
        s = s.replacingOccurrences(of: " ", with: "")
        return Decimal(string: s)
    }

    // MARK: Line items

    private static func inferLineItems(from lines: [String]) -> [ParsedLineItem] {
        var items: [ParsedLineItem] = []
        let skipKeywords = ["subtotal", "total", "tax", "tip", "tender", "balance", "change", "card", "visa", "mastercard", "approved", "auth", "thank you", "phone", "tel"]
        for line in lines {
            let lower = line.lowercased()
            if skipKeywords.contains(where: { lower.contains($0) }) { continue }
            guard let amount = extractAmount(from: line) else { continue }
            // Strip the amount from the trailing end to keep the description.
            let withoutAmount = line.replacingOccurrences(of: amount.formattedTrailingPattern(), with: "", options: .regularExpression)
            let description = withoutAmount.trimmingCharacters(in: .whitespacesAndNewlines)
            guard description.count >= 2 else { continue }
            items.append(ParsedLineItem(descriptionText: description, amount: amount))
        }
        // Cap to a reasonable number to avoid clutter.
        return Array(items.prefix(20))
    }
}

private extension Decimal {
    /// Returns a regex-suitable string that loosely matches this amount as it appeared.
    func formattedTrailingPattern() -> String {
        // Generic trailing currency strip: any $? \d+(,\d+)*\.\d{2} at end-of-line
        return #"\$?\s?\d{1,3}(?:[,\d]{0,12})?\.\d{2}\s*$"#
    }
}
