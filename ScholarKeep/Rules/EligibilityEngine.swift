import Foundation

/// Input for an eligibility evaluation.
struct EligibilityInput: Equatable {
    var categoryKey: String?
    var descriptionText: String
    var amount: Decimal
    var program: Program
    var acquisitionPath: AcquisitionPath
    var studentHasDeviceWithinWindow: Bool = false
    /// PEP-only: was the Student Learning Plan approved on/before the purchase date?
    var slpApprovedBeforePurchase: Bool = true
    /// Has the parent indicated insurance / HSA / another source paid any portion?
    var hasInsuranceDoubleDip: Bool = false
    /// Date of the purchase (for spend-window check).
    var purchaseDate: Date = .now
}

/// Structured output from the engine. Pure data — no UI.
struct EligibilityResult: Equatable {
    var status: EligibilityStatus
    var reasons: [String]
    var matchedRuleKeys: [String]
    var requiresPreAuth: Bool
    var requiresStudentName: Bool
    var requiresProviderCredentials: Bool
    var requiresEducationalBenefitForm: Bool
    var requiresFloridaTeacherCertificate: Bool
    var requiresFloridaLicensedProvider: Bool
    var citations: [String]
    var providerCredentialOptions: [String]
}

/// Pure, testable eligibility engine. All rule data comes from a `Ruleset`.
struct EligibilityEngine {
    let ruleset: Ruleset

    init(ruleset: Ruleset) {
        self.ruleset = ruleset
    }

    // MARK: Public entry points

    func evaluate(input: EligibilityInput) -> EligibilityResult {
        // 0. Hard block: insurance double-dip → ineligible regardless of category.
        if input.hasInsuranceDoubleDip {
            return result(
                status: .ineligible,
                reasons: ["Items already paid by insurance, HSA, School Readiness, or another source are not reimbursable (no double-billing)."],
                citations: ["All three Purchasing Guides — Duplicate Billing"]
            )
        }

        // 0a. PEP-only: SLP must be approved on or before the purchase date.
        if input.program == .pep && !input.slpApprovedBeforePurchase {
            return result(
                status: .ineligible,
                reasons: ["Any purchase made before the Student Learning Plan (SLP) is approved is permanently ineligible under PEP. There is no appeals process for this."],
                citations: ["PEP families — SLP approval is a hard prerequisite"]
            )
        }

        // 1. Resolve the category — explicit key first, then keyword inference.
        let categoryFromKey: RuleCategory? = input.categoryKey.flatMap { key in
            ruleset.categories.first { $0.key == key }
        }
        let category = categoryFromKey ?? inferCategory(from: input.descriptionText, program: input.program)

        // 1a. If user supplied no category and we can't infer, BUT the description hits
        //     a clearly ineligible keyword for any program, surface that.
        if category == nil, let hardIneligible = scanIneligibleKeywords(in: input.descriptionText, program: input.program) {
            return result(
                status: .ineligible,
                reasons: ["Matches an ineligible item: \(hardIneligible.displayName).",
                          hardIneligible.notes].compactMap { $0 },
                matchedRuleKeys: [hardIneligible.key],
                citations: [hardIneligible.sourceCitation]
            )
        }

        guard let category else {
            return result(
                status: .unknown,
                reasons: ["No matching rule. Items or services not explicitly listed require pre-authorization — submit a request through your scholarship portal before buying."]
            )
        }

        return evaluate(category: category, input: input)
    }

