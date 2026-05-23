import SwiftUI
import SwiftData

/// Standalone "Can I buy this?" checker — no receipt required.
struct PrePurchaseCheckerView: View {
    @Environment(AppSettings.self) private var settings
    @Query(sort: \Student.createdAt) private var students: [Student]

    @State private var description: String = ""
    @State private var amountText: String = ""
    @State private var path: AcquisitionPath = .reimbursement
    @State private var studentID: UUID?
    @State private var result: EligibilityResult?

    var body: some View {
        NavigationStack {
            Form {
                Section("Who is this for?") {
                    Picker("Student", selection: $studentID) {
                        Text("Choose…").tag(UUID?.none)
                        ForEach(students) { s in
                            Text("\(s.displayName) (\(s.program.shortName))").tag(UUID?.some(s.id))
                        }
                    }
                }
                Section("What are you buying?") {
                    TextField("Describe the item or service", text: $description, axis: .vertical)
                        .lineLimit(2...4)
                    HStack {
                        Text("Amount")
                        Spacer()
                        TextField("0.00", text: $amountText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 120)
                    }
                    Picker("Payment path", selection: $path) {
                        ForEach(AcquisitionPath.allCases) { Text($0.displayName).tag($0) }
                    }
                }
                Section {
                    Button("Check") { runCheck() }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                        .disabled(activeStudent == nil || description.trimmingCharacters(in: .whitespaces).isEmpty)
                }
                if let result {
                    Section("Result") {
                        EligibilityBadgeView(result: result)
                    }
                }
                Section {
                    Text("Estimate only — confirm against the official Purchasing Guide before buying.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .navigationTitle("Can I buy this?")
            .onAppear {
                if studentID == nil { studentID = settings.activeStudentID ?? students.first?.id }
            }
        }
    }

    private var activeStudent: Student? {
        guard let id = studentID else { return nil }
        return students.first { $0.id == id }
    }

    private func runCheck() {
        guard let student = activeStudent, let engine = RulesetLoader.shared.engine else { return }
        let amount = Decimal(string: amountText) ?? 0
        let withinDeviceWindow = DeviceWindowChecker.studentHasRecentDevice(
            student: student,
            within: engine.ruleset.globalRules.deviceReplacementYears
        )
        result = engine.evaluateFreeText(description, amount: amount,
                                         program: student.program,
                                         acquisitionPath: path,
                                         studentHasDeviceWithinWindow: withinDeviceWindow)
    }
}
