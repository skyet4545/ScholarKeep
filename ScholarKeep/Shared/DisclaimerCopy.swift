import Foundation

enum DisclaimerCopy {
    /// Verbatim §16 copy from the build spec. Always shown with the active school year.
    static func full(schoolYear: String) -> String {
        """
        Not affiliated with the State of Florida, the Florida Department of Education, \
        Step Up For Students, AAA Scholarship Foundation, or EMA. ScholarKeep is a personal \
        record-keeping and preparation tool. It does not connect to, submit to, or retrieve \
        data from any official scholarship system.

        Eligibility results are estimates based on published program rules as of the \
        \(schoolYear) school year and may be incomplete or out of date. Always confirm \
        purchases and requirements against your program's official Purchasing Guide and \
        Family Handbook before buying or submitting.

        You are responsible for your own submissions and records.
        """
    }

    static let short = "Personal companion tool — not affiliated with FLDOE, Step Up, AAA, or EMA. Confirm everything against the official Purchasing Guide."
}