    /// Free-text "Can I buy this?" entry point — no category selected.
    func evaluateFreeText(_ text: String, amount: Decimal, program: Program,
                          acquisitionPath: AcquisitionPath = .reimbursement,
                          studentHasDeviceWithinWindow: Bool = false,
                          slpApprovedBeforePurchase: Bool = true,
                          hasInsuranceDoubleDip: Bool = false,
                          purchaseDate: Date = .now) -> EligibilityResult {
        let inferred = inferCategory(from: text, program: program)
        let input = EligibilityInput(
            categoryKey: inferred?.key,
            descriptionText: text,
            amount: amount,
            program: program,
            acquisitionPath: acquisitionPath,
            studentHasDeviceWithinWindow: studentHasDeviceWithinWindow,
            slpApprovedBeforePurchase: slpApprovedBeforePurchase,
            hasInsuranceDoubleDip: hasInsuranceDoubleDip,
            purchaseDate: purchaseDate
        )
        return evaluate(input: input)
    }

    // MARK: Core evaluation (ordered, first decisive match wins)

    private func evaluate(category: RuleCategory, input: EligibilityInput) -> EligibilityResult {
        var reasons: [String] = []
        let matchedKeys: [String] = [category.key]
        let citations: [String] = [category.sourceCitation]

        // 1. Hard-ineligible category match.
        if category.baseEligibility == .ineligible {
            reasons.append("\(category.displayName) is not reimbursable under Florida ESA rules.")
            if let notes = category.notes { reasons.append(notes) }
            return result(status: .ineligible, reasons: reasons, matchedRuleKeys: matchedKeys, citations: citations)
        }

        // 2. Per-program exclusion (an eligible category that's blocked for this program).
        if let note = category.excludesNote(for: input.program) {
            reasons.append(note)
            return result(status: .ineligible, reasons: reasons, matchedRuleKeys: matchedKeys, citations: citations)
        }
        if !category.applies(toProgram: input.program) {
            reasons.append("\(category.displayName) does not apply to \(input.program.shortName).")
            return result(status: .ineligible, reasons: reasons, matchedRuleKeys: matchedKeys, citations: citations)
        }

        // 3. Direct-pay-only via reimbursement path.
        if category.baseEligibility == .directPayOnly && input.acquisitionPath == .reimbursement {
            reasons.append("\(category.displayName) is direct-pay only — it cannot be submitted for reimbursement.")
            if let notes = category.notes { reasons.append(notes) }
            return result(status: .directPayOnly, reasons: reasons, matchedRuleKeys: matchedKeys, citations: citations)
        }

        // 4. Device 2-year frequency rule.
        if category.requiresPreAuthIfWithinDeviceWindow == true && input.studentHasDeviceWithinWindow {
            reasons.append("This student already has a device purchased within the last \(ruleset.globalRules.deviceReplacementYears) years. The 2-year frequency rule follows the student across programs — a replacement needs pre-authorization.")
            return result(
                status: .needsPreAuth,
                reasons: reasons,
                matchedRuleKeys: matchedKeys,
                requiresPreAuth: true,
                requiresStudentName: category.requiresStudentName ?? false,
                requiresProviderCredentials: category.requiresProviderCredentials ?? false,
                requiresEducationalBenefitForm: category.requiresEducationalBenefitForm ?? false,
                requiresFloridaTeacherCertificate: category.requiresFloridaTeacherCertificate ?? false,
                requiresFloridaLicensedProvider: category.requiresFloridaLicensedProvider ?? false,
                citations: citations,
                providerCredentialOptions: category.providerCredentialOptions ?? []
            )
        }

        // 5. Peripheral over the threshold needs pre-auth.
        if let threshold = category.needsPreAuthIfPeripheralOver, input.amount > 0, input.amount > threshold {
            reasons.append("Single peripheral over \(format(threshold)) requires pre-authorization.")
            return result(
                status: .needsPreAuth,
                reasons: reasons,
                matchedRuleKeys: matchedKeys,
                requiresPreAuth: true,
                citations: citations
            )
        }

        // 6. Caps.
        if let caps = category.caps, let maxAmount = caps.maxAmount, input.amount > 0, input.amount > maxAmount {
            reasons.append("Amount \(format(input.amount)) exceeds the \(format(maxAmount)) cap for \(category.displayName).")
            if let notes = category.notes { reasons.append(notes) }
            return result(status: .ineligible, reasons: reasons, matchedRuleKeys: matchedKeys, citations: citations)
        }

        // 7. Pre-auth required for the category itself (e.g. theme parks).
        if category.requiresPreAuth == true || category.baseEligibility == .needsPreAuth {
            reasons.append("\(category.displayName) requires pre-authorization before purchase.")
            if let notes = category.notes { reasons.append(notes) }
            return result(
                status: .needsPreAuth,
                reasons: reasons,
                matchedRuleKeys: matchedKeys,
                requiresPreAuth: true,
                requiresStudentName: category.requiresStudentName ?? false,
                requiresProviderCredentials: category.requiresProviderCredentials ?? false,
                requiresEducationalBenefitForm: category.requiresEducationalBenefitForm ?? false,
                requiresFloridaTeacherCertificate: category.requiresFloridaTeacherCertificate ?? false,
                requiresFloridaLicensedProvider: category.requiresFloridaLicensedProvider ?? false,
                citations: citations,
                providerCredentialOptions: category.providerCredentialOptions ?? []
            )
        }

        // 8. Likely eligible — surface documentation requirements.
        reasons.append("\(category.displayName) is eligible for \(input.program.shortName) under the current ruleset.")
        if category.requiresStudentName == true {
            reasons.append("Make sure the receipt/invoice shows the student's name exactly as on the scholarship record.")
        }
        if category.requiresProviderCredentials == true {
            reasons.append("Include the provider's credentials (license number / certificate) and dates of service on the invoice.")
        }
        if category.requiresFloridaTeacherCertificate == true {
            reasons.append("The tutor must hold a valid Florida teaching certificate for this subject/grade level.")
        }
        if category.requiresFloridaLicensedProvider == true {
            reasons.append("Provider must be licensed by the Florida Department of Health or approved by APD/SIS. ABA specifically requires BCBA supervision (RBT under BCBA OK).")
        }
        if category.requiresEducationalBenefitForm == true {
            reasons.append("An Educational Benefit Form / statement is required.")
        }
        if let notes = category.notes {
            reasons.append(notes)
        }

        return result(
            status: .likelyEligible,
            reasons: reasons,
            matchedRuleKeys: matchedKeys,
            requiresStudentName: category.requiresStudentName ?? false,
            requiresProviderCredentials: category.requiresProviderCredentials ?? false,
            requiresEducationalBenefitForm: category.requiresEducationalBenefitForm ?? false,
            requiresFloridaTeacherCertificate: category.requiresFloridaTeacherCertificate ?? false,
            requiresFloridaLicensedProvider: category.requiresFloridaLicensedProvider ?? false,
            citations: citations,
            providerCredentialOptions: category.providerCredentialOptions ?? []
        )
    }

