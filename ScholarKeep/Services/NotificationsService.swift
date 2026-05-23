import Foundation
import UserNotifications

/// Schedules local reminders for the submission deadline, on-hold clocks, and
/// device-window openings. No remote push — all reminders are local-only.
enum NotificationsService {

    enum Category: String {
        case submissionDeadline
        case onHoldClock
        case deviceWindow
    }

    static func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        case .authorized, .provisional, .ephemeral:
            return true
        case .denied:
            return false
        @unknown default:
            return false
        }
    }

    static func scheduleSubmissionDeadline(school year: String, daysBefore: [Int] = [30, 7, 1]) async {
        guard await requestAuthorizationIfNeeded() else { return }
        let center = UNUserNotificationCenter.current()
        // July 31 of the second year of the school-year label (e.g. "2026-27" → 2027-07-31).
        guard let deadline = submissionDeadlineDate(for: year) else { return }
        await removeIdentifiers(prefix: "deadline-\(year)")
        for days in daysBefore {
            guard let fireDate = Calendar.current.date(byAdding: .day, value: -days, to: deadline) else { continue }
            if fireDate < .now { continue }
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate),
                repeats: false
            )
            let content = UNMutableNotificationContent()
            content.title = "Reimbursement deadline in \(days) day\(days == 1 ? "" : "s")"
            content.body = "Submit \(year) ESA reimbursements by July 31."
            content.sound = .default
            content.categoryIdentifier = Category.submissionDeadline.rawValue
            let request = UNNotificationRequest(identifier: "deadline-\(year)-\(days)", content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    static func scheduleOnHoldClock(for claim: Claim, days: Int = 30) async {
        guard await requestAuthorizationIfNeeded() else { return }
        guard let onHoldStart = claim.onHoldStartedAt,
              let due = Calendar.current.date(byAdding: .day, value: days, to: onHoldStart),
              due > .now else { return }
        await removeIdentifiers(prefix: "onhold-\(claim.id.uuidString)")
        let center = UNUserNotificationCenter.current()
        let fires: [(Int, Date)] = [
            (days - 7, Calendar.current.date(byAdding: .day, value: -7, to: due) ?? due),
            (days - 1, Calendar.current.date(byAdding: .day, value: -1, to: due) ?? due)
        ]
        for (label, fireDate) in fires where fireDate > .now {
            let trigger = UNCalendarNotificationTrigger(
                dateMatching: Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate),
                repeats: false
            )
            let content = UNMutableNotificationContent()
            content.title = "On-hold clock: \(label) day(s) left"
            content.body = "Provide the missing docs for \"\(claim.title)\" or it may be denied."
            content.sound = .default
            content.categoryIdentifier = Category.onHoldClock.rawValue
            let request = UNNotificationRequest(identifier: "onhold-\(claim.id.uuidString)-\(label)", content: content, trigger: trigger)
            try? await center.add(request)
        }
    }

    static func scheduleDeviceWindowReminder(student: Student, lastDevice: DevicePurchase, years: Int) async {
        guard await requestAuthorizationIfNeeded() else { return }
        let due = lastDevice.nextEligibleDate(years: years)
        guard due > .now else { return }
        await removeIdentifiers(prefix: "device-\(student.id.uuidString)")
        let trigger = UNCalendarNotificationTrigger(
            dateMatching: Calendar.current.dateComponents([.year, .month, .day], from: due),
            repeats: false
        )
        let content = UNMutableNotificationContent()
        content.title = "\(student.displayName): device window opens"
        content.body = "It's been \(years) years since the last device purchase. You can buy a replacement without pre-authorization."
        content.sound = .default
        content.categoryIdentifier = Category.deviceWindow.rawValue
        let request = UNNotificationRequest(identifier: "device-\(student.id.uuidString)-\(lastDevice.id.uuidString)", content: content, trigger: trigger)
        try? await UNUserNotificationCenter.current().add(request)
    }

    static func cancelAll() async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        center.removeAllDeliveredNotifications()
    }

    // MARK: helpers

    private static func submissionDeadlineDate(for schoolYear: String) -> Date? {
        // Expect labels like "2026-27"
        let parts = schoolYear.split(separator: "-")
        guard parts.count == 2, let startYear = Int(parts[0]) else { return nil }
        let endYear = startYear + 1
        var components = DateComponents()
        components.year = endYear
        components.month = 7
        components.day = 31
        components.hour = 9
        return Calendar.current.date(from: components)
    }

    private static func removeIdentifiers(prefix: String) async {
        let center = UNUserNotificationCenter.current()
        let pending = await center.pendingNotificationRequests()
        let toRemove = pending.map(\.identifier).filter { $0.hasPrefix(prefix) }
        center.removePendingNotificationRequests(withIdentifiers: toRemove)
    }
}
