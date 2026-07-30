import SwiftData
import SwiftUI

struct ReceiptInboxView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \ReceiptCandidate.receivedAt, order: .reverse)
    private var candidates: [ReceiptCandidate]

    @State private var google = GoogleOAuthService.shared
    @State private var isScanning = false
    @State private var statusMessage: String?
    @State private var errorMessage: String?
    @State private var selectedFilter: ReceiptCandidateStatus = .pending

    private var visibleCandidates: [ReceiptCandidate] {
        candidates.filter { $0.status == selectedFilter }
    }

    var body: some View {
        List {
            connectionSection
            Section {
                Picker("Status", selection: $selectedFilter) {
                    Text("Pending").tag(ReceiptCandidateStatus.pending)
                    Text("Imported").tag(ReceiptCandidateStatus.imported)
                    Text("Dismissed").tag(ReceiptCandidateStatus.dismissed)
                }
                .pickerStyle(.segmented)
                .listRowBackground(Color.clear)
            }

            if visibleCandidates.isEmpty {
                emptySection
            } else {
                Section(selectedFilter == .pending ? "Ready to review" : selectedFilter.rawValue.capitalized) {
                    ForEach(visibleCandidates) { candidate in
                        NavigationLink {
                            ReceiptCandidateReviewView(candidate: candidate)
                        } label: {
                            candidateRow(candidate)
                        }
                    }
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(DS.canvas)
        .navigationTitle("Receipt Inbox")
        .toolbar {
            if google.isConnected {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        Task { await scan() }
                    } label: {
                        if isScanning {
                            ProgressView()
                        } else {
                            Label("Scan Gmail", systemImage: "arrow.clockwise")
                        }
                    }
                    .disabled(isScanning)
                    .accessibilityIdentifier("scanGmailButton")
                }
            }
        }
        .alert("Gmail", isPresented: Binding(
            get: { errorMessage != nil },
            set: { if !$0 { errorMessage = nil } }
        )) {
            Button("OK", role: .cancel) { errorMessage = nil }
        } message: {
            Text(errorMessage ?? "")
        }
    }

    @ViewBuilder
    private var connectionSection: some View {
        Section {
            if google.isConnected {
                HStack(spacing: DS.md) {
                    Image(systemName: "envelope.badge.fill")
                        .font(.title3)
                        .foregroundStyle(DS.statusGood)
                        .frame(width: 36, height: 36)
                        .background(DS.statusGood.opacity(0.12), in: RoundedRectangle(cornerRadius: 10))
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Gmail connected").font(.body.weight(.semibold))
                        Text(google.connectedEmail ?? "")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                Button {
                    Task { await scan() }
                } label: {
                    Label(isScanning ? "Scanning…" : "Scan for receipts", systemImage: "magnifyingglass")
                }
                .disabled(isScanning)
                Button(role: .destructive) {
                    Task {
                        await google.disconnect()
                        statusMessage = nil
                    }
                } label: {
                    Text("Disconnect Gmail")
                }
            } else if google.isConfigured {
                VStack(alignment: .leading, spacing: DS.sm) {
                    Label("Connect Gmail", systemImage: "envelope.fill")
                        .font(.headline)
                    Text("ScholarKeep searches for likely receipts with read-only access. It cannot send, delete, archive, or change your email.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                Button {
                    Task { await connect() }
                } label: {
                    if google.isAuthorizing {
                        HStack { ProgressView(); Text("Connecting…") }
                    } else {
                        Text("Continue with Google")
                    }
                }
                .disabled(google.isAuthorizing)
                .accessibilityIdentifier("connectGmailButton")
            } else {
                VStack(alignment: .leading, spacing: DS.sm) {
                    Label("Gmail import", systemImage: "envelope")
                        .font(.headline)
                    Text("Gmail import is not configured in this build. Camera, Photos, Files, and Share remain available.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            if let statusMessage {
                Text(statusMessage)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        } header: {
            Text("Connected email")
        } footer: {
            Text("Messages are read on this device and become records only after you review them.")
        }
    }

    private var emptySection: some View {
        Section {
            VStack(spacing: DS.md) {
                Image(systemName: selectedFilter == .pending ? "tray" : "checkmark.circle")
                    .font(.system(size: 38, weight: .light))
                    .foregroundStyle(.secondary)
                Text(emptyTitle)
                    .font(.headline)
                Text(emptyDetail)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.xl)
        }
    }

    private var emptyTitle: String {
        switch selectedFilter {
        case .pending: return "No receipts waiting"
        case .imported: return "No imported email receipts"
        case .dismissed: return "No dismissed messages"
        }
    }

    private var emptyDetail: String {
        if selectedFilter == .pending, google.isConnected {
            return "Scan Gmail to look for recent receipts and invoices."
        }
        return "Items will appear here as you review your Receipt Inbox."
    }

    private func candidateRow(_ candidate: ReceiptCandidate) -> some View {
        HStack(spacing: DS.md) {
            Image(systemName: candidate.attachmentData == nil ? "envelope.fill" : "doc.text.fill")
                .foregroundStyle(DS.accent)
                .frame(width: 34, height: 34)
                .background(DS.accentSoft, in: RoundedRectangle(cornerRadius: 10))
            VStack(alignment: .leading, spacing: 3) {
                Text(candidate.suggestedVendor.isEmpty ? candidate.subject : candidate.suggestedVendor)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(candidate.subject)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text(candidate.receivedAt.formatted(date: .abbreviated, time: .omitted))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            Spacer()
            if let total = candidate.suggestedTotal {
                Text(total.formatted(.currency(code: "USD")))
                    .font(.subheadline.weight(.semibold))
                    .monospacedDigit()
            }
        }
        .padding(.vertical, 2)
    }

    private func connect() async {
        do {
            try await google.connect()
            await scan()
        } catch {
            let nsError = error as NSError
            // AuthenticationServices reports a user-cancelled browser sheet as
            // code 1. Cancellation is not a product error worth alerting.
            if nsError.code != 1 {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func scan() async {
        isScanning = true
        statusMessage = nil
        errorMessage = nil
        defer { isScanning = false }
        do {
            let result = try await GmailReceiptImportService.scan(modelContext: modelContext)
            if result.importedCount > 0 {
                statusMessage = "Found \(result.importedCount) new possible receipt\(result.importedCount == 1 ? "" : "s")."
                selectedFilter = .pending
            } else {
                statusMessage = "Scan complete. No new receipts found."
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
