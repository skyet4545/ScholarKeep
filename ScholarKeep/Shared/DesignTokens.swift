import SwiftUI

/// Design tokens for v0.5.0 — Jony Ive-inspired restraint with a single warm
/// signature color. Use these throughout the app rather than ad-hoc values
/// so the system stays consistent.
enum DS {

    // MARK: Color

    /// The single signature accent color — desaturated clay.
    /// Defined in `AccentColor.colorset` so SwiftUI's `.tint(.accentColor)`
    /// and system-default tinting both pick it up automatically.
    static let accent = Color.accentColor

    /// Soft accent for fills behind icons / capsule chips.
    static var accentSoft: Color { Color.accentColor.opacity(0.12) }

    /// Warm canvas — slightly off-white in light, near-black in dark.
    /// Use as scene backdrop only; cards sit on top.
    static let canvas = Color(light: Color(red: 0.972, green: 0.957, blue: 0.941),
                              dark: Color(red: 0.055, green: 0.055, blue: 0.059))

    /// Grouped row / card background.
    static let grouped = Color(light: .white,
                               dark: Color(red: 0.110, green: 0.110, blue: 0.118))

    /// Subtle fill (chips, dividers, code).
    static let subtle = Color(light: Color(red: 0.937, green: 0.925, blue: 0.902),
                              dark: Color(red: 0.165, green: 0.165, blue: 0.173))

    /// Status — sage-y green (not slime).
    static let statusGood = Color(light: Color(red: 0.247, green: 0.557, blue: 0.361),
                                  dark: Color(red: 0.373, green: 0.714, blue: 0.490))
    /// Status — muted amber.
    static let statusWarn = Color(light: Color(red: 0.769, green: 0.525, blue: 0.165),
                                  dark: Color(red: 0.878, green: 0.651, blue: 0.365))
    /// Status — muted clay-red.
    static let statusBad  = Color(light: Color(red: 0.710, green: 0.227, blue: 0.180),
                                  dark: Color(red: 0.878, green: 0.451, blue: 0.396))

    // MARK: Spacing (4-pt grid)

    static let xs: CGFloat = 4
    static let sm: CGFloat = 8
    static let md: CGFloat = 12
    static let base: CGFloat = 16
    static let lg: CGFloat = 20
    static let xl: CGFloat = 24
    static let xxl: CGFloat = 32
    static let xxxl: CGFloat = 48

    // MARK: Shape

    /// Single corner radius for every card. Resist using more than one.
    static let cardRadius: CGFloat = 16
    /// Button radius.
    static let buttonRadius: CGFloat = 14
}

// MARK: - Conveniences

extension Color {
    /// Make a light/dark adaptive color from two `Color`s.
    init(light: Color, dark: Color) {
        self.init(uiColor: UIColor { trait in
            trait.userInterfaceStyle == .dark
                ? UIColor(dark)
                : UIColor(light)
        })
    }
}

extension View {
    /// Apply the canvas background that the v0.5.0 design system expects.
    func dsCanvas() -> some View {
        self.background(DS.canvas.ignoresSafeArea())
    }

    /// Wrap content in a v0.5.0 card: white-on-canvas, single radius, no shadow.
    func dsCard(padding: CGFloat = DS.lg) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.grouped, in: RoundedRectangle(cornerRadius: DS.cardRadius))
    }
}

// MARK: - Reusable status badge

struct DSStatusBadge: View {
    enum Kind { case good, warn, bad, info }
    let kind: Kind
    let symbol: String
    let text: String

    private var color: Color {
        switch kind {
        case .good: return DS.statusGood
        case .warn: return DS.statusWarn
        case .bad:  return DS.statusBad
        case .info: return DS.accent
        }
    }

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: symbol)
                .font(.caption.weight(.semibold))
            Text(text)
                .font(.caption.weight(.semibold))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .foregroundStyle(color)
        .background(color.opacity(0.14), in: Capsule())
    }
}
