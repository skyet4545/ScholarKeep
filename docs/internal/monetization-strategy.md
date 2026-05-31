# ScholarKeep Monetization Strategy

_Answer to "who's gonna pay for an untested app, and how do we get from zero to revenue?"_

## The brutal truth about pricing apps in this niche

1. **The current pricing ($4.99/mo or $39.99/yr) is correct.** Don't change it. The earlier research confirmed this is the right anchor (Cozi Gold = $39/yr, Day One Silver = $50/yr, audience pays exactly this for adjacent productivity apps).

2. **The audience can pay $40 and will if it's earned.** They already pay it for Cozi, Erin Condren planners ($60), curriculum subscriptions ($60-200). $40 is not the obstacle.

3. **The obstacle is trust, not price.** Sarah won't pay $40 to a stranger to manage her kid's records. She'll pay $40 to a tool another mom in her FB group has used for 3 months and recommends.

4. **Charging too early kills momentum.** If the first 5 beta moms hit a paywall before they've experienced value, they bail and tell their group "it's another paid app pretending to be free."

5. **Charging too late wastes goodwill.** If beta runs 18 months and we keep saying "still free!", the early adopters expect free forever.

The window: charge after testimonials exist, before the early audience expects free permanently.

---

## Who pays first, and why

In order of "first to convert":

### Tier 1: People Carlos already trusts → Carlos
- Your co-op friends, church community, family members who do homeschool
- They pay because they want to support you, not because they did a cost-benefit analysis
- Realistic ceiling: 10-20 people
- They'll be your first testimonials regardless of whether they pay

### Tier 2: Beta testers who experienced the "one avoided $400 mistake"
- Sarah catches that her Chromebook needed a pre-auth she forgot
- Or her July 31 PDF saves her 4 hours
- One concrete save = the conversion trigger
- They'll pay $40 happily because the math is obvious

### Tier 3: FB group strangers who saw a tester's testimonial
- "@Amanda recommended ScholarKeep and I tried it — game changer."
- This is where the actual scale starts
- They convert at maybe 5-15% trial-to-paid rate
- Requires Tiers 1 and 2 to have generated the social proof first

### Tier 4: FPEA convention attendees
- May 2026, Gaylord Palms
- Booth presence + demo + immediate trial
- High-intent audience
- Could be your single biggest revenue event in year 1

### Tier 5 (year 2+): Organic App Store search
- "Florida ESA tracker" / "Step Up scholarship app"
- Low volume but high intent
- Compounds over time as App Store ratings accumulate

---

## The "earn the right to charge" 4-phase sequence

### Phase 1: Free Beta (NOW → Month 3)
**Goal:** Validate, gather testimonials, learn what's broken.

- ScholarKeep is 100% free for beta testers
- Pro features included
- Beta testers get **Lifetime Pro free** when public launch happens (loyalty hook + a thank-you that costs us nothing because they were going to be Pro anyway)
- Target: 10-20 beta moms, 6-12 weeks of usage each
- Active feedback collection (the in-app "Send feedback to Carlos" we already shipped)
- Carlos personally responds to every feedback email — that single behavior creates the testimonials we'll need in Phase 2

**Revenue: $0. Investment: time + the cost of giving away Pro to ~20 lifetime accounts.**

### Phase 2: Soft launch with testimonials (Month 4-6)
**Goal:** Convert beta moms' word-of-mouth into the first 50 paying users.

