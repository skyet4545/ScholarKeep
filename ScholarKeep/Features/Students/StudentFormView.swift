import SwiftUI
import SwiftData

/// Reusable form used for both creating and editing a student.
struct StudentFormView: View {
    @Binding var displayName: String
    @Binding var program: Program
    @Binding var sfo: SFO
    @Binding var gradeLevel: String
    @Binding var county: String
    @Binding var schoolYear: String
    @Binding var awardAmountText: String
    @Binding var notes: String
    /// PEP-only: when the Student Learning Plan was approved.
    var slpApprovedDate: Binding<Date?>? = nil

    var body: some View {
        Form {
            Section("Student") {
                TextField("Student name", text: $displayName)
                    .textContentType(.name)
                    .textInputAutocapitalization(.words)

                Picker("Program", selection: $program) {
                    ForEach(Program.allCases) { p in
                        Text(p.displayName).tag(p)
                    }
                }

                Picker("Scholarship organization", selection: $sfo) {
                    ForEach(SFO.allCases) { s in
                        Text(s.displayName).tag(s)
                    }
                }

                TextField("Grade level (e.g. 3rd, K, 9th)", text: $gradeLevel)
                TextField("County", text: $county)
                    .textInputAutocapitalization(.words)
                TextField("School year (e.g. 2026-27)", text: $schoolYear)
                    .keyboardType(.numbersAndPunctuation)
                    .autocorrectionDisabled()
            }

            Section {
                TextField("Award amount (optional)", text: $awardAmountText)
                    .keyboardType(.decimalPad)
            } header: {
                Text("Manual balance")
            } footer: {
                Text("Enter the award amount you've been told to expect. ScholarKeep does not connect to EMA/SMP — this is your own record.")
            }

            if program == .pep, let slpBinding = slpApprovedDate {
                Section {
                    Toggle("SLP has been approved", isOn: Binding(
                        get: { slpBinding.wrappedValue != nil },
                        set: { newValue in
                            slpBinding.wrappedValue = newValue ? (slpBinding.wrappedValue ?? .now) : nil
                        }
                    ))
                    if let unwrapped = slpBinding.wrappedValue {
                        DatePicker("Approved on",
                                   selection: Binding(
                                    get: { unwrapped },
                                    set: { slpBinding.wrappedValue = $0 }
                                   ),
                                   displayedComponents: .date)
                    }
                } header: {
                    Text("Student Learning Plan (PEP)")
                } footer: {
                    Text("Any purchase made before the SLP is approved is permanently ineligible under PEP. There is no appeals process for this — set the approval date carefully.")
                }
            }

            Section("Notes") {
                TextField("Notes", text: $notes, axis: .vertical)
                    .lineLimit(3...6)
            }
        }
    }
}

/// Mutable working copy used by Add/Edit screens.
struct StudentFormDraft {
    var displayName: String = ""
    var program: Program = .fesUA
    var sfo: SFO = .stepUp
    var gradeLevel: String = ""
    var county: String = ""
    var schoolYear: String = SchoolYear.label()
    var awardAmountText: String = ""
    var notes: String = ""
    var slpApprovedDate: Date? = nil

    var isValid: Bool {
        !displayName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !schoolYear.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var awardAmount: Decimal? {
        let trimmed = awardAmountText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }
        return DecimalParsing.parse(trimmed)
    }

    init() {}

    init(student: Student) {
        self.displayName = student.displayName
        self.program = student.program
        self.sfo = student.sfo
        self.gradeLevel = student.gradeLevel
        self.county = student.county
        self.schoolYear = student.schoolYear
        if let amount = student.awardAmount {
            self.awardAmountText = NSDecimalNumber(decimal: amount).stringValue
        }
        self.notes = student.notes
        self.slpApprovedDate = student.slpApprovedDate
    }

    func apply(to student: Student) {
        student.displayName = displayName.trimmingCharacters(in: .whitespaces)
        student.program = program
        student.sfo = sfo
        student.gradeLevel = gradeLevel.trimmingCharacters(in: .whitespaces)
        student.county = county.trimmingCharacters(in: .whitespaces)
        student.schoolYear = schoolYear.trimmingCharacters(in: .whitespaces)
        student.awardAmount = awardAmount
        student.notes = notes
        student.slpApprovedDate = (program == .pep) ? slpApprovedDate : nil
    }

    func newStudent() -> Student {
        Student(
            displayName: displayName.trimmingCharacters(in: .whitespaces),
            program: program,
            sfo: sfo,
            gradeLevel: gradeLevel.trimmingCharacters(in: .whitespaces),
            county: county.trimmingCharacters(in: .whitespaces),
            schoolYear: schoolYear.trimmingCharacters(in: .whitespaces),
            awardAmount: awardAmount,
            notes: notes,
            slpApprovedDate: (program == .pep) ? slpApprovedDate : nil
        )
    }
}
