import Foundation

/// Grants free Pro for life to TestFlight beta testers who installed before
/// the public App Store launch. The promise in monetization-strategy.md is
/// "Lifetime Pro free for beta testers" — this is how we honor it without
/// requiring accounts, a server, or any cross-device coordination.
///
/// How it works:
/// - On first launch, we record `firstLaunchDate` to UserDefaults.
/// - When the App Store goes live, we set `publicLaunchDate` here (compile-time).
/// - If the user's `firstLaunchDate` is BEFORE `publicLaunchDate`, they're a
///   beta founder forever, even on re-installs IF they're still on the same
///   Apple ID (iCloud-synced UserDefaults via NSUbiquitousKeyValueStore would
///   make this device-loss-proof; for now, local UserDefaults is enough since
///   we'll cross-check via `originalAppVersion` from StoreKit later).
enum BetaEntitlement {

    private static let firstLaunchKey = "scholarkeep.firstLaunchDate"

    /// The date the App Store version goes live. Set this once before public
    /// launch. All users whose first launch is before this date get Lifetime Pro.
    /// nil = we haven't launched publicly yet, so EVERYONE counts as beta.
    static let publicLaunchDate: Date? = nil  // TODO: set this once App Store goes live

    /// Stamp the first launch date if missing. Call once from ScholarKeepApp.init.
    static func recordFirstLaunchIfNeeded() {
        let defaults = UserDefaults.standard
        if defaults.object(forKey: firstLaunchKey) == nil {
            defaults.set(Date.now, forKey: firstLaunchKey)
        }
    }

    /// First time this device installed the app.
    static var firstLaunchDate: Date? {
        UserDefaults.standard.object(forKey: firstLaunchKey) as? Date
    }

    /// True if the user installed before the public launch — Pro for life.
    static var isActive: Bool {
        guard let first = firstLaunchDate else { return true }  // never launched? treat as beta
        guard let launch = publicLaunchDate else { return true }  // still pre-launch
        return first < launch
    }
}
