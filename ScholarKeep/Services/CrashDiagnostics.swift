import Foundation
import MetricKit

/// Subscribes to MetricKit (Apple-first-party, no third-party SDK) and writes any
/// received crash/diagnostic payloads to the app container under Application Support/.
/// User can attach or share these from Settings → Diagnostics in a future update.
final class CrashDiagnostics: NSObject, MXMetricManagerSubscriber {
    static let shared = CrashDiagnostics()

    override init() {
        super.init()
        MXMetricManager.shared.add(self)
    }

    func didReceive(_ payloads: [MXMetricPayload]) {
        for (i, payload) in payloads.enumerated() {
            write(data: payload.jsonRepresentation(), prefix: "metric", index: i)
        }
    }

    func didReceive(_ payloads: [MXDiagnosticPayload]) {
        for (i, payload) in payloads.enumerated() {
            write(data: payload.jsonRepresentation(), prefix: "diagnostic", index: i)
        }
    }

    private func write(data: Data, prefix: String, index: Int) {
        guard let dir = logsDirectory() else { return }
        let stamp = ISO8601DateFormatter().string(from: .now).replacingOccurrences(of: ":", with: "-")
        let url = dir.appendingPathComponent("\(prefix)-\(stamp)-\(index).json")
        try? data.write(to: url)
    }

    private func logsDirectory() -> URL? {
        guard let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else { return nil }
        let dir = base.appendingPathComponent("ScholarKeepDiagnostics", isDirectory: true)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
}
