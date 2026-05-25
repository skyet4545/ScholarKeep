# ScholarKeep Design System (v0.5.0)

_Apple-native Clinical bones + Clay/Terracotta accent._

Goal: feel like a first-party Apple records app, but with a warm signature color that immediately tells you "this isn't another corporate fintech app." Single accent. Restrained type. Generous whitespace. SF everything.

## 1. Color

### Accent
Used for primary CTAs, active states, links, the hero status pill, progress fills, and the app icon tint.

| Token | Light | Dark |
|---|---|---|
| `accent` | `#B85C3A` (terracotta) | `#D17354` (terracotta+10%) |
| `accent-soft` | `#B85C3A` @ 12% alpha | `#D17354` @ 18% alpha |
| `accent-hover` | `#A14F30` | `#DD8266` |

### Neutrals
Pull from Apple system colors so dark mode comes free. Backgrounds favor *warm* gray over pure cool gray.

| Token | Light | Dark | Use |
|---|---|---|---|
| `bg-canvas` | `#F7F4F0` (warm off-white) | `#0E0E0F` | App background |
| `bg-grouped` | `#FFFFFF` | `#1C1C1E` | Card / grouped row background |
| `bg-subtle` | `#EFECE6` | `#1C1C1E` | Subtle fill (chips, dividers, code) |
| `text-primary` | `#0A0A0A` | `#F2F2F2` | Headlines + body |
| `text-secondary` | `#6B6760` | `#9A958A` | Captions + secondary labels |
| `text-tertiary` | `#9A958A` | `#6F6A60` | Meta labels (timestamps, etc.) |
| `divider` | `#0A0A0A` @ 6% | `#FFF` @ 8% | Hairline dividers |

### Status
Only used for eligibility verdicts and claim status. **Not** decorative.

| Token | Hex | Use |
|---|---|---|
| `status-good` | `#3F8E5C` | Eligible / paid / approved |
| `status-warn` | `#C4862A` | Needs pre-auth / on-hold |
| `status-bad` | `#B53A2E` | Ineligible / rejected |
| `status-info` | accent (terracotta) | Likely-eligible / pending |

## 2. Typography

SF Pro across the board. **No custom fonts.** Apple-default for free polish.

| Token | Size / Weight | Use |
|---|---|---|
| `hero` | 34pt / Bold / -0.4 tracking | Onboarding screen titles, balance hero |
| `title-1` | 28pt / Bold | Section titles in detail screens |
| `title-2` | 22pt / Semibold | Card hero text |
| `title-3` | 17pt / Semibold | Inline emphasis, group headers |
| `body` | 17pt / Regular | Default body |
| `callout` | 16pt / Regular | Form labels |
| `subhead` | 15pt / Regular | Secondary body |
| `footnote` | 13pt / Regular | Captions, helper text |
| `caption-1` | 12pt / Semibold | Eyebrows / metadata labels |
| `caption-2` | 11pt / Regular | Timestamps, IDs |

### Hierarchy rule
Each card has **exactly one** `title-2` or `hero`. No competing headlines.

## 3. Spacing

4-point grid. Use these tokens; do not invent values.

```
xs   = 4
sm   = 8
md   = 12
base = 16
lg   = 20
xl   = 24
2xl  = 32
3xl  = 48
```

**Card padding:** `lg` (20pt) by default, `xl` (24pt) for hero cards.
**Card spacing in stack:** `md` (12pt).
**Section spacing on dashboard:** `2xl` (32pt).
**Tap target minimum:** 44pt.

## 4. Shape

**One** corner radius for cards: **`16pt`**. Pills are capsule. Buttons inherit card radius. Resist the urge to use multiple radii.

**Shadows:** Skip them. The warm canvas bg + white grouped bg gives enough card separation. Drop shadows are the #1 amateur tell.

## 5. Iconography

SF Symbols only. **Weight: medium.** Never mix weights in the same screen. Tint primary icons with `accent`; status icons take their status color.

Common mappings:
- Receipt → `doc.text.viewfinder`
- Eligibility chat → `bubble.left.and.bubble.right.fill`
- Claims → `tray.and.arrow.up.fill`
- Privacy/lock → `lock.shield.fill`
- Recurring → `arrow.triangle.2.circlepath`
- Settings → `gearshape.fill`

## 6. Components

### `Card`
- 16pt radius, `bg-grouped`, 20pt padding, no shadow.
- One `title-2` max.
- Use `divider` (1pt hairline) between rows inside a card.

### `HeroCard` (dashboard active-student card)
- 24pt padding, `bg-grouped`.
- Eyebrow (`caption-1`, tertiary), hero number, progress bar (terracotta fill on `accent-soft` track), three pills below.

### `StatusBadge`
Capsule, 4×10pt padding, status color @ 14% alpha bg, status color text, leading SF Symbol.

### `ActionRow` (list row)
Leading icon (28pt circle with `accent-soft` fill, accent symbol inside) → title (`body`) + subtitle (`footnote` secondary) → trailing chevron.

### `PrimaryButton`
Filled `accent`, 14pt radius, 14pt vertical padding, `body` semibold. Disabled = 30% alpha.

### `SecondaryButton`
Text-only, `accent` color, no background, `body` semibold.

### `EmptyState`
SF Symbol (48pt, tertiary) → `title-2` headline → `subhead` body → `PrimaryButton`. Always offers a single next action — never just "No items."

## 7. Motion

- 200ms ease-out on tap reactions
- 280ms spring on card insertion/dismissal
- Animated number tickers when balances change (don't snap)
- No bouncing, no parallax, no decorative motion

## 8. Anti-patterns (don't do)

- Multiple accent colors in one screen
- Drop shadows
- More than 2 weights of SF Pro on one screen
- Decorative color (rainbow categories)
- Custom fonts in v1
- Pure black backgrounds (`#000`) — use `#0E0E0F`
- Pure white backgrounds in light mode — use `#F7F4F0` for canvas
- Empty states that just say "No items"
- Mixing corner radii on cards
