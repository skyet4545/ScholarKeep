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
            notes: notes
        )
    }
}
