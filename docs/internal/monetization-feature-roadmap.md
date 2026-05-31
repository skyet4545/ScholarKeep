# What the App Needs to Support the Monetization Strategy

_Maps each phase of monetization-strategy.md to concrete app features. Ordered by dependency — earlier items block later ones._

## What we already have (don't rebuild)

Verified shipped through v0.6.3:

- ✅ StoreKit 2 subscription IAPs configured ($4.99/mo, $39.99/yr) with 7-day intro offer
- ✅ Pro feature gates on PDF submission packages, CSV exports, iCloud backup toggle (preference only), year-end summary, Family Sharing
- ✅ PaywallView with the new design system
- ✅ Settings → "Manage subscription" link to Apple's subscription manager
- ✅ Account deletion (Apple Guideline 5.1.1(v))
- ✅ Privacy manifest
- ✅ In-app feedback shortcut (Settings → Send feedback to Carlos)
- ✅ "Not affiliated" disclaimer
- ✅ Honest "iCloud sync coming in v0.7" copy (replaces the lying toggle)
- ✅ Receipt scanning (single + multi via VisionKit)
- ✅ Eligibility checker (chat + post-scan verdict)
- ✅ Claim lifecycle
- ✅ Share Extension for email receipts

## Critical-path features (ship BEFORE charging)

### 🔴 1. Real CloudKit sync — the trust-or-die feature
**Why it matters:** A paid user whose data vanishes when her phone dies is catastrophic. One viral FB post about losing a year of receipts kills the app.

**What we ship:**
- SwiftData configured with `ModelConfiguration(cloudKitDatabase: .private(...))`
- Background sync on launch + scenePhase active
- Conflict resolution (last-write-wins is fine for single-user, single-device-at-a-time)
- Sync status visible in Settings: "Last synced 3 min ago"
- Honest "iCloud backup ON" toggle that actually works (replace the placeholder)
- Sign in with Apple becomes ACTUALLY required at this moment (opt-in from Settings)