    // MARK: Inference

    /// Infer a category from free text. Prefers ineligible-for-this-program matches first
    /// (so PEP "Chromebook" gets caught), then longest-keyword match across remaining
    /// categories that apply to this program.
    func inferCategory(from text: String, program: Program) -> RuleCategory? {
        let lower = text.lowercased()

        // 0. Categories explicitly ineligible for this program (e.g. devices on PEP).
        for cat in ruleset.categories where cat.excludesNote(for: program) != nil {
            if matchesAnyKeyword(in: lower, keywords: cat.keywords) ||
               matchesAnyPhrase(in: lower, phrases: cat.phrasalKeywords) {
                return cat
            }
        }

        // 1. Universal ineligible categories.
        for cat in ruleset.categories where cat.baseEligibility == .ineligible {
            if matchesAnyKeyword(in: lower, keywords: cat.keywords) ||
               matchesAnyPhrase(in: lower, phrases: cat.phrasalKeywords) {
                return cat
            }
        }

        // 2. Longest-keyword-first across remaining categories that apply.
        let candidates = ruleset.categories.filter {
            $0.baseEligibility != .ineligible && $0.applies(toProgram: program)
        }
        var bestMatch: (category: RuleCategory, length: Int)? = nil
        for cat in candidates {
            for keyword in cat.keywords {
                let kw = keyword.lowercased()
                if containsWord(kw, in: lower),
                   bestMatch == nil || kw.count > bestMatch!.length {
                    bestMatch = (cat, kw.count)
                }
            }
            // Phrasal keywords match substring (no word boundary).
            for phrase in cat.phrasalKeywords ?? [] {
                let p = phrase.lowercased()
                if lower.contains(p),
                   bestMatch == nil || p.count > bestMatch!.length {
                    bestMatch = (cat, p.count)
                }
            }
        }
        return bestMatch?.category
    }

