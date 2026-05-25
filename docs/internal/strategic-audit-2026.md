# ScholarKeep Strategic Audit — 2026

_Synthesis of three research streams + ScholarKeep audit + prioritized recommendations._
_Generated 2026-05-25._

## TL;DR

ScholarKeep is well-built for 2025-vintage standards but has 4 specific risks before it can be successfully launched, and 3 specific 2028-positioning investments to make this year. The single biggest competitive issue: **HeyPeppy already serves this exact niche**, and our marketing doesn't position against it.

**Top 5 priorities, ranked:**

| # | Action | Effort | Strategic value |
|---|---|---|---|
| 1 | Marketing copy audit + HeyPeppy positioning + mom acknowledgment | 30 min | Critical — current site doesn't differentiate against incumbent |
| 2 | App Store readiness gates (account delete, VoiceOver, contrast) | 3-4 hrs | Critical — blocks submission, blocks scale |
| 3 | Foundation Models receipt extraction + appeal-letter drafting | 1 week | Biggest "wow" leap — on-device AI w/ no privacy cost |
| 4 | App Intents for 5 core verbs + IndexedEntity | 2-3 days | Cheapest investment with longest 2028 payoff |
| 5 | iPadOS first-class layout (Tab+Sidebar) | 1 week | Big quality lift for the audience's natural workflow |

---

## 1. Audience snapshot (verified)

**She:** 34-45, suburban/exurban FL (Tampa Bay, Jacksonville, Orlando, Polk, Brevard), married, one income or 1.5, 2-4 kids. Joined FL homeschool wave post-COVID (+46% in 5 years, Florida Trend). Handles 95% of receipt-and-reimbursement labor. Husband supports but doesn't engage with EMA portal. **Admin work happens 9-10pm after kids are in bed.**

**Where she lives online (named):**
- **FPEA** (Florida Parent-Educators Association) — 38th annual convention May 2026 at Gaylord Palms, Kissimmee. Highest-trust acquisition channel.
- Home Education Foundation (FLHEF) / flhef.org/pepinfo
- **Instagram**: @heavenly_homeschool covers PEP directly. #HomeschoolingLife hashtag.
- **Podcasts**: Schoolhouse Rocked (Aby Rinella), Little by Little Homeschool, Revival Homeschool, Joy Filled Podcast.
- **Trusted curriculum brands**: MasterBooks, BJU Press, Sonlight, IEW, Notgrass, Apologia.

**Religious + political context:**
- ~91% Christian nationally; FL likely skews more conservative-religious
- BUT meaningful secular-special-needs segment (FES-UA pulled autism/dyslexia families)
- **Avoid**: explicit Bible verses on homepage, political signaling, "school choice" framing, praising DeSantis or "freedom"
- **Safe**: "stewardship," "calling" (subtle, PEP-targeted), warm family voice, "your homeschool"

**Language to use vs avoid:**
| ❌ Don't say | ✅ Say instead |
|---|---|
| students, learners, scholars | kids, your kids, your homeschool |
| school choice | your scholarship, your PEP funds, your award |
| (any political signaling) | (just talk about the receipts and the math) |

## 2. Competitive landscape — the HeyPeppy threat

**HeyPeppy** (peppycat.com) is the incumbent in this niche. Today.
- AI-categorization for PEP/UA
- $12/mo Pro, $19/mo Ultra (= $144-228/yr)
- 25% FPEA partnership discount
- Web-first (no native iOS app)
- Cloud-based

**ScholarKeep wins on 5 axes — these need to be EXPLICIT in marketing:**

| Axis | ScholarKeep | HeyPeppy |
|---|---|---|
| **Platform** | Native iOS, made for mom's actual phone use | Web-first |
| **Privacy** | On-device only, zero servers | Cloud-based |
| **Price** | $39.99/yr ($3.33/mo) | $144-228/yr |
| **Program coverage** | FES-UA + FES-EO + PEP | PEP + UA only |
| **AI posture** | Manual control + AI helpers — you decide | AI-first categorization moms don't trust on $400 buys |

