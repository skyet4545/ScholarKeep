import Foundation

enum Program: String, Codable, CaseIterable, Identifiable {
    case fesUA
    case fesEO
    case pep

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .fesUA: return "FES-UA (Unique Abilities)"
        case .fesEO: return "FES-EO (Educational Options, income-based)"
        case .pep:   return "PEP (Personalized Education Program)"
        }
    }

    var shortName: String {
        switch self {
        case .fesUA: return "FES-UA"
        case .fesEO: return "FES-EO"
        case .pep:   return "PEP"
        }
    }

    /// One-line description used in onboarding to help the parent pick.
    var oneLiner: String {
        switch self {
        case .fesUA:
            return "Disability-based ESA (IEP or qualifying diagnosis). Broadest spending — includes specialized therapies."
        case .fesEO:
            return "Income-based ESA (post-HB-1 2023). Same flexible spending as PEP except students are enrolled in an approved private school."
        case .pep:
            return "ESA for K-12 students not enrolled full-time in public or private school (homeschool / personalized education)."
        }
    }
}

enum SFO: String, Codable, CaseIterable, Identifiable {
    case stepUp
    case aaa

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .stepUp: return "Step Up For Students"
        case .aaa:    return "AAA Scholarship Foundation"
        }
    }

    var portalName: String {
        switch self {
        case .stepUp: return "EMA"
        case .aaa:    return "SMP"
        }
    }
}

enum SchoolYear {
    /// Returns the school year label (e.g. "2026-27") that contains the given date,
    /// where a school year runs July 1 – June 30.
    static func label(for date: Date = Date.now, calendar: Calendar = .current) -> String {
        let components = calendar.dateComponents([.year, .month], from: date)
        guard let year = components.year, let month = components.month else { return "" }
        let startYear = month >= 7 ? year : year - 1
        let endYearTwoDigit = (startYear + 1) % 100
        return String(format: "%d-%02d", startYear, endYearTwoDigit)
    }
}
