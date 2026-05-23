import Foundation

/// Decoded versioned ruleset, loaded from JSON at runtime. No eligibility logic
/// is hard-coded in Swift — this struct is the data the engine evaluates.
struct Ruleset: Codable, Equatable {
    let schoolYear: String
    let sourceVersion: String
    let lastUpdated: String
    let disclaimer: String
    let sources: [String]?
    let deadlines: Deadlines
    let globalRules: GlobalRules
    let categories: [RuleCategory]

    struct Deadlines: Codable, Equatable {
        let spendWindowStart: String
        let spendWindowEnd: String
        let reimbursementSubmissionDeadline: String
        let preAuthDeadline: String?
        let reviewDaysMax: Int
        let disbursementSchedule: [String: String]?

        // Backward-compat shim for older seed JSON; modern ruleset uses disbursementSchedule.
        let disbursementDates: [String]?
        let onHoldDays: Int?

        enum CodingKeys: String, CodingKey {
            case spendWindowStart, spendWindowEnd, reimbursementSubmissionDeadline
            case preAuthDeadline, reviewDaysMax, disbursementSchedule
            case disbursementDates, onHoldDays
        }

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: CodingKeys.self)
            self.spendWindowStart = try c.decode(String.self, forKey: .spendWindowStart)
            self.spendWindowEnd = try c.decode(String.self, forKey: .spendWindowEnd)
            self.reimbursementSubmissionDeadline = try c.decode(String.self, forKey: .reimbursementSubmissionDeadline)
            self.preAuthDeadline = try c.decodeIfPresent(String.self, forKey: .preAuthDeadline)
            self.reviewDaysMax = try c.decode(Int.self, forKey: .reviewDaysMax)
            self.disbursementSchedule = try c.decodeIfPresent([String: String].self, forKey: .disbursementSchedule)
            self.disbursementDates = try c.decodeIfPresent([String].self, forKey: .disbursementDates)
            self.onHoldDays = try c.decodeIfPresent(Int.self, forKey: .onHoldDays)
        }

        func encode(to encoder: Encoder) throws {
            var c = encoder.container(keyedBy: CodingKeys.self)
            try c.encode(spendWindowStart, forKey: .spendWindowStart)
            try c.encode(spendWindowEnd, forKey: .spendWindowEnd)
            try c.encode(reimbursementSubmissionDeadline, forKey: .reimbursementSubmissionDeadline)
            try c.encodeIfPresent(preAuthDeadline, forKey: .preAuthDeadline)
            try c.encode(reviewDaysMax, forKey: .reviewDaysMax)
            try c.encodeIfPresent(disbursementSchedule, forKey: .disbursementSchedule)
            try c.encodeIfPresent(disbursementDates, forKey: .disbursementDates)
            try c.encodeIfPresent(onHoldDays, forKey: .onHoldDays)
        }
    }

    struct GlobalRules: Codable, Equatable {
        let deviceReplacementYears: Int
        let peripheralPreAuthOver: Decimal
        let balanceCapNoNewFundingFESUA: Decimal
        let frequencyRuleCrossesProgramSwitches: Bool?
        let stepUpSupportPhone: String?
    }
}

struct RuleCategory: Codable, Equatable, Identifiable {
    let key: String
    let displayName: String
    let programs: [String]
    let eligibility: String
    let keywords: [String]
    let phrasalKeywords: [String]?     // matched anywhere in text (no word boundary)
    let ineligibleKeywords: [String]?
    let requiresStudentName: Bool?
    let requiresProviderCredentials: Bool?
    let requiresEducationalBenefitForm: Bool?
    let requiresPreAuth: Bool?
    let requiresPreAuthIfWithinDeviceWindow: Bool?
    let requiresPreAuthIfNotPubliclyAvailable: Bool?
    let requiresFloridaTeacherCertificate: Bool?
    let requiresFloridaLicensedProvider: Bool?
    let requiresApprovedProvider: Bool?
    let needsPreAuthIfPeripheralOver: Decimal?
    let frequencyYears: Int?
    let providerCredentialOptions: [String]?
    let caps: CategoryCaps?
    let ineligibleForProgram: [String: String]?
    let notes: String?
    let sourceCitation: String

    var id: String { key }

    struct CategoryCaps: Codable, Equatable {
        let maxAmount: Decimal?
        let perStudentPerClaim: Bool?
        let perStudentPerYear: Bool?
        let paidInFull: Bool?
        let noBundling: Bool?
        let tvSizeInchesMax: Int?
    }

    func applies(toProgram program: Program) -> Bool {
        programs.contains(program.rawValue)
    }

    func excludesNote(for program: Program) -> String? {
        ineligibleForProgram?[program.rawValue]
    }

    var baseEligibility: EligibilityStatus {
        EligibilityStatus(rawValue: eligibility) ?? .unknown
    }
}
