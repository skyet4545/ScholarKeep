import SwiftUI

/// v0.5.1 — Apple Journal-inspired reusable UI components.
/// Use these throughout the app to maintain visual consistency.

// MARK: - Journal page header
/// Large editorial title with optional eyebrow/subtitle.
/// Use at the top of a screen for the "you are here" moment.
struct JournalHeader: View {
    let eyebrow: String?
    let title: String
    let subtitle: String?

    init(eyebrow: String? = nil, title: String, subtitle: String? = nil) {
        self.eyebrow = eyebrow
        self.title = title
        self.subtitle = subtitle
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            if let eyebrow {
                Text(eyebrow)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            Text(title)
                .journalTitle()
            if let subtitle {
                Text(subtitle)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .padding(.top, 2)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, DS.lg)
        .padding(.top, DS.sm)
        .padding(.bottom, DS.md)
    }
}

// MARK: - Journal section
/// Section header (small caps style) above a grouped card.
struct JournalSection<Content: View>: View {
    let title: String?
    let action: (label: String, handler: () -> Void)?
    @ViewBuilder let content: () -> Content

    init(_ title: String? = nil,
         action: (label: String, handler: () -> Void)? = nil,
         @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.action = action
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.sm) {
            if title != nil || action != nil {
                HStack {
                    if let title {
                        Text(title)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .textCase(.uppercase)
                            .tracking(0.5)
                    }
                    Spacer()
                    if let action {
                        Button(action.label, action: action.handler)
                            .font(.footnote.weight(.semibold))
                            .foregroundStyle(DS.accent)
                    }
                }
                .padding(.horizontal, DS.lg + 4)
            }
            VStack(spacing: 0) { content() }
                .background(DS.grouped, in: RoundedRectangle(cornerRadius: DS.cardRadius))
                .shadow(color: Color.black.opacity(0.04), radius: 12, x: 0, y: 4)
                .padding(.horizontal, DS.lg)
        }
    }
}

// MARK: - Journal row
/// Single tappable row inside a JournalSection. Use Divider between rows.
struct JournalRow: View {
    let symbol: String?
    let symbolTint: Color
    let title: String
    let subtitle: String?
    let trailing: String?
    let trailingTint: Color?
    let showChevron: Bool
    let onTap: (() -> Void)?

    init(symbol: String? = nil,
         symbolTint: Color = DS.accent,
         title: String,
         subtitle: String? = nil,
         trailing: String? = nil,
         trailingTint: Color? = nil,
         showChevron: Bool = false,
         onTap: (() -> Void)? = nil) {
        self.symbol = symbol
        self.symbolTint = symbolTint
        self.title = title
        self.subtitle = subtitle
        self.trailing = trailing
        self.trailingTint = trailingTint
        self.showChevron = showChevron
        self.onTap = onTap
    }

    @ViewBuilder
    var body: some View {
        if let onTap {
            Button(action: onTap) { rowContent }.buttonStyle(.plain)
        } else {
            rowContent
        }
    }

    private var rowContent: some View {
        HStack(spacing: DS.md) {
            if let symbol {
                Image(systemName: symbol)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(symbolTint)
                    .frame(width: 32, height: 32)
                    .background(symbolTint.opacity(0.14), in: RoundedRectangle(cornerRadius: 10))
            }
            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.subheadline)
                    .foregroundStyle(.primary)
                if let subtitle {
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            if let trailing {
                Text(trailing)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(trailingTint ?? .secondary)
                    .monospacedDigit()
            }
            if showChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.horizontal, DS.base)
        .padding(.vertical, DS.md)
    }
}

// MARK: - Journal empty state
/// Beautiful empty state: big symbol, conversational copy, single CTA.
/// Use everywhere instead of "No items."
struct JournalEmpty: View {
    let symbol: String
    let title: String
    let copy: String
    let cta: (label: String, handler: () -> Void)?

