import Foundation
import SwiftData

/// A tutor, therapist, or other credentialed service provider the parent uses.
/// Kept per-student so the parent doesn't retype credentials on every receipt
/// and so the app can surface "missing license #" warnings consistently.
@Model
final class Provider {
    var id: UUID = UUID()
    var name: String = ""
    var typeRaw: String = ProviderType.other.rawValue
    var licenseNumber: String = ""
    var licenseType: String = ""      // e.g. "BCBA", "SLP", "Florida Educator's Certificate"
    var licenseState: String = "FL"   // "FL", "TX", etc.
    var isFloridaCertifiedTeacher: Bool = false
    var deliversVirtually: Bool = false  // out-of-state OK if virtual + credentialed
    var notes: String = ""
    var createdAt: Date = Date.now
    var student: Student?
    @Relationship(deleteRule: .nullify, inverse: \Expense.provider) var expenses: [Expense] = []

    init(
        id: UUID = UUID(),
        name: String,
        type: ProviderType,
        licenseNumber: String = "",
        licenseType: String = "",
        licenseState: String = "FL",
        isFloridaCertifiedTeacher: Bool = false,
        deliversVirtually: Bool = false,
        notes: String = "",
        createdAt: Date = Date.now,
        student: Student? = nil
    ) {
        self.id = id
        self.name = name
        self.typeRaw = type.rawValue
        self.licenseNumber = licenseNumber
        self.licenseType = licenseType
        self.licenseState = licenseState
        self.isFloridaCertifiedTeacher = isFloridaCertifiedTeacher
        self.deliversVirtually = deliversVirtually
        self.notes = notes
        self.createdAt = createdAt
        self.student = student
    }

    var type: ProviderType {
        get { ProviderType(rawValue: typeRaw) ?? .other }
        set { typeRaw = newValue.rawValue }
    }
}

enum ProviderType: String, Codable, CaseIterable, Identifiable {
    case partTimeTutor
    case fullTimeTutor
    case choiceNavigator
    case abaProvider
    case speechTherapist
    case occupationalTherapist
    case physicalTherapist
    case psychotherapist
    case visionTherapist
    case musicArtTherapist
    case horseTherapyCenter
    case jobCoach
    case privateSchool
    case onlineProvider
    case publicSchoolService
    case other

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .partTimeTutor:          return "Part-time tutor"
        case .fullTimeTutor:          return "Full-time tutor (Florida certified)"
        case .choiceNavigator:        return "Choice navigator"
        case .abaProvider:            return "ABA provider (BCBA-supervised)"
        case .speechTherapist:        return "Speech-Language Pathologist"
        case .occupationalTherapist:  return "Occupational Therapist"
        case .physicalTherapist:      return "Physical Therapist"
        case .psychotherapist:        return "Psychotherapist / Counselor"
        case .visionTherapist:        return "Vision Therapist (Optometrist)"
        case .musicArtTherapist:      return "Music / Art Therapist"
        case .horseTherapyCenter:     return "Horse Therapy (PATH-certified center)"
        case .jobCoach:               return "Transition / job coach"
        case .privateSchool:          return "Private school"
        case .onlineProvider:         return "Online / virtual provider"
        case .publicSchoolService:    return "Public school contracted service"
        case .other:                  return "Other"
        }
    }

    /// Programs this provider type is typically reimbursable under.
    var typicalPrograms: [Program] {
        switch self {
        case .abaProvider, .speechTherapist, .occupationalTherapist, .physicalTherapist,
             .psychotherapist, .visionTherapist, .musicArtTherapist, .horseTherapyCenter,
             .jobCoach:
            return [.fesUA]
        case .privateSchool:
            return [.fesUA, .fesEO]
        case .fullTimeTutor:
            return [.fesUA, .pep]
        default:
            return Program.allCases
        }
    }
}