**The "manual control" insight from audience research:** moms are open to AI doing OCR, but skeptical of AI categorizing because if it gets one item wrong on a $400 curriculum bundle, they have to redo it manually anyway. Our positioning should be **"AI that helps, you decide"** not **"AI that does it for you."**

## 3. The "dads built this for moms" optics trap

Audience research flagged this explicitly: a two-dad founding story is fine IF the marketing voice is authored *with* moms. Currently the entire ScholarKeep site is dad-voiced. Risks reading as performative.

**Fixes (in order of credibility):**
1. Get 1-2 mom beta testers to give quotes/testimonials for the site
2. Add a named mom advisor visible on the About page
3. At minimum, add a line acknowledging "built with the help of homeschool moms who don't have time for bad software"

This isn't optional — without it, the dad-collective voice becomes a liability.

## 4. App Store readiness audit

Per the 2026 best-practices research, here's where ScholarKeep stands:

| Benchmark | Status | Action |
|---|---|---|
| PrivacyInfo.xcprivacy | ✅ Just added | Verify all Required Reason APIs are declared |
| App Privacy label = "Data Not Collected" | ✅ True (on-device only) | Confirm in App Store Connect |
| Account deletion path | ❌ Missing | Sign in with Apple users need in-app delete (Settings → Sign out is not enough) |
| Tab bar 3-5 tabs | ✅ 4 tabs | — |
| Cold start ≤ 1.5s | ❓ Unmeasured | Profile via Xcode Organizer |
| VoiceOver 100% coverage | ❓ Likely partial | Audit via Accessibility Inspector |
| Dynamic Type at 200% | ❓ Unverified | Test in simulator |
| WCAG AA contrast on terracotta | ❓ Unverified | Verify status colors hit 4.5:1 |
| Crash-free sessions ≥ 99.5% | ✅ Likely (120/120 tests pass) | Verify in TestFlight Crashes view |
| Empty states functional | ✅ JournalEmpty pattern | — |
| Reviewer notes with sample receipt | ❌ Need to draft | Will pre-empt Share Extension review issues |

**4 blockers before App Store submission:**
1. ✅ Privacy manifest (done in this session)
2. Account deletion in Settings
3. VoiceOver label audit
4. Reviewer notes draft

## 5. Future-forward investments (2028 readiness)

The single biggest finding from the future-forward research: **Foundation Models (Apple's on-device LLM) will be table-stakes by 2028.** It's the iOS 17 → iOS 19 generational shift.

### Investment #1: Foundation Models receipt extraction (1 week of work)

**What:** Add `ReceiptExtractor` service wrapping `LanguageModelSession` with a `@Generable ReceiptDraft` struct (merchant, date, line items, ESA category, total, tax). Run on-device only.

**Why this matters for ScholarKeep specifically:**
- Better OCR + structured extraction than VisionKit alone
- AI-assisted categorization that **doesn't break the privacy promise** (it's all on-device)
- Drafted appeal letters when a claim is denied — huge value for the audience
- Writing Tools integration on every TextEditor (proofread/rewrite for free)
- **Killer marketing story**: "AI you can actually trust, because it lives on your phone, not in a corporate data center"

This is the single biggest differentiator we can ship in 2026. It directly counters HeyPeppy's AI-categorization-but-in-the-cloud pitch.

### Investment #2: App Intents + IndexedEntity (2-3 days)

**5 core verbs:**
1. Add Receipt (with photo)
2. Find Receipts matching X
3. Submit Claim
4. What's my YTD remaining for [student]
5. Check eligibility of [item]

Conform `Receipt` and `Student` to `AppEntity` + `IndexedEntity`. Free benefits:
- Spotlight search of receipts from home screen
- Siri integration (today: structured intents; tomorrow: personal-context Siri)
- Action Button, Control Center, Visual Intelligence pickers all work automatically
- Apps without App Intents will feel as broken in 2028 as apps without share extensions did in 2020

### Investment #3: iPadOS first-class layout (1 week)

iOS 18 `Tab + TabSection` pattern → expands into sidebar on iPad. Plus `NavigationSplitView` for claim detail.

**Why for our audience:** ESA families often do claim review at a desk on iPad, not phone. Currently iPad is supported as a checkbox but not first-class. Same SwiftUI codebase.

### Things to AVOID (the research is specific):

