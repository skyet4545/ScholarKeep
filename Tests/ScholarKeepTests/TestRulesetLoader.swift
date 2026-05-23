import Foundation
@testable import ScholarKeep

/// Shared helper for loading the bundled ruleset from the test target host.
/// Looks at the host app bundle first, then the test bundle as a fallback.
enum TestRuleset {
    static func load() throws -> Ruleset {
        if let url = Bundle.main.url(forResource: "ruleset-2026-27", withExtension: "json") {
            let data = try Data(contentsOf: url)
            return try JSONDecoder().decode(Ruleset.self, from: data)
        }
        // Walk through every bundle until we find it (handy in CI environments).
        for bundle in Bundle.allBundles {
            if let url = bundle.url(forResource: "ruleset-2026-27", withExtension: "json") {
                let data = try Data(contentsOf: url)
                return try JSONDecoder().decode(Ruleset.self, from: data)
            }
        }
        throw NSError(domain: "ScholarKeepTests", code: 404,
                      userInfo: [NSLocalizedDescriptionKey: "ruleset-2026-27.json not bundled with tests"])
    }

    static func engine() throws -> EligibilityEngine {
        EligibilityEngine(ruleset: try load())
    }
}
