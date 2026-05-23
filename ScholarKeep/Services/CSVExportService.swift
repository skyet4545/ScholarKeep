import Foundation

enum CSVExportService {
    static func exportExpenses(_ expenses: [Expense]) throws -> URL {
        let header = ["Date", "Vendor", "Student", "Program", "Path", "Category", "Subtotal", "Tax", "Shipping", "Total", "Currency", "Eligibility", "Pre-auth required", "Pre-auth #", "Claim", "Claim status", "Notes"]
        var rows: [[String]] = [header]
        for e in expenses {
            rows.append([
                e.purchaseDate.formatted(date: .numeric, time: .omitted),
                e.vendorName,
                e.student?.displayName ?? "",
                e.student?.program.shortName ?? "",
                e.acquisitionPath.shortName,
                e.categoryKey ?? "",
                NSDecimalNumber(decimal: e.subtotal).stringValue,
                NSDecimalNumber(decimal: e.tax).stringValue,
                NSDecimalNumber(decimal: e.shipping).stringValue,
                NSDecimalNumber(decimal: e.total).stringValue,
                e.currency,
                e.eligibilityResult?.displayName ?? "",
                e.requiresPreAuth ? "yes" : "",
                e.preAuthNumber ?? "",
                e.claim?.title ?? "",
                e.claim?.status.displayName ?? "",
                e.notes
            ])
        }
        let csv = rows.map { row in
            row.map { field in
                let needsQuotes = field.contains(",") || field.contains("\"") || field.contains("\n")
                var s = field.replacingOccurrences(of: "\"", with: "\"\"")
                if needsQuotes { s = "\"\(s)\"" }
                return s
            }.joined(separator: ",")
        }.joined(separator: "\n")

        let dir = FileManager.default.temporaryDirectory.appendingPathComponent("ScholarKeepExports", isDirectory: true)
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let url = dir.appendingPathComponent("ScholarKeep_Expenses_\(Date().formatted(.iso8601.year().month().day())).csv")
        try csv.data(using: .utf8)?.write(to: url, options: .atomic)
        return url
    }
}