**Effort:** 3-5 days. Risk: SwiftData CloudKit has quirks (every relationship must be optional, no unique constraints CloudKit can't enforce, schema migrations are tricky).

**Blocker:** Nothing. This is the next big build.

---

### 🔴 2. Beta tester entitlement — lifetime Pro for testers
**Why it matters:** The monetization strategy promises "Lifetime Pro" to beta testers. We need to honor that programmatically when the public launch happens.

**What we ship:**
- A `BetaEntitlement` flag stored locally (granted during beta period via launch arg, settings toggle, or a one-time code Carlos shares)
- When `SubscriptionService.isPro` is checked, also OR with `BetaEntitlement.isActive`
- A subtle badge in Settings → Subscription: "Beta Founder · Pro for life"
- When public launch ships, existing beta installs automatically have the flag set
- New installs after launch date don't get the flag (cutoff date)

**Implementation approach (simplest):**
- Add `betaEnrolledBefore: Date?` to AppSettings
- Set it on first launch IF user is on a TestFlight build OR if app version < public launch version
- Check it alongside StoreKit subscription in `isPro` computed property
- Doesn't require server, doesn't require accounts

**Effort:** 4-6 hours.

**Blocker:** None. Can ship anytime, but most useful right before App Store launch.

---

### 🟡 3. 30-day Apple StoreKit free trial — currently 7-day
**Why it matters:** Strategy doc commits to 30-day trial. Currently 7-day. Apple StoreKit handles trials per-product; we configure in App Store Connect.

**What we ship:**
- Update Pro Yearly intro offer: 7 days → 30 days free
- Update Pro Monthly intro offer: 7 days → 30 days free
- Trial countdown UI in Settings: "Pro trial: 22 days left · auto-renews [date]"
- Email reminder via local notification 3 days before trial converts to paid (transparent, not surprise-charging)

**Effort:** 1-2 hours of code + App Store Connect changes.

**Blocker:** None.

---

### 🟡 4. Honest paywall + restore purchases
**Why it matters:** Sarah will scrutinize the paywall. Apple requires Restore Purchases visible. The audience hates dark patterns.

**What we audit + fix:**
- Paywall shows BOTH prices clearly + trial duration + renewal date estimate
- Renewal price after trial visible BEFORE purchase
- "Restore Purchases" button on the paywall (required by Apple)
- "Cancel anytime in Settings → Apple ID → Subscriptions" line
- No fake urgency ("LIMITED TIME!" that's actually always on)
- No "Continue" button that auto-charges (must be explicit "Start Trial / Subscribe")

**Effort:** 2-3 hours to audit + polish existing PaywallView.

**Blocker:** None.

---

### 🟡 5. Trial countdown UI
**Why it matters:** Subscribers shouldn't be surprised by the trial ending. Showing "22 days left in trial" earns trust + reduces refund requests.

**What we ship:**
- A card in Dashboard during trial: "Pro Trial · 22 days left, renews [date] at $39.99"
- Same card in Settings → Subscription section
- 3-day-out reminder via local notification: "Your Pro trial ends Saturday. Manage in Settings."

**Effort:** 3-4 hours.

**Blocker:** None.

---

## Soft launch features (Month 4-6, when App Store is live)

### 🟢 6. Founder pricing product ($29.99/yr for first 100)
**Why it matters:** Strategy commits to founder pricing for first 100 paid. Apple StoreKit can do this 2 ways:

**Option A: Promo codes**
- Generate 100 unique promo codes in App Store Connect
- Distribute via marketing (site banner: "First 100: use code FOUNDER for $29.99")
- Apple tracks redemption count
- Simple, no code changes

**Option B: Separate IAP product**
- Create "Pro Yearly - Founder ($29.99)" as a separate IAP
- Available only to users who launched before [cutoff date]
- More work but cleaner UX

**Recommendation: Option A (promo codes).** Simpler, lower risk. Code on the marketing site + in the recruitment message.

**Effort:** 30 min in App Store Connect.

---

### 🟢 7. Soft paywall at value moments
**Why it matters:** The current paywall is generic. Sarah converts when she's experiencing a Pro need — not when she lands on Settings.

**What we ship — contextual Pro upsell triggers:**
- User taps "Export CSV" → sheet: "CSV exports are part of Pro. Want a 30-day free trial?"
- User completes a claim → "Generate the PDF submission package?" → Pro upsell if not Pro
- User toggles iCloud backup (post-CloudKit) → "iCloud sync is part of Pro."
- User reaches 10+ receipts → "Heading into July? Pro generates the submission PDF for you."

These should feel like helpful interruptions, not aggressive paywalls. Always offer "Maybe later" without consequences.

**Effort:** 4-6 hours to wire 4-5 contextual triggers.

---

### 🟢 8. In-app App Store review prompt
**Why it matters:** Reviews compound App Store visibility + trust. Apple gives you a few prompts per year per user; spend them at peak-positive moments.

**What we ship:**
- After user gets their first "Eligible" verdict on a real receipt → prompt
- After user successfully submits a claim → prompt
- After 5+ receipts saved → prompt
- Use Apple's `SKStoreReviewController.requestReview(in: scene)` — Apple rate-limits this for us

**Effort:** 30 min.

---

### 🟢 9. "What's new" sheet on first launch after update
**Why it matters:** Niche-but-beloved apps win on visible changelogs. Sarah wants to know what changed and that there's still a human shipping updates.

**What we ship:**
- On first launch of a new version, show a friendly sheet: "v0.7 — iCloud sync is live. Your data now syncs across your iPhone and iPad. — Carlos & Ramsey"
- Dismiss button stores last-seen version in AppSettings
- Lives forever as the changelog Sarah trusts

**Effort:** 1-2 hours.

---

## Growth phase features (Month 7-12, FPEA + scale)

### 🟢 10. Referral mechanic — "Tell a mom, get a month"
**Why it matters:** Word-of-mouth is the primary acquisition channel. Make it rewarding.

**What we ship:**
- Settings → "Invite a friend" → generates a shareable link with a referral ID
- When the friend installs and converts to Pro, the referrer gets +1 month
- The friend gets a 7-day extended trial (37 days instead of 30)
- Simple referral tracking via App Store Connect's promo codes or our own backend

**Caveat:** True referral tracking requires either a backend (breaks our no-server promise) OR Apple's official referral attribution (limited to App Store ads). A simpler version: a shareable promo code that gives the friend a discount AND the referrer a month — no automatic attribution, just trust + Carlos manually crediting.

**Effort:** Half-day for the simple version. 2-3 days for full attribution.

---

### 🟢 11. Sample data mode (for FPEA demo)
**Why it matters:** Showing the app at a booth is hard with an empty install. Demo mode = instant "see how it works."

**What we ship:**
- Launch arg `--demo` populates sample data: 3 students, 12 receipts, 4 claims at various statuses
- Banner at top: "Demo mode · tap to exit and start fresh"
- Exits demo wipes the sample and lets the user start their own data

**Effort:** 3-4 hours.

---

### 🟢 12. Year-end summary report (verify it's actually built)
**Why it matters:** The strategy doc lists this as a Pro feature. Audit: is it actually implemented or just a placeholder?

**What we audit:**
- Generate a printable PDF: "Maya's FES-UA Year — 2026-27. Total spent: $8,247. Categories: ..."
- Trigger: Settings or auto-generated on July 31 each year
- Builds switching cost: users with years of summaries don't leave

**Effort:** If not built, 1 day. If built, 30 min to polish.

---

## Long-term / Year 2+ features (compounding play)

### 🟢 13. Annual portfolio + evaluation packet (PEP killer feature)
**Why it matters:** Per audience research, PEP requires an annual evaluation. This is the "year-2 expansion" that makes ScholarKeep indispensable.

**What we ship:**
- "Generate evaluation packet" button (Pro only)
- Compiles: year's curriculum receipts, hours log, sample-work photos (parent uploads), parent-signed declaration
- Outputs printable PDF ready to hand to evaluator
- Partner with named evaluators (flhomeschoolevaluations.com etc.) for distribution

**Effort:** 1-2 weeks. Big feature but huge value.

---

### 🟢 14. Provider directory (FES-UA killer feature)
**Why it matters:** "Where do I find a BCBA in Brevard who takes FES-UA?" — Step Up's marketplace is widely disliked.

**What we ship:**
- In-app directory of providers parents have used + reviewed
- Filterable by county + service type
- Reviews from anonymous-but-verified ScholarKeep users
- Could become a marketplace business (provider-side revenue) in year 3

**Effort:** 2-3 weeks. Largest feature. Year-3 work.

---

## Cross-cutting trust + retention features

| # | Feature | Purpose | Effort |
|---|---|---|---|
| 15 | "Your Pro renews [date]" prominently in Settings | Reduce refund requests | 30 min |
| 16 | Annual renewal email-via-notification: "Pro renewed — here's what it did this year" | Transparency + retention | 2 hrs |
| 17 | Grace period on failed payments (Apple handles this) | Avoid involuntary churn | 0 (built-in) |
| 18 | Subscription state visible always (Pro / Trial / Free) | Honesty | already exists |
| 19 | Soft re-engagement notification after 30 days dormant: "Your July 31 deadline is X days away" | Retention | 1 hr |
| 20 | "Data export anytime" (CSV is currently Pro — consider making it Free) | Avoid hostage feeling | 0 (just unflag from Pro gate) |

**On #20:** Worth debating. Making CSV export FREE removes a Pro feature but builds the "we won't hold your data hostage" trust signal. Sarah hates apps that force you to pay to leave. The PDF submission package stays Pro (more polished, real differentiator). Recommend free CSV.

---

## Prioritized ship order

Mapping the strategy to a build order:

### Sprint 1 (Weeks 1-2): Trust foundation
- **#1: CloudKit sync** — must ship before anyone pays
- **#2: Beta entitlement** — promise we made
- **#4: Honest paywall audit** — must be right before strangers see it

### Sprint 2 (Weeks 3-4): Conversion mechanics
- **#3: 30-day trial** — App Store Connect change + UI
- **#5: Trial countdown UI**
- **#7: Soft contextual paywall triggers**
- **#8: App Store review prompt**

### Sprint 3 (Weeks 5-6): Launch polish
- **#6: Founder pricing promo codes** (App Store Connect only)
- **#9: What's new sheet**
- **#15, #18: Subscription transparency polish**
- **#12: Year-end summary audit + polish**

### Sprint 4 (post-launch, ongoing)
- **#10: Referral mechanic** (FPEA prep)
- **#11: Demo mode** (FPEA prep)
- **#19: Re-engagement notification**
- **#20: Free CSV export** (debatable, my recommendation: yes)

### Year 2 builds
- **#13: Annual portfolio packet** (PEP indispensability)
- **#14: Provider directory** (FES-UA indispensability)

---

## What this means for Carlos's calendar

If we follow this sequence:
- **Next 4 weeks of build:** CloudKit + Beta entitlement + Paywall polish + Trial mechanics = ship-ready-to-charge
- **Week 5:** App Store submission with reviewer notes
- **Weeks 5-8:** Apple review + first beta moms testing parallel
- **Week 9-10:** Public launch with testimonials + founder pricing
- **Month 3-6:** Growth phase, FPEA prep
- **Month 6-7:** FPEA convention May 2026
- **Month 12:** Annual portfolio packet ships
- **Month 18:** Provider directory begins

That's the buildout. Each phase pays for the next, each feature serves the monetization phase it's mapped to.

**Carlos's only ongoing job in parallel:** Recruit beta testers, collect testimonials, and don't burn the trust we've architected.
