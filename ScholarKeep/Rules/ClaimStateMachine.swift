import Foundation

/// Pure validator for ClaimStatus transitions. UI calls `transition` and shows
/// an error if the new state isn't allowed (or if readiness gating blocks it).
enum ClaimStateMachine {
    enum TransitionError: Error, LocalizedError, Equatable {
        case notAllowed(from: ClaimStatus, to: ClaimStatus)
        case checklistIncomplete

        var errorDescription: String? {
            switch self {
            case .notAllowed(let from, let to):
                return "Can't move from \(from.displayName) to \(to.displayName)."
            case .checklistIncomplete:
                return "Complete the documentation checklist on every expense before marking the claim Ready to Submit."
            }
        }
    }

    /// Allowed transitions per §9.
    static func canTransition(from current: ClaimStatus, to next: ClaimStatus) -> Bool {
        if current == next { return false }
        if next == .draft { return true }   // any state → draft (parent edits)

        switch (current, next) {
        case (.draft, .readyToSubmit),
             (.readyToSubmit, .submitted),
             (.submitted, .pendingReview),
             (.submitted, .onHold),
             (.pendingReview, .approved),
             (.pendingReview, .onHold),
             (.onHold, .submitted),
             (.onHold, .denied),
             (.approved, .paidReimbursed),
             (.approved, .denied),
             (.denied, .readyToSubmit),
             (.denied, .submitted):
            return true
        default:
            return false
        }
    }

    /// Transition a claim, enforcing readiness gating where required.
    @discardableResult
    static func transition(_ claim: Claim, to next: ClaimStatus, note: String = "", date: Date = .now) throws -> StatusEvent {
        guard canTransition(from: claim.status, to: next) else {
            throw TransitionError.notAllowed(from: claim.status, to: next)
        }
        if next == .readyToSubmit {
            for expense in claim.expenses where !expense.isFullyReadyForSubmit {
                throw TransitionError.checklistIncomplete
            }
        }
        claim.status = next

        // Side effects per state.
        switch next {
        case .submitted:
            if claim.submittedDate == nil { claim.submittedDate = date }
            claim.onHoldStartedAt = nil
        case .onHold:
            claim.onHoldStartedAt = date
        case .approved:
            claim.decisionDate = date
            claim.onHoldStartedAt = nil
        case .paidReimbursed:
            claim.paidDate = date
        case .denied:
            claim.decisionDate = date
            claim.onHoldStartedAt = nil
        default:
            break
        }

        let event = StatusEvent(status: next, date: date, note: note, claim: claim)
        claim.statusEvents.append(event)
        return event
    }

    /// Allowed next states for the current status.
    static func allowedNextStates(from current: ClaimStatus) -> [ClaimStatus] {
        ClaimStatus.allCases.filter { canTransition(from: current, to: $0) }
    }
}