    private func scanIneligibleKeywords(in text: String, program: Program) -> RuleCategory? {
        let lower = text.lowercased()
        // Per-program ineligible exclusions get priority.
        for cat in ruleset.categories where cat.excludesNote(for: program) != nil {
            if matchesAnyKeyword(in: lower, keywords: cat.keywords) { return cat }
        }
        for cat in ruleset.categories where cat.baseEligibility == .ineligible {
            if matchesAnyKeyword(in: lower, keywords: cat.keywords) { return cat }
        }
        return nil
    }

    private func matchesAnyKeyword(in text: String, keywords: [String]) -> Bool {
        for keyword in keywords {
            if containsWord(keyword.lowercased(), in: text) { return true }
        }
        return false
    }

    private func matchesAnyPhrase(in text: String, phrases: [String]?) -> Bool {
        guard let phrases else { return false }
        for phrase in phrases {
            if text.contains(phrase.lowercased()) { return true }
        }
        return false
    }

    private func containsWord(_ keyword: String, in text: String) -> Bool {
        guard !keyword.isEmpty else { return false }
        let escaped = NSRegularExpression.escapedPattern(for: keyword)
        let pattern = "(?<![A-Za-z0-9])\(escaped)(?![A-Za-z0-9])"
        guard let regex = try? NSRegularExpression(pattern: pattern, options: [.caseInsensitive]) else {
            return text.contains(keyword)
        }
        let range = NSRange(text.startIndex..., in: text)
        return regex.firstMatch(in: text, options: [], range: range) != nil
    }

    // MARK: Result helpers

    private func result(
        status: EligibilityStatus,
        reasons: [String],
        matchedRuleKeys: [String] = [],
        requiresPreAuth: Bool = false,
        requiresStudentName: Bool = false,
        requiresProviderCredentials: Bool = false,
        requiresEducationalBenefitForm: Bool = false,
        requiresFloridaTeacherCertificate: Bool = false,
        requiresFloridaLicensedProvider: Bool = false,
        citations: [String] = [],
        providerCredentialOptions: [String] = []
    ) -> EligibilityResult {
        EligibilityResult(
            status: status,
            reasons: reasons,
            matchedRuleKeys: matchedRuleKeys,
            requiresPreAuth: requiresPreAuth,
            requiresStudentName: requiresStudentName,
            requiresProviderCredentials: requiresProviderCredentials,
            requiresEducationalBenefitForm: requiresEducationalBenefitForm,
            requiresFloridaTeacherCertificate: requiresFloridaTeacherCertificate,
            requiresFloridaLicensedProvider: requiresFloridaLicensedProvider,
            citations: citations,
            providerCredentialOptions: providerCredentialOptions
        )
    }

    private func format(_ amount: Decimal) -> String {
        amount.formatted(.currency(code: "USD"))
    }
}

/// Helper that asks: "Does this student have a device purchase within the window?"
enum DeviceWindowChecker {
    static func studentHasRecentDevice(student: Student, within years: Int, asOf: Date = .now) -> Bool {
        guard let cutoff = Calendar.current.date(byAdding: .year, value: -years, to: asOf) else { return false }
        return student.devicePurchases.contains { $0.purchaseDate >= cutoff }
    }
}