    init(symbol: String, title: String, body: String,
         cta: (label: String, handler: () -> Void)? = nil) {
        self.symbol = symbol
        self.title = title
        self.copy = body
        self.cta = cta
    }

    var body: some View {
        VStack(spacing: DS.lg) {
            Image(systemName: symbol)
                .font(.system(size: 56, weight: .light))
                .foregroundStyle(DS.accent.opacity(0.45))
                .padding(.bottom, DS.xs)
            VStack(spacing: DS.sm) {
                Text(title)
                    .font(.title3.weight(.semibold))
                    .multilineTextAlignment(.center)
                Text(copy)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.xl)
            }
            if let cta {
                Button(cta.label, action: cta.handler)
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(DS.accent)
                    .padding(.top, DS.sm)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, DS.xxxl)
        .padding(.horizontal, DS.lg)
    }
}

// MARK: - Journal chip / pill
struct JournalChip: View {
    enum Style { case accent, neutral, good, warn, bad }
    let text: String
    let style: Style
    let symbol: String?

    init(_ text: String, style: Style = .neutral, symbol: String? = nil) {
        self.text = text
        self.style = style
        self.symbol = symbol
    }

    private var fg: Color {
        switch style {
        case .accent: return DS.accent
        case .neutral: return .secondary
        case .good: return DS.statusGood
        case .warn: return DS.statusWarn
        case .bad: return DS.statusBad
        }
    }
    private var bg: Color {
        switch style {
        case .accent: return DS.accent.opacity(0.14)
        case .neutral: return DS.subtle
        case .good: return DS.statusGood.opacity(0.14)
        case .warn: return DS.statusWarn.opacity(0.14)
        case .bad: return DS.statusBad.opacity(0.14)
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            if let symbol {
                Image(systemName: symbol).font(.caption2.weight(.semibold))
            }
            Text(text).font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .foregroundStyle(fg)
        .background(bg, in: Capsule())
    }
}

// MARK: - Journal primary CTA
/// Full-width prominent button styled per the design system.
struct JournalCTA: View {
    let label: String
    let symbol: String?
    let isDisabled: Bool
    let action: () -> Void

    init(_ label: String, symbol: String? = nil, isDisabled: Bool = false, action: @escaping () -> Void) {
        self.label = label
        self.symbol = symbol
        self.isDisabled = isDisabled
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                if let symbol {
                    Image(systemName: symbol).font(.subheadline.weight(.semibold))
                }
                Text(label)
                    .font(.body.weight(.semibold))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(DS.accent, in: RoundedRectangle(cornerRadius: DS.buttonRadius))
            .foregroundStyle(.white)
            .opacity(isDisabled ? 0.35 : 1)
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
    }
}

// MARK: - Journal hero / data card
/// Apple Journal-style "moment" card with optional eyebrow + giant title.
struct JournalHeroCard<Content: View>: View {
    let eyebrow: String?
    let title: String
    @ViewBuilder let content: () -> Content

    init(eyebrow: String? = nil, title: String, @ViewBuilder content: @escaping () -> Content) {
        self.eyebrow = eyebrow
        self.title = title
        self.content = content
    }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.sm) {
            if let eyebrow {
                Text(eyebrow)
                    .font(.footnote.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            Text(title)
                .font(.system(size: 44, weight: .bold))
                .monospacedDigit()
                .foregroundStyle(.primary)
                .padding(.top, 2)
            content()
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.xl)
        .background(DS.grouped, in: RoundedRectangle(cornerRadius: DS.cardRadius))
        .shadow(color: Color.black.opacity(0.05), radius: 16, x: 0, y: 6)
        .padding(.horizontal, DS.lg)
    }
}

// MARK: - Divider with proper left inset for rows with leading icons
extension View {
    func journalRowDivider() -> some View {
        self.overlay(alignment: .bottom) {
            Divider().padding(.leading, 56)
        }
    }
}
