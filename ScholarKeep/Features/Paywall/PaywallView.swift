import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var subs = SubscriptionService.shared
    @State private var purchasing: Product? = nil
    @State private var errorMessage: String?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    header
                    benefitsList
                    productCards
                    restoreRow
                    footnote
                }
                .padding(20)
            }
            .navigationTitle("ScholarKeep Pro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Not now") { dismiss() }
                }
            }
            .task {
                await subs.loadProducts()
                await subs.refreshEntitlements()
            }
        }
    }

    private var header: some View {
        VStack(spacing: 12) {
            Image(systemName: "graduationcap.fill")
                .font(.system(size: 56))
                .foregroundStyle(.tint)
            Text("Make every reimbursement count")
                .font(.title2.bold())
                .multilineTextAlignment(.center)
            Text("Pro unlocks the tools that get your claims approved on the first try.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var benefitsList: some View {
        VStack(alignment: .leading, spacing: 14) {
            benefit("Submission-package PDFs",
                    "Per-expense + per-claim, paginated, with the documentation checklist baked in.",
                    "doc.text.fill")
            benefit("CSV export for taxes and records",
                    "Every expense, every refund, every status — exportable for your year-end records.",
                    "tablecells.fill")
            benefit("iCloud backup",
                    "Your data follows you across iPhone and iPad. Off by default, on with one tap.",
                    "icloud.fill")
            benefit("Year-end summary report",
                    "Full breakdown by program, category, and claim status — ready before the July 31 deadline.",
                    "chart.line.uptrend.xyaxis")
        }
    }

    private func benefit(_ title: String, _ subtitle: String, _ icon: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(.tint)
                .font(.title3)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.subheadline.weight(.semibold))
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var productCards: some View {
        VStack(spacing: 12) {
            if subs.products.isEmpty {
                ProgressView("Loading subscription options…")
                    .padding(.vertical, 30)
            } else {
                ForEach(subs.products, id: \.id) { product in
                    productCard(product)
                }
            }
            if let errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
        }
    }

    private func productCard(_ product: Product) -> some View {
        let isYearly = product.id.contains("yearly")
        return Button {
            buy(product)
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(product.displayName)
                        .font(.headline)
                    Spacer()
                    if isYearly {
                        Text("SAVE 33%")
                            .font(.caption2.bold())
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(Color.accentColor, in: Capsule())
                            .foregroundStyle(.white)
                    }
                }
                Text(product.displayPrice + (isYearly ? " / year" : " / month"))
                    .font(.title3.bold().monospacedDigit())
                if let intro = product.subscription?.introductoryOffer, intro.paymentMode == .freeTrial {
                    Text("7-day free trial")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Text(product.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.accentColor.opacity(isYearly ? 0.12 : 0.06), in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(isYearly ? Color.accentColor : Color.secondary.opacity(0.2),
                            lineWidth: isYearly ? 2 : 1)
            }
        }
        .buttonStyle(.plain)
        .disabled(purchasing != nil)
        .overlay {
            if purchasing?.id == product.id {
                ProgressView()
            }
        }
    }

    private var restoreRow: some View {
        VStack(spacing: 8) {
            Button("Restore purchases") {
                Task {
                    await subs.restorePurchases()
                    if subs.isPro {
                        dismiss()
                    } else {
                        errorMessage = "No active subscription found on this Apple ID."
                    }
                }
            }
            .font(.subheadline)
            if subs.isPro {
                Label("Pro is active", systemImage: "checkmark.seal.fill")
                    .foregroundStyle(.green)
                    .font(.caption.weight(.semibold))
            }
        }
    }

    private var footnote: some View {
        VStack(spacing: 6) {
            Text("Family Sharing is enabled — up to 6 family members share one Pro subscription.")
            Text("Subscriptions auto-renew until cancelled. Cancel any time in Settings → Apple ID → Subscriptions.")
        }
        .font(.caption2)
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .padding(.top, 8)
    }

    private func buy(_ product: Product) {
        purchasing = product
        errorMessage = nil
        Task {
            defer { purchasing = nil }
            do {
                try await subs.purchase(product)
                if subs.isPro { dismiss() }
            } catch SubscriptionPurchaseError.userCancelled {
                // silent
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

/// View modifier: shows the paywall when triggered by `isPresented`.
struct PaywallSheet: ViewModifier {
    @Binding var isPresented: Bool

    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented) {
            PaywallView()
        }
    }
}

extension View {
    func paywallSheet(isPresented: Binding<Bool>) -> some View {
        modifier(PaywallSheet(isPresented: isPresented))
    }
}