| Looks futuristic | Why skip |
|---|---|
| Vision Pro / visionOS port | Device cost excludes 99% of audience |
| App Clips | Wrong entry pattern — moms aren't at a physical location |
| Watch app | "Is this eligible?" voice query is rare in practice |
| Mac Catalyst | iPad-first IS the desktop story |
| Genmoji / Image Playground | Zero relevance |
| Standby mode widget | Not when moms check ESA reimbursements |

## 6. Year 2-3 expansion paths (from audience research)

When ScholarKeep has product-market fit, these are the natural extensions:

### Year 2 path A: Annual portfolio + evaluation packet
PEP requires an annual evaluation; FES-UA requires standardized testing or evaluator sign-off. "Tap to generate evaluation packet from the year's receipts + portfolio of student work" is the bridge from receipt-tracker to indispensable. Partners well with named evaluators like flhomeschoolevaluations.com.

### Year 2 path B: Eligibility check at the register
Camera + barcode/category check. "Is this PEP-eligible?" in the store. Addresses highest-friction in-store moment. Could expand to shared family approval flow ("dad scans, mom approves").

### Year 3 path C: Provider directory + booking
Approved-provider discovery, with reviews from other FL families. This is the moat HeyPeppy hasn't built and Step Up's own marketplace is widely disliked. Long-term path into marketplace business with provider-side revenue.

## 7. Distribution + marketing strategy (refined)

Based on audience research:

| Channel | Effort | Expected leverage |
|---|---|---|
| FPEA booth at May 2026 convention | High (in-person, $$) | Highest trust |
| FPEA newsletter sponsorship | Medium | High trust |
| Instagram @heavenly_homeschool partnership/mention | Medium | High |
| Podcast sponsorship (Schoolhouse Rocked, Little by Little) | Medium | Medium-high |
| FB groups (Carlos + Ramsey post in different ones) | Low | Medium (starting point) |
| App Store organic | Low | Low for niche search |
| Google search ads | Low-medium | Probably wasteful |

**Strategy:** Free channels first (FB groups, recruitment message → 5-10 testers). FPEA convention as the big Q2 2026 push. App Store submission unblocks "scholarkeep" search.

## 8. What we keep doing right

- Privacy-first / on-device positioning
- Eligibility ruleset cited line-by-line from official guides
- Chat-style "Can I buy this?" interaction (early Foundation Models pattern)
- Apple Journal-style design (matches the audience's aesthetic)
- $39.99/yr pricing (correctly anchored)
- Explicit "not affiliated with Step Up" stance
- Family Sharing on Pro
- Solo-developer cadence + human-voice changelog (Mela pattern)

## 9. The Year-1 roadmap (synthesized)

**Week 1 (this week):**
1. Marketing copy audit + HeyPeppy positioning + mom acknowledgment
2. Account deletion in Settings
3. VoiceOver audit
4. Color contrast verification

**Week 2:**
5. App Store screenshots
6. App Store Connect metadata + submission
7. Carlos & Ramsey start FB group outreach in parallel

**Week 3-4:**
8. First 5-10 beta moms onboarded, feedback collected
9. v0.6.x patches based on feedback

**Month 2-3:**
10. Foundation Models receipt extractor (v0.7.0)
11. App Intents + IndexedEntity (v0.8.0)

**Month 4-6:**
12. iPadOS first-class layout (v0.9.0)
13. v1.0 public launch
14. FPEA convention prep

**Year 2:**
15. Annual portfolio packet
16. Eligibility check at register

**Year 3:**
17. Provider directory + booking

---

## Sources used

- **Audience research**: FLDOE, Step Up For Students, Florida Trend, NHERI, Barna, Pew, FPEA, peppycat.com (competitor), evening-routine evidence from Apologia + BookShark blogs
- **Best practices**: Apple HIG, Apple Privacy Manifest docs, QAwerk App Store Rejection 2026, Adapty Mobile App Onboarding 2026
- **Future-forward**: Apple Foundation Models docs, App Intents docs, WWDC25 sessions, Donny Wals on iOS 18 TabView, ActivityKit, Core Spotlight unification

Detailed reports for each stream archived at this commit.
