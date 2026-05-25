# ScholarKeep Visual Direction Research

_Generated 2026-05-24 as input to the v0.5.0 redesign._

## What we learned from each cluster

**Personal finance (Copilot, Monarch, Rocket, YNAB)** — The polished apps in this category (Copilot especially, an Apple Design Award finalist) share a recipe: ex-Apple designers, native iOS feel, generous whitespace, *animated* data viz where motion is informational not decorative, and a single confident accent that adapts to context. Monarch's recent refresh moved toward "warmth and approachability" — softened blues, mauve accents — explicitly because too-clinical fintech reads cold. Rocket and YNAB skew busier/spreadsheet-y, which is exactly what amateur apps look like: too many colored chips per row, no breathing room, every row screaming for attention.

**Apple-native (Wallet, Health, Fitness, Reminders, Journal)** — Heavy use of SF Pro + SF Symbols, large rounded "tile" cards on neutral backgrounds, content-first layouts where chrome disappears. Health's Favorites tab moved to small square tiles in iOS 17 to surface more at once without scroll. Apple Journal is almost defiantly minimal — typography + a single hero entry per scroll position — leaning into the "sacred private space" feel.

**Records/journaling (Day One, Bear, Things 3, Notion)** — These win on *typography as identity*. Day One licensed Hoefler faces plus Apple's New York. Bear shipped a custom typeface in 2.0 and obsesses over vertical rhythm. Things 3 increased corner radii and loosened spacing in its 2023 refresh specifically because tighter felt dated. The premium signal here is *restraint*: one accent color, serif or refined sans for body, lots of whitespace, no shadows competing with the type.

**Onboarding gold standards (Headspace, Duolingo, Calm)** — Warm illustration palettes (corals, sage, soft blues, no pure black/white), rounded character forms, one idea per screen, persona-based branching.

**What makes apps look amateur, concretely**: too many accent colors competing, drop shadows on everything, inconsistent corner radii across cards, system-default text styles only, icons of mismatched weight/scale, dense list rows with no whitespace, empty states that just say "No items," and decorative color (rainbow categories) instead of meaningful color.

## Three visual directions

### Direction 1 — "Apple-native Clinical"
**Summary.** Treat ScholarKeep like a first-party Apple records app — SF Pro throughout, SF Symbols, large rounded tiles on grouped neutral backgrounds, one system-tinted accent.
**Signature traits.** Bold section headers, secondary labels in tertiary gray, plenty of inset card padding, no custom illustration, status conveyed via tinted SF Symbols + small colored dots.
**Exemplar.** Apple Wallet + Apple Health Favorites tab.
**Feel.** Utility-grade, official, "the IRS would approve."

### Direction 2 — "Copilot Warm-Premium" ⭐ recommended
**Summary.** Best-in-class polished fintech with one warm signature color (clay, terracotta, sage, or muted gold — not blue) carrying through dials, progress bars, and CTA. Heavier on micro-animations and meaningful data viz.
**Signature traits.** Generous whitespace, custom-tuned type scale (SF Pro Display for hero numbers, SF Pro Text for body), animated counters when receipts/dollars update, color-coded category chips used sparingly, distinctive empty-state illustrations.
**Exemplar.** Copilot Money, post-refresh Monarch.
**Feel.** Premium, considered, "someone designs this app full-time."

### Direction 3 — "Day One Editorial"
**Summary.** Typography-led, almost paper-like — treats each child's records as a personal archive worth preserving. Mixes a refined serif for titles with SF Pro for UI chrome, on warm off-white / deep ink backgrounds.
**Signature traits.** Restrained accent (sepia, ink-blue, or olive), single hero entry per screen position, dates and locations rendered with editorial care, generous line-height, soft cream rather than pure white, document thumbnails framed like photos.
**Exemplar.** Day One + Bear + Apple Journal.
**Feel.** Heirloom, private, "this matters to my family."

## Recommendation

**Lead with Direction 2 (Copilot Warm-Premium), borrowing typography discipline from Direction 3.**

The audience is homeschool / special-ed parents — overwhelmed, often skeptical of digital tools handling sensitive kid records, and aesthetically attuned (overlaps with Instagram-curated home decor, planner culture, Notion-template buyers). Direction 1 reads too IRS-bureaucratic for an emotionally-loaded category. Direction 3 risks looking like a journaling app and undersells the finance utility ESA paperwork demands.

Direction 2 splits the difference: warm signature color signals "made with care" (counters amateur perception immediately), Copilot-grade information density signals competence with money/receipts, and pulling Day One's typographic restraint into headers and entry titles signals "your records are treated with dignity." It also gives the privacy moat a visual hook — a warm, calm, *personal* color (not stock fintech green or bank blue) reinforces "this lives on your device, not in some corporation's cloud."

Tactically: pick one warm signature color, commit to SF Pro across the board (skip custom fonts in v1), invest disproportionately in the home dashboard hero moment and the empty states, and standardize one corner radius + one shadow recipe across every card.