- ScholarKeep on App Store. Free download.
- Pro $4.99/mo or $39.99/yr (current pricing — don't change)
- **30-day free trial of Pro** (Apple StoreKit handles this — moms see the full thing, decide on day 28)
- Free tier remains genuinely useful (eligibility checker, basic tracking)
- Marketing site now leads with 2-3 real testimonials from beta moms
- The first 50 users come from: Carlos's network + each beta mom telling 5 friends
- Goal: 50 paid users = $2,000/yr ARR

**Revenue: ~$2,000 ARR. Investment: App Store submission + getting testimonials.**

### Phase 3: Growth via community (Month 7-12)
**Goal:** Get to 500 paid users.

- FPEA convention May 2026 — big push (~50 booth conversions possible)
- Sponsored mentions on 1-2 FL homeschool podcasts ($200-400 each)
- One-time "Florida homeschool family" Founder pricing offer: $29.99/yr for first 100 (urgency + loyalty)
- Family Sharing pushed prominently — "$40 covers your whole family"
- Carlos & Ramsey post a quarterly "what's new" video on Instagram
- Goal: 500 paid users = $20,000 ARR

**Revenue: ~$20,000 ARR. Investment: convention booth + light marketing budget if needed.**

### Phase 4: Compounding (Year 2+)
**Goal:** Get to 2,000-5,000 paid users + start year-2 expansion features.

- Year-1 cohort renews at high rate (the year of receipts they have in the app = high switching cost)
- Annual portfolio + evaluation packet ships → makes Pro indispensable for PEP families
- Provider directory (the v3 audit recommendation) → makes Pro indispensable for FES-UA families
- Word-of-mouth compounds — each happy mom tells 3-5
- Goal: 2,000+ paid = $80K+ ARR
- This is when ScholarKeep becomes a real business

**Revenue: $80K+ ARR. Investment: full-time effort, possibly a part-time hire.**

---

## Specific pricing decisions (lock these in)

### Beta (now)
- **Free for everyone.** Pro included. Lifetime Pro promised to all beta testers.

### Public launch (Month 4-6)
- **Free tier:** Eligibility checker, basic receipt tracking, claim list, deadline reminders, recurring tasks. No artificial caps. Honestly useful.
- **Pro $39.99/yr or $4.99/mo:** PDF submission packages, CSV exports, iCloud backup (when shipped), year-end summary report, Family Sharing.
- **30-day free trial** of Pro for everyone (Apple StoreKit handles this)
- **Founder pricing** ($29.99/yr) for first 100 paid users — urgency + locks in goodwill

### Don't do
- ❌ Free tier with usage caps ("50 receipts then pay"). Feels stingy, kills trust.
- ❌ Pop-up paywalls mid-flow. Sarah will rage-quit.
- ❌ Auto-renew without an obvious reminder a week before charge. Apple requires it; do it well.
- ❌ "Lifetime" pricing for new users. Too cheap, kills annual recurring.
- ❌ Multiple tiers (Pro / Pro+ / Premium). Confusion. One Pro tier only.

### Maybe later (don't ship in v1, revisit at month 12)
- **"Family Founder" tier:** $99/yr, covers 5 students, includes a printable annual portfolio template. Tests whether power users (FES-UA + multi-kid) will pay 2.5×.
- **Lifetime upgrade option:** $149 one-time, for the segment that hates subscriptions. Run as experiment, see if it cannibalizes annual.

---

## What needs to be true before we charge anyone

In strict order — each is a blocker for the next:

| # | Requirement | Status |
|---|---|---|
| 1 | App works reliably for the core flow (scan → verdict → claim) | ✅ Shipped through v0.6.3 |
| 2 | 5+ beta testers used it for 2+ weeks and gave feedback | ❌ Not started — needs Carlos's outreach |
| 3 | **Real CloudKit sync** so a paid user's data won't vanish if their phone dies | ❌ Queued for v0.7 — blocker for charging |
| 4 | 2-3 written testimonials from beta moms with names + counties | ❌ Comes after #2 |
| 5 | App Store listing live (so people can actually buy) | ❌ Submission deferred until #2-4 |
| 6 | Foundation Models receipt extraction (the "wow" that justifies $40) | 🟡 Nice-to-have, not blocker |

**The critical path to first dollar:** Get testers → ship CloudKit → collect testimonials → submit App Store → first paying user.

Realistic timeline: 8-12 weeks from now to first paid user.

---

## What changes the strategy

| Trigger | New strategy |
|---|---|
| HeyPeppy responds aggressively (drops price, adds iOS app) | Faster App Store push; lean harder on privacy + on-device differentiation |
| One beta mom posts a viral testimonial in a 50k-member FB group | Accelerate App Store submission immediately; have founder pricing ready |
| FPEA approaches us about a partnership | Take the meeting; consider modest revenue share for newsletter + booth |
| 30+ beta moms in 2 weeks | Skip founder-pricing scarcity, go straight to standard $39.99 — demand exceeds capacity |
| Beta feedback says "it's worth $80, not $40" | Test $59.99 price point with new sign-ups; don't change for existing free testers |
| Beta feedback says "no one will pay $40 for this" | Re-examine value props; consider $19.99/yr or free + sponsored newsletter model |

---

## The actual one-paragraph monetization plan

> "ScholarKeep is free during a 12-week beta with 10-20 hand-picked FL homeschool moms, who get lifetime Pro as a thank-you. After we've shipped real iCloud sync and collected 3 testimonials, ScholarKeep goes on the App Store with a generous free tier and Pro at $39.99/yr (30-day trial via Apple). First 100 paid users get a $29.99 founder price. We push hard at the FPEA convention in May. Year-2 features (portfolio packet, provider directory) drive renewals and Pro upgrades. Target: 50 paid by month 6, 500 by month 12, 2000+ by month 24."

That's the plan. Each phase pays for the next. Nothing speculative — every step is responding to validated signal from the previous step.

## Carlos's question, answered directly

**"Who's gonna pay for it without getting tested?"**

**Nobody.** And that's correct. The app shouldn't be paid until 10-20 moms have used it for free for 6-12 weeks and 3 of them write down what it saved them. Then strangers will pay because Sarah-from-the-FB-group already did the testing for them.

The path to first revenue isn't "figure out the right price." It's:
1. **Get 5 moms to install it this week** (your job — post the recruitment message)
2. **Listen to them for 6 weeks** (the in-app feedback shortcut is already shipped)
3. **Ship CloudKit sync** so their data is safe (my next big build)
4. **Get them to write 2-3 sentences each about what it saved them**
5. **Submit to App Store with those testimonials front and center**
6. **Charge $39.99/yr to everyone after that**

That's the strategy. The only thing standing between you and revenue is step 1.
