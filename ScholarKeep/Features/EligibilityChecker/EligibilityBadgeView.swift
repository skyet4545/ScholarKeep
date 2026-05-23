import SwiftUI

struct EligibilityBadgeView: View {
    let result: EligibilityResult

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: result.status.systemImageName)
                    .foregroundStyle(tint)
                Text(result.status.displayName)
                    .font(.headline)
                    .foregroundStyle(tint)
                Spacer()
            }
            ForEach(result.reasons, id: \.self) { reason in
                Text(reason)
                    .font(.footnote)
                    .foregroundStyle(.primary)
            }
            if !result.citations.isEmpty {
                Text(result.citations.joined(separator: " · "))
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(tint.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
    }

    private var tint: Color {
        switch result.status {
        case .eligible, .likelyEligible: return .green
        case .needsPreAuth, .directPayOnly: return .orange
        case .ineligible, .likelyIneligible: return .red
        case .unknown: return .gray
        }
    }
}

struct EligibilityChip: View {
    let status: EligibilityStatus

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: status.systemImageName)
            Text(status.displayName)
        }
        .font(.caption.weight(.semibold))
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(tint.opacity(0.18), in: Capsule())
        .foregroundStyle(tint)
    }

    private var tint: Color {
        switch status {
        case .eligible, .likelyEligible: return .green
        case .needsPreAuth, .directPayOnly: return .orange
        case .ineligible, .likelyIneligible: return .red
        case .unknown: return .gray
        }
    }
}
