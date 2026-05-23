import Foundation
import SwiftData

@Model
final class StatusEvent {
    @Attribute(.unique) var id: UUID
    var statusRaw: String
    var date: Date
    var note: String
    var claim: Claim?

    init(
        id: UUID = UUID(),
        status: ClaimStatus,
        date: Date = .now,
        note: String = "",
        claim: Claim? = nil
    ) {
        self.id = id
        self.statusRaw = status.rawValue
        self.date = date
        self.note = note
        self.claim = claim
    }

    var status: ClaimStatus {
        get { ClaimStatus(rawValue: statusRaw) ?? .draft }
        set { statusRaw = newValue.rawValue }
    }
}
