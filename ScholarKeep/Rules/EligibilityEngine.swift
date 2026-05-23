import Foundation

/// Input for an eligibility evaluation.
struct EligibilityInput: Equatable {
    var categoryKey: String?
    var descriptionText: String
    var amount: Decimal
    var program: Program
    var acquisitionPath: AcquisitionPath
    var studentHasDeviceWithinWindow: Bool = false
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
    var citations: [String]
}

/// Pure, testable eligibility engine. All rule data comes from a `Ruleset`.
struct EligibilityEngine {
    let ruleset: Ruleset

    init(ruleset: Ruleset) {
        self.ruleset = ruleset
    }

    // MARK: Public entry points

    /// Evaluate a structured input (post-category-assignment).
    func evaluate(input: EligibilityInput) -> EligibilityResult {
        // 1. Try the explicit category first if provided, else infer from description.
        var category: RuleCategory? = nil
        if let key = input.categoryKey {
            category = ruleset.categories.first { $0.key == key }
        }
        if category == nil {
            category = inferCategory(from: input.descriptionText)
        }

        // 1a. Free-text-only ineligible keyword scan — wins over an unmatched lookup.
        if let hardIneligible = scanIneligibleKeywords(in: input.descriptionText), category?.baseEligibility != .ineligible {
            return EligibilityResult(
                status: .ineligible,
                reasons: ["Matches an ineligible item: \(hardIneligible.displayName).",
                          hardIneligible.notes].compactMap { $0 },
                matchedRuleKeys: [hardIneligible.key],
                requiresPreAuth: false,
                requiresStudentName: false,
                requiresProviderCredentials: false,
                requiresEducationalBenefitForm: false,
                citations: [hardIneligible.sourceCitation]
            )
        }

        guard let category else {
            return EligibilityResult(
                status: .unknown,
                reasons: ["No matching rule. Confirm against the official Purchasing Guide before buying or submitting."],
                matchedRuleKeys: [],
                requiresPreAuth: false,
                requiresStudentName: false,
                requiresProviderCredentials: false,
                requiresEducationalBenefitForm: false,
                citations: []
            )
        }

        return evaluate(category: category, input: input)
    }

    /// Free-text "Can I buy this?" entry point — no category selected.
    func evaluateFreeText(_ text: String, amount: Decimal, program: Program,
                          acquisitionPath: AcquisitionPath = .reimbursement,
                          studentHasDeviceWithinWindow: Bool = false) -> EligibilityResult {
        let inferred = inferCategory(from: text)
        let input = EligibilityInput(
            categoryKey: inferred?.key,
            descriptionText: text,
            amount: amount,
            program: program,
            acquisitionPath: acquisitionPath,
            studentHasDeviceWithinWindow: studentHasDeviceWithinWindow
        )
        return evaluate(input: input)
    }

    // MARK: Core evaluation (ordered)

