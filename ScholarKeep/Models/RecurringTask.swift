import Foundation
import SwiftData

enum RecurringSchedule: String, Codable, CaseIterable, Identifiable {
    case daily
    case weekly
    case monthly
    case quarterly
    case annually
    case oneTime

    var id: String { rawValue }
    var displayName: String {
        switch self {
        case .daily:     return "Daily"
        case .weekly:    return "Weekly"
        case .monthly:   return "Monthly"
        case .quarterly: return "Quarterly"
        case .annually:  return "Annually"
        case .oneTime:   return "One-time"
        }
    }

    /// Advances `from` by one schedule period.
    func next(from: Date) -> Date? {
        let cal = Calendar.current
        switch self {
        case .daily:     return cal.date(byAdding: .day, value: 1, to: from)
        case .weekly:    return cal.date(byAdding: .day, value: 7, to: from)
        case .monthly:   return cal.date(byAdding: .month, value: 1, to: from)
        case .quarterly: return cal.date(byAdding: .month, value: 3, to: from)
        case .annually:  return cal.date(byAdding: .year, value: 1, to: from)
        case .oneTime:   return nil
        }
    }
}

/// Suggested templates the user picks from when adding a new task.
enum RecurringTaskTemplate: String, CaseIterable, Identifiable {
    case annualEvaluation
    case quarterlyReceipts
    case scholarshipRenewal
    case slpRenewal
    case yearEndExport
    case backToSchoolReview
    case fpeaEvent
    case custom

    var id: String { rawValue }

    var title: String {
        switch self {
        case .annualEvaluation:    return "Annual evaluation by certified teacher"
        case .quarterlyReceipts:   return "Bundle quarterly receipts for submission"
        case .scholarshipRenewal:  return "Renew scholarship application"
        case .slpRenewal:          return "Update Student Learning Plan (PEP)"
        case .yearEndExport:       return "Export year-end CSV + PDF records"
        case .backToSchoolReview:  return "Back-to-school: review last year's denials"
        case .fpeaEvent:           return "FPEA convention prep"
        case .custom:              return "Custom task"
        }
    }

    var defaultSchedule: RecurringSchedule {
        switch self {
        case .annualEvaluation, .scholarshipRenewal, .slpRenewal,
             .yearEndExport, .backToSchoolReview, .fpeaEvent:
            return .annually
        case .quarterlyReceipts:
            return .quarterly
        case .custom:
            return .monthly
        }
    }

    var iconName: String {
        switch self {
        case .annualEvaluation:    return "graduationcap"
        case .quarterlyReceipts:   return "tray.and.arrow.up"
        case .scholarshipRenewal:  return "doc.text.fill"
        case .slpRenewal:          return "doc.badge.gearshape"
        case .yearEndExport:       return "square.and.arrow.up.on.square"
        case .backToSchoolReview:  return "magnifyingglass"
        case .fpeaEvent:           return "calendar.badge.exclamationmark"
        case .custom:              return "star"
        }
    }
}

/// A recurring obligation parents have to remember (annual evaluations,
/// quarterly receipt bundling, renewals, etc.). Schedules a local notification
/// for the next due date.
@Model
final class RecurringTask {
    @Attribute(.unique) var id: UUID
    var title: String
    var notes: String
    var scheduleRaw: String
    var nextDueDate: Date
    var lastCompletedDate: Date?
    var isArchived: Bool
    var createdAt: Date
    var student: Student?

    init(
        id: UUID = UUID(),
        title: String,
        notes: String = "",
        schedule: RecurringSchedule,
        nextDueDate: Date,
        lastCompletedDate: Date? = nil,
        isArchived: Bool = false,
        createdAt: Date = .now,
        student: Student? = nil
    ) {
        self.id = id
        self.title = title
        self.notes = notes
        self.scheduleRaw = schedule.rawValue
        self.nextDueDate = nextDueDate
        self.lastCompletedDate = lastCompletedDate
        self.isArchived = isArchived
        self.createdAt = createdAt
        self.student = student
    }

    var schedule: RecurringSchedule {
        get { RecurringSchedule(rawValue: scheduleRaw) ?? .monthly }
        set { scheduleRaw = newValue.rawValue }
    }

    /// True when the task is overdue (past nextDueDate AND not archived).
    var isOverdue: Bool {
        !isArchived && nextDueDate < .now
    }

    /// Marks the task complete and advances nextDueDate by one schedule period.
    /// For one-time tasks, archives instead.
    func markComplete(asOf date: Date = .now) {
        lastCompletedDate = date
        if let next = schedule.next(from: nextDueDate) {
            nextDueDate = next
        } else {
            isArchived = true
        }
    }
}
