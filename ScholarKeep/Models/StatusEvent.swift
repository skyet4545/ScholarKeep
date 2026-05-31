import Foundation
import SwiftData

@Model
final class StatusEvent {
    var id: UUID = UUID()
    var statusRaw: String = ClaimStatus.draft.rawValue
    var date: Date = Date.now
    var note: String = ""
    var claim: Claim?

    init(
        id: UUID = UUID(),
        status: ClaimStatus,
        date: Date = Date.now,
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
