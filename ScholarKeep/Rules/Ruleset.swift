import Foundation

/// Decoded versioned ruleset, loaded from JSON at runtime. No eligibility logic
/// is hard-coded in Swift — this struct is the data the engine evaluates.
struct Ruleset: Codable, Equatable {
    let schoolYear: String
    let sourceVersion: String
    let lastUpdated: String
    let disclaimer: String
    let deadlines: Deadlines
    let globalRules: GlobalRules
    let categories: [RuleCategory]

    struct Deadlines: Codable, Equatable {
        let spendWindowStart: String                  // "--07-01"
        let spendWindowEnd: String                    // "--06-30"
        let reimbursementSubmissionDeadline: String   // "--07-31"
        let onHoldDays: Int
        let reviewDaysMax: Int
        let disbursementDates: [String]
    }

    struct GlobalRules: Codable, Equatable {
        let deviceReplacementYears: Int
        let peripheralPreAuthOver: Decimal
        let balanceCapNoNewFundingFESUA: Decimal
    }
}

struct RuleCategory: Codable, Equatable, Identifiable {
    let key: String
    let displayName: String
    let programs: [String]                                  // ["fesUA","pep"]
    let eligibility: String                                 // matches EligibilityStatus rawValue
    let keywords: [String]
    let ineligibleKeywords: [String]?
    let requiresStudentName: Bool?
    let requiresProviderCredentials: Bool?
    let requiresEducationalBenefitForm: Bool?
    let requiresPreAuth: Bool?
    let requiresPreAuthIfWithinDeviceWindow: Bool?
    let caps: CategoryCaps?
    let ineligibleForProgram: [String: String]?
    let notes: String?
    let sourceCitation: String

    var id: String { key }

    struct CategoryCaps: Codable, Equatable {
        let maxAmount: Decimal?
        let perStudentPerClaim: Bool?
        let paidInFull: Bool?
    }

    /// Whether this category applies to the given program.
    func applies(toProgram program: Program) -> Bool {
        programs.contains(program.rawValue)
    }

    /// Returns a per-program ineligibility note if the category excludes this program.
    func excludesNote(for program: Program) -> String? {
        ineligibleForProgram?[program.rawValue]
    }

    var baseEligibility: EligibilityStatus {
        EligibilityStatus(rawValue: eligibility) ?? .unknown
    }
}
