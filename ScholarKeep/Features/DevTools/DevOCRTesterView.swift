import SwiftUI
import UIKit

/// Hidden dev tool surfaced by launching with `--devtools`.
/// Paste raw OCR text from a real receipt and watch what the parser extracts.
/// Lets us iterate on `ReceiptParser` heuristics without running OCR over and over.
struct DevOCRTesterView: View {
    @State private var rawInput: String = ""
    @State private var parsed: ParsedReceipt?

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $rawInput)
                        .frame(minHeight: 200)
                        .font(.system(.body, design: .monospaced))
                    Button("Parse") { run() }
                        .buttonStyle(.borderedProminent)
                    Button("Load sample receipt") { loadSample() }
                } header: {
                    Text("Raw OCR text (one line per detected line)")
                }

                if let parsed {
                    Section("Parser output") {
                        LabeledContent("Vendor", value: parsed.vendorName.isEmpty ? "—" : parsed.vendorName)
                        LabeledContent("Date", value: parsed.purchaseDate?.formatted(date: .abbreviated, time: .omitted) ?? "—")
                        LabeledContent("Subtotal", value: parsed.subtotal?.formatted(.currency(code: "USD")) ?? "—")
                        LabeledContent("Tax", value: parsed.tax?.formatted(.currency(code: "USD")) ?? "—")
                        LabeledContent("Total", value: parsed.total?.formatted(.currency(code: "USD")) ?? "—")
                    }
                    Section("Line items (\(parsed.lineItems.count))") {
                        ForEach(parsed.lineItems.indices, id: \.self) { i in
                            let item = parsed.lineItems[i]
                            HStack {
                                Text(item.descriptionText)
                                Spacer()
                                Text(item.amount.formatted(.currency(code: "USD")))
                                    .monospacedDigit()
                            }
                            .font(.caption)
                        }
                    }
                }
            }
            .navigationTitle("OCR Tester")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func run() {
        // Treat each line as a top-to-bottom OCRLine; assign descending y.
        let lines = rawInput.split(separator: "\n").enumerated().map { (i, text) -> OCRLine in
            let y = 1.0 - (CGFloat(i) / CGFloat(max(rawInput.split(separator: "\n").count, 1)))
            return OCRLine(text: String(text), boundingBox: CGRect(x: 0, y: y, width: 1, height: 0.02))
        }
        parsed = ReceiptParser.parse(lines: lines)
    }

    private func loadSample() {
        rawInput = """
        Target
        123 Main Street, Orlando FL
        04/15/2026
        Spiral Notebook 3.99
        Composition Book 4.50
        Crayola Markers 12.99
        Subtotal 21.48
        Tax 1.50
        Total 22.98
        VISA **** 1234 22.98
        Approved Auth 1234567
        """
    }
}