    private func evaluate(category: RuleCategory, input: EligibilityInput) -> EligibilityResult {
        var reasons: [String] = []
        let matchedKeys: [String] = [category.key]
        let citations: [String] = [category.sourceCitation]

        // 1. Hard-ineligible category match → Ineligible immediately.
        if category.baseEligibility == .ineligible {
            reasons.append("\(category.displayName) is not reimbursable under Florida ESA rules.")
            if let notes = category.notes { reasons.append(notes) }
            return EligibilityResult(
                status: .ineligible,
                reasons: reasons,
                matchedRuleKeys: matchedKeys,
                requiresPreAuth: false,
                requiresStudentName: false,
                requiresProviderCredentials: false,
                requiresEducationalBenefitForm: false,
                citations: citations
            )
        }

        // 2. Program-specific exclusion.
        if let note = category.excludesNote(for: input.program) {
            reasons.append(note)
            return EligibilityResult(
                status: .ineligible,
                reasons: reasons,
                matchedRuleKeys: matchedKeys,
                requiresPreAuth: false,
                requiresStudentName: false,
                requiresProviderCredentials: false,
                requiresEducationalBenefitForm: false,
                citations: citations
            )
        }
        if !category.applies(toProgram: input.program) {
            reasons.append("\(category.displayName) does not apply to \(input.program.shortName).")
            return EligibilityResult(
                status: .ineligible,
                reasons: reasons,
                matchedRuleKeys: matchedKeys,
                requiresPreAuth: false,
                requiresStudentName: false,
                requiresProviderCredentials: false,
                requiresEducationalBenefitForm: false,
                citations: citations
            )
        }

        // 3. Direct-pay-only category and parent is requesting reimbursement.
        if category.baseEligibility == .directPayOnly && input.acquisitionPath == .reimbursement {
            reasons.append("\(category.displayName) is direct-pay only — it cannot be submitted for reimbursement.")
            if let notes = category.notes { reasons.append(notes) }
            return EligibilityResult(
                status: .directPayOnly,
                reasons: reasons,
                matchedRuleKeys: matchedKeys,
                requiresPreAuth: false,
                requiresStudentName: false,
                requiresProviderCredentials: false,
                requiresEducationalBenefitForm: false,
                citations: citations
            )
        }

        // 4. Device 2-year rule.
        if category.requiresPreAuthIfWithinDeviceWindow == true && input.studentHasDeviceWithinWindow {
            reasons.append("This student already has a device purchased within the last \(ruleset.globalRules.deviceReplacementYears) years. A replacement requires pre-authorization.")
            return EligibilityResult(
                status: .needsPreAuth,
                reasons: reasons,
                matchedRuleKeys: matchedKeys,
                requiresPreAuth: true,
                requiresStudentName: category.requiresStudentName ?? false,
                requiresProviderCredentials: category.requiresProviderCredentials ?? false,
                requiresEducationalBenefitForm: category.requiresEducationalBenefitForm ?? false,
                citations: citations
            )
        }

        // 5. Cap checks.
        if let caps = category.caps, let max = caps.maxAmount, input.amount > 0, input.amount > max {
            reasons.append("Amount \(format(input.amount)) exceeds the \(format(max)) cap for \(category.displayName).")
            return EligibilityResult(
                status: .ineligible,
                reasons: reasons,
                matchedRuleKeys: matchedKeys,
                requiresPreAuth: false,
                requiresStudentName: category.requiresStudentName ?? false,
                requiresProviderCredentials: category.requiresProviderCredentials ?? false,
                requiresEducationalBenefitForm: category.requiresEducationalBenefitForm ?? false,
                citations: citations
            )
        }

        // 6. Pre-auth required for the category itself (e.g. theme parks).
        if category.requiresPreAuth == true || category.baseEligibility == .needsPreAuth {
            reasons.append("\(category.displayName) requires pre-authorization before purchase.")
            if category.requiresEducationalBenefitForm == true {
                reasons.append("An Educational Benefit Form is required.")
            }
            return EligibilityResult(
                status: .needsPreAuth,
                reasons: reasons,
                matchedRuleKeys: matchedKeys,
                requiresPreAuth: true,
                requiresStudentName: category.requiresStudentName ?? false,
                requiresProviderCredentials: category.requiresProviderCredentials ?? false,
                requiresEducationalBenefitForm: category.requiresEducationalBenefitForm ?? false,
                citations: citations
            )
        }

        // 7. Likely eligible — surface documentation requirements.
        reasons.append("\(category.displayName) is eligible for \(input.program.shortName) under the current ruleset.")
        if category.requiresStudentName == true {
            reasons.append("Make sure the receipt shows the student's name exactly as on the scholarship record.")
        }
        if category.requiresProviderCredentials == true {
            reasons.append("Include the provider's license number and dates of service.")
        }
        if category.requiresEducationalBenefitForm == true {
            reasons.append("An Educational Benefit Form is required.")
        }
        return EligibilityResult(
            status: .likelyEligible,
            reasons: reasons,
            matchedRuleKeys: matchedKeys,
            requiresPreAuth: false,
            requiresStudentName: category.requiresStudentName ?? false,
            requiresProviderCredentials: category.requiresProviderCredentials ?? false,
            requiresEducationalBenefitForm: category.requiresEducationalBenefitForm ?? false,
            citations: citations
        )
    }

    // MARK: Inference

    /// Infer a category from free text. Prefers ineligible-category matches first
    /// to ensure clear-cut "gas" or "lunch" type purchases get flagged. Matches on
    /// whole-word boundaries so "chromebook" doesn't trigger the "book" keyword.
    func inferCategory(from text: String) -> RuleCategory? {
        let lower = text.lowercased()
        // First pass: ineligible categories (decisive).
        for cat in ruleset.categories where cat.baseEligibility == .ineligible {
            if matchesAnyKeyword(in: lower, keywords: cat.keywords) {
                return cat
            }
        }
        // Second pass: longest-keyword-first across remaining categories, so "chromebook"
        // (length 9) wins over "book" (length 4).
        let candidates = ruleset.categories.filter { $0.baseEligibility != .ineligible }
        var bestMatch: (category: RuleCategory, length: Int)? = nil
        for cat in candidates {
            for keyword in cat.keywords {
                let kw = keyword.lowercased()
                if containsWord(kw, in: lower) {
                    if bestMatch == nil || kw.count > bestMatch!.length {
                        bestMatch = (cat, kw.count)
                    }
                }
            }
        }
        return bestMatch?.category
    }

    /// Scan for an ineligible-category keyword anywhere in the text (whole-word match).
    private func scanIneligibleKeywords(in text: String) -> RuleCategory? {
        let lower = text.lowercased()
        for cat in ruleset.categories where cat.baseEligibility == .ineligible {
            if matchesAnyKeyword(in: lower, keywords: cat.keywords) {
                return cat
            }
        }
        return nil
    }

    private func matchesAnyKeyword(in text: String, keywords: [String]) -> Bool {
        for keyword in keywords {
            if containsWord(keyword.lowercased(), in: text) { return true }
        }
        return false
    }

    /// Whole-word containment that tolerates multi-word keywords like "ap exam".
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

    // MARK: Helpers

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
