import Foundation

/// Loads the bundled ruleset JSON and exposes a configured engine.
/// Future hook: swap with a remote-fetched ruleset by overriding the source URL.
final class RulesetLoader {
    static let shared = RulesetLoader()

    private(set) var ruleset: Ruleset?
    private(set) var engine: EligibilityEngine?
    private(set) var loadError: Error?

    private init() {
        reload()
    }

    func reload() {
        guard let url = Bundle.main.url(forResource: "ruleset-2026-27", withExtension: "json") else {
            loadError = NSError(domain: "ScholarKeep", code: 404,
                                userInfo: [NSLocalizedDescriptionKey: "ruleset JSON not found in bundle"])
            return
        }
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let decoded = try decoder.decode(Ruleset.self, from: data)
            self.ruleset = decoded
            self.engine = EligibilityEngine(ruleset: decoded)
            self.loadError = nil
        } catch {
            self.loadError = error
        }
    }

    var schoolYearLabel: String {
        ruleset?.schoolYear ?? SchoolYear.label()
    }
}
