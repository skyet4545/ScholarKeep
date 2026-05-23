import Foundation
import SwiftUI

@Observable
final class AppSettings {
    static let shared = AppSettings()

    private enum Keys {
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let appLockEnabled = "appLockEnabled"
        static let iCloudBackupEnabled = "iCloudBackupEnabled"
        static let activeStudentID = "activeStudentID"
    }

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.hasCompletedOnboarding = defaults.bool(forKey: Keys.hasCompletedOnboarding)
        self.appLockEnabled = defaults.bool(forKey: Keys.appLockEnabled)
        self.iCloudBackupEnabled = defaults.bool(forKey: Keys.iCloudBackupEnabled)
        if let raw = defaults.string(forKey: Keys.activeStudentID), let uuid = UUID(uuidString: raw) {
            self.activeStudentID = uuid
        } else {
            self.activeStudentID = nil
        }
    }

    var hasCompletedOnboarding: Bool {
        didSet { defaults.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding) }
    }

    var appLockEnabled: Bool {
        didSet { defaults.set(appLockEnabled, forKey: Keys.appLockEnabled) }
    }

    var iCloudBackupEnabled: Bool {
        didSet { defaults.set(iCloudBackupEnabled, forKey: Keys.iCloudBackupEnabled) }
    }

    var activeStudentID: UUID? {
        didSet {
            if let id = activeStudentID {
                defaults.set(id.uuidString, forKey: Keys.activeStudentID)
            } else {
                defaults.removeObject(forKey: Keys.activeStudentID)
            }
        }
    }
}
