import Foundation
import StoreKit
import Observation

enum ProProductID: String, CaseIterable {
    case monthly = "com.carlosreyes.scholarkeep.pro.monthly"
    case yearly  = "com.carlosreyes.scholarkeep.pro.yearly"
}

enum SubscriptionPurchaseError: Error, LocalizedError {
    case productNotFound
    case userCancelled
    case pending
    case failed(String)
    case verificationFailed

    var errorDescription: String? {
        switch self {
        case .productNotFound:    return "That product isn't available in the App Store right now."
        case .userCancelled:      return nil
        case .pending:            return "Purchase is pending parental approval / additional verification."
        case .failed(let msg):    return msg
        case .verificationFailed: return "We couldn't verify the purchase with Apple. Try Restore Purchases."
        }
    }
}

/// Source of truth for subscription state. Observes StoreKit 2 transactions and
/// publishes `isPro` so feature gates can react.
@Observable
final class SubscriptionService {
    static let shared = SubscriptionService()

    private(set) var products: [Product] = []
    private(set) var isPro: Bool = false
    private(set) var lastChecked: Date?

    private var transactionListener: Task<Void, Never>?

    private init() {
        transactionListener = listenForTransactions()
        Task { await loadProducts() }
        Task { await refreshEntitlements() }
    }

    deinit {
        transactionListener?.cancel()
    }

    // MARK: Product catalog

    @MainActor
    func loadProducts() async {
        do {
            let storeProducts = try await Product.products(for: ProProductID.allCases.map(\.rawValue))
            // Sort: monthly first, then yearly.
            self.products = storeProducts.sorted { lhs, rhs in
                if lhs.id.contains("monthly") && rhs.id.contains("yearly") { return true }
                return false
            }
        } catch {
            // Leave products empty — the paywall will show an error state.
            self.products = []
        }
    }

    // MARK: Purchase

    @MainActor
    func purchase(_ product: Product) async throws {
        let result = try await product.purchase()
        switch result {
        case .success(let verification):
            switch verification {
            case .verified(let transaction):
                await transaction.finish()
                await refreshEntitlements()
            case .unverified:
                throw SubscriptionPurchaseError.verificationFailed
            }
        case .userCancelled:
            throw SubscriptionPurchaseError.userCancelled
        case .pending:
            throw SubscriptionPurchaseError.pending
        @unknown default:
            throw SubscriptionPurchaseError.failed("Unknown StoreKit result.")
        }
    }

    @MainActor
    func restorePurchases() async {
        try? await AppStore.sync()
        await refreshEntitlements()
    }

    // MARK: Entitlement check

    /// Re-evaluates `isPro` by walking `Transaction.currentEntitlements`.
    @MainActor
    func refreshEntitlements() async {
        var hasPro = false
        for await result in Transaction.currentEntitlements {
            if case .verified(let transaction) = result,
               ProProductID.allCases.map(\.rawValue).contains(transaction.productID) {
                if transaction.revocationDate == nil {
                    hasPro = true
                    break
                }
            }
        }
        self.isPro = hasPro
        self.lastChecked = .now
    }

    // MARK: Background transaction stream

    private func listenForTransactions() -> Task<Void, Never> {
        Task.detached(priority: .background) { [weak self] in
            for await result in Transaction.updates {
                if case .verified(let transaction) = result {
                    await transaction.finish()
                    await MainActor.run {
                        Task { await self?.refreshEntitlements() }
                    }
                }
            }
        }
    }
}
