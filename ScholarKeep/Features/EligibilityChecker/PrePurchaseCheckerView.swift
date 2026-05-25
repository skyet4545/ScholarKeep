import SwiftUI
import SwiftData

/// Chat-style "Can I buy this?" — one message per query, each verdict cites
/// the Purchasing Guide passage from the deterministic ruleset.
struct PrePurchaseCheckerView: View {
    @Environment(AppSettings.self) private var settings
    @Query(sort: \Student.createdAt) private var students: [Student]

    @State private var messages: [ChatMessage] = []
    @State private var input: String = ""
    @State private var amountInput: String = ""
    @State private var path: AcquisitionPath = .reimbursement
    @State private var studentID: UUID?

    var body: some View {
        NavigationStack {
            ZStack {
                DS.canvas.ignoresSafeArea()
                VStack(spacing: 0) {
                    contextStrip
                    if messages.isEmpty {
                        emptyState
                    } else {
                        ScrollViewReader { proxy in
                            ScrollView {
                                LazyVStack(alignment: .leading, spacing: 12) {
                                    ForEach(messages) { message in
                                        ChatBubble(message: message)
                                            .id(message.id)
                                    }
                                }
                                .padding(16)
                            }
                            .onChange(of: messages.count) { _, _ in
                                if let last = messages.last {
                                    withAnimation(.easeOut) {
                                        proxy.scrollTo(last.id, anchor: .bottom)
                                    }
                                }
                            }
                        }
                    }
                    inputBar
                }
            }
            .navigationTitle("Can I buy this?")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !messages.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Clear") {
                            messages.removeAll()
                        }
                        .font(.body.weight(.semibold))
                        .foregroundStyle(DS.accent)
                    }
                }
            }
            .onAppear {
                if studentID == nil { studentID = settings.activeStudentID ?? students.first?.id }
            }
        }
    }

    // MARK: Sections

    private var contextStrip: some View {
        HStack(spacing: 8) {
            Menu {
                ForEach(students) { s in
                    Button {
                        studentID = s.id
                    } label: {
                        HStack {
                            Text("\(s.displayName) — \(s.program.shortName)")
                            if studentID == s.id { Image(systemName: "checkmark") }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "person.crop.circle")
                        .font(.caption)
                    Text(activeStudent?.displayName ?? "Choose student")
                        .font(.caption.weight(.semibold))
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.accentColor.opacity(0.15), in: Capsule())
                .foregroundStyle(Color.accentColor)
            }
            Menu {
                ForEach(AcquisitionPath.allCases) { p in
                    Button {
                        path = p
                    } label: {
                        HStack {
                            Text(p.displayName)
                            if path == p { Image(systemName: "checkmark") }
                        }
                    }
                }
            } label: {
                HStack(spacing: 4) {
                    Text(path.shortName)
                        .font(.caption.weight(.semibold))
                    Image(systemName: "chevron.down")
                        .font(.caption2)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(Color.secondary.opacity(0.15), in: Capsule())
            }
            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 4)
    }

    private var emptyState: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Image(systemName: "bubble.left.and.bubble.right.fill")
                        .font(.title)
                        .foregroundStyle(.tint)
                    Text("Type any purchase. I'll tell you if it's reimbursable, what documentation you'll need, and quote the Purchasing Guide.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Text("Try one of these")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                ForEach(suggestedPrompts, id: \.self) { prompt in
                    Button {
                        input = prompt
                        send()
                    } label: {
                        HStack {
                            Text(prompt)
                                .font(.subheadline)
                                .multilineTextAlignment(.leading)
                            Spacer()
                            Image(systemName: "arrow.up.right")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding(12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.secondary.opacity(0.08), in: RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(16)
        }
    }

    private var inputBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 10) {
                HStack(spacing: 4) {
                    Image(systemName: "dollarsign")
                        .foregroundStyle(.secondary)
                    TextField("Amount", text: $amountInput)
                        .keyboardType(.decimalPad)
                        .frame(width: 70)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(Color.secondary.opacity(0.1), in: Capsule())

                HStack {
                    TextField("Describe what you're buying", text: $input, axis: .vertical)
                        .lineLimit(1...3)
                        .submitLabel(.send)
                        .onSubmit { send() }
                    if !input.isEmpty {
                        Button {
                            send()
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.title2)
                                .foregroundStyle(.tint)
                        }
                        .accessibilityIdentifier("sendChat")
                        .accessibilityLabel("Send")
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.secondary.opacity(0.1), in: Capsule())
            }
            .padding(12)
        }
    }

    // MARK: Send

    private var activeStudent: Student? {
        guard let id = studentID else { return students.first }
        return students.first { $0.id == id }
    }

    private let suggestedPrompts: [String] = [
        "Chromebook for math lessons",
        "ABA therapy session with BCBA",
        "Magic Kingdom annual pass",
        "Co-op tuition $400",
        "Online Coursera class",
        "Gas to drive to tutoring",
        "Private school tuition"
    ]

    private func send() {
        let text = input.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, let student = activeStudent else { return }
        guard let engine = RulesetLoader.shared.engine else { return }

        let amount = DecimalParsing.parse(amountInput) ?? 0
        let withinWindow = DeviceWindowChecker.studentHasRecentDevice(
            student: student,
            within: engine.ruleset.globalRules.deviceReplacementYears
        )
        let result = engine.evaluateFreeText(text,
                                             amount: amount,
                                             program: student.program,
                                             acquisitionPath: path,
                                             studentHasDeviceWithinWindow: withinWindow,
                                             slpApprovedBeforePurchase: student.slpApprovedBefore(.now))

        let userMessage = ChatMessage(
            role: .user,
            text: text + (amount > 0 ? " (\(amount.formatted(.currency(code: "USD"))))" : ""),
            timestamp: .now
        )
        let botMessage = ChatMessage(
            role: .bot(result),
            text: "",
            studentLabel: "\(student.displayName) · \(student.program.shortName)",
            timestamp: .now
        )

        messages.append(userMessage)
        messages.append(botMessage)
        input = ""
        amountInput = ""
    }
}

// MARK: Chat data

struct ChatMessage: Identifiable {
    let id = UUID()
    enum Role {
        case user
        case bot(EligibilityResult)
    }
    let role: Role
    let text: String
    var studentLabel: String? = nil
    let timestamp: Date
}

private struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        switch message.role {
        case .user:
            HStack {
                Spacer(minLength: 40)
                Text(message.text)
                    .padding(12)
                    .background(Color.accentColor, in: RoundedRectangle(cornerRadius: 16))
                    .foregroundStyle(.white)
                    .frame(maxWidth: 280, alignment: .trailing)
            }
        case .bot(let result):
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: result.status.systemImageName)
                    .foregroundStyle(tint(for: result.status))
                    .padding(6)
                    .background(tint(for: result.status).opacity(0.15), in: Circle())
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Text(result.status.displayName)
                            .font(.subheadline.weight(.bold))
                            .foregroundStyle(tint(for: result.status))
                        if let label = message.studentLabel {
                            Text("· \(label)")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                    }
                    ForEach(result.reasons, id: \.self) { reason in
                        Text(reason)
                            .font(.subheadline)
                            .foregroundStyle(.primary)
                    }
                    if !result.citations.isEmpty {
                        VStack(alignment: .leading, spacing: 2) {
                            ForEach(result.citations, id: \.self) { c in
                                Text("📖  \(c)")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.top, 4)
                    }
                    if !result.providerCredentialOptions.isEmpty {
                        DisclosureGroup("Provider credentials required") {
                            VStack(alignment: .leading, spacing: 2) {
                                ForEach(result.providerCredentialOptions, id: \.self) { c in
                                    Text("• \(c)")
                                        .font(.caption)
                                }
                            }
                        }
                        .font(.caption.weight(.semibold))
                        .padding(.top, 4)
                    }
                }
                .padding(12)
                .background(tint(for: result.status).opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
                .frame(maxWidth: 320, alignment: .leading)
                Spacer(minLength: 40)
            }
        }
    }

    private func tint(for status: EligibilityStatus) -> Color {
        switch status {
        case .eligible, .likelyEligible: return .green
        case .needsPreAuth, .directPayOnly: return .orange
        case .ineligible, .likelyIneligible: return .red
        case .unknown: return .gray
        }
    }
}
