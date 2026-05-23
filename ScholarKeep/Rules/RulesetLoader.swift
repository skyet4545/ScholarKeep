import Foundation
import Observation

/// Loads the bundled ruleset JSON and exposes a configured engine.
/// Supports an optional remote refresh from a public URL so we can push new
/// rules between app releases without users having to download an update.
@Observable
final class RulesetLoader {
    static let shared = RulesetLoader()

    private(set) var ruleset: Ruleset?
    private(set) var engine: EligibilityEngine?
    private(set) var loadError: Error?
    private(set) var lastRefreshAt: Date?
    private(set) var lastRefreshSource: Source = .bundle

    enum Source: String {
        case bundle = "Bundled"
        case cache = "Cached download"
        case remote = "Remote refresh"
    }

    /// Public URL we fetch the latest ruleset JSON from. Hosting plan: drop a
    /// `ruleset-latest.json` file in the same GitHub Pages repo as the LEGAL/
    /// docs and point this URL at it. App falls back to the bundled file when
    /// the network is unavailable or the response is malformed.
    static let remoteURL = URL(string: "https://skyet4545.github.io/ScholarKeep/ruleset-latest.json")!

    private let cacheFileName = "ruleset-cache.json"

    private init() {
        loadBest()
    }

    // MARK: Load order: cache → bundle (then attempt remote refresh in background)

    func loadBest() {
        if let cached = loadFromCache() {
            apply(cached, source: .cache)
            return
        }
        if let bundled = loadFromBundle() {
            apply(bundled, source: .bundle)
        }
    }

    /// Re-runs `loadBest()` (called from Settings when the user taps Reload).
    func reload() {
        loadBest()
    }

    /// Attempts to fetch the latest ruleset from `remoteURL`. On success, updates
    /// the in-memory engine and writes the new JSON to the cache file. On failure,
    /// leaves the existing ruleset in place.
    @discardableResult
    func fetchRemote() async -> Bool {
        var request = URLRequest(url: Self.remoteURL)
        request.cachePolicy = .reloadIgnoringLocalCacheData
        request.timeoutInterval = 15
        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let http = response as? HTTPURLResponse, 200..<300 ~= http.statusCode else {
                return false
            }
            let decoded = try JSONDecoder().decode(Ruleset.self, from: data)
            try writeCache(data: data)
            await MainActor.run {
                self.apply(decoded, source: .remote)
            }
            return true
        } catch {
            return false
        }
    }

    // MARK: Helpers

    private func apply(_ ruleset: Ruleset, source: Source) {
        self.ruleset = ruleset
        self.engine = EligibilityEngine(ruleset: ruleset)
        self.lastRefreshAt = .now
        self.lastRefreshSource = source
        self.loadError = nil
    }

    private func loadFromBundle() -> Ruleset? {
        guard let url = Bundle.main.url(forResource: "ruleset-2026-27", withExtension: "json") else {
            loadError = NSError(domain: "ScholarKeep", code: 404,
                                userInfo: [NSLocalizedDescriptionKey: "ruleset JSON not found in bundle"])
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(Ruleset.self, from: data)
        } catch {
            loadError = error
            return nil
        }
    }

    private func loadFromCache() -> Ruleset? {
        guard let url = cacheURL(), FileManager.default.fileExists(atPath: url.path) else {
            return nil
        }
        do {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(Ruleset.self, from: data)
        } catch {
            // Bad cache → wipe it so we don't keep hitting the error.
            try? FileManager.default.removeItem(at: url)
            return nil
        }
    }

    private func writeCache(data: Data) throws {
        guard let url = cacheURL() else { return }
        try data.write(to: url, options: .atomic)
    }

    private func cacheURL() -> URL? {
        guard let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let dir = base.appendingPathComponent("ScholarKeep", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent(cacheFileName)
    }

    var schoolYearLabel: String {
        ruleset?.schoolYear ?? SchoolYear.label()
    }

    /// Removes the cached download so the next launch falls back to bundled.
    func clearCache() {
        if let url = cacheURL() {
            try? FileManager.default.removeItem(at: url)
        }
        loadBest()
    }
}
