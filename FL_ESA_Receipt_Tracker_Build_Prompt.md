# Build Prompt — "ScholarKeep": Florida ESA Receipt & Reimbursement Tracker (iOS)

> **How to use this document:** Paste this entire file into Claude Code as the project brief. It contains the product spec, the domain knowledge (Florida ESA rules), the data model, the eligibility rules engine, the submission lifecycle, screen-by-screen UX, the tech stack, a phased build plan, and acceptance criteria. Build the app iteratively, milestone by milestone, and check each milestone against the acceptance criteria before moving on.

---

## 0. TL;DR for the builder

Build a **native iOS app (SwiftUI, iOS 17+)** that lets a Florida parent **scan receipts, automatically extract the details, check whether each purchase is likely eligible** under their child's ESA scholarship rules, **track each expense through the reimbursement lifecycle**, and **export submission-ready reports**. Storage is **local-first (SwiftData) with optional iCloud (CloudKit) backup**. All OCR runs **on-device (Apple Vision)**. The app is a **personal companion/preparation tool** — it does **not** connect to the state's system (see the critical constraint below).

---

## 1. Product overview & goal

Florida runs Education Savings Account (ESA) scholarship programs that put public education funds into a flexible, parent-directed account. Parents can either buy through an approved marketplace / pay approved providers directly, **or pay out of pocket and submit receipts for reimbursement.** The reimbursement path is **paperwork-heavy**: receipts must be itemized, proof of payment must be separate, items must be eligible, the student's name must match, and claims move through a multi-step review that frequently puts items "on hold" or denies them for fixable reasons.

**The problem:** Parents lose receipts, buy ineligible items by mistake, miss deadlines, and get claims denied for documentation issues — leaving scholarship money unspent or clawed back.

**The product:** A phone-based tracker that captures every purchase the moment it happens, validates it against the program's rules, keeps the documentation organized per student, and walks the expense through its whole life from "I bought this" to "I got reimbursed." Think of it as a **personal records system + eligibility coach + deadline minder** that makes the parent's actual submission in the official portal fast and rejection-proof.

**Target user:** A Florida parent/guardian managing one or more children on an ESA scholarship (FES-UA and/or PEP), administered by Step Up For Students or AAA Scholarship Foundation.

---

## 2. CRITICAL constraints & context (read before designing anything)

1. **There is NO public API for the state's ESA portal ("EMA" / Education Market Assistant) or for Step Up For Students / AAA.** The app **cannot** read the parent's real account balance, auto-submit claims, or fetch official statuses. **Do not attempt to build any integration with EMA, Step Up, AAA, MyScholarShop, or Tipalti.** This app is a **standalone companion**: the parent manually records what they bought, the app prepares and organizes everything, and the parent then submits through the official portal themselves. All "status," "balance," and "submitted/approved/paid" states in this app are **manually maintained by the parent** (the app reminds and assists, but is the source of *their own* records, not the state's). Make this clear in onboarding copy so expectations are correct.

2. **Program rules change every school year.** Eligible/ineligible item lists, caps, and deadlines are revised annually by the program. **Do not hard-code the rules in Swift.** Drive the eligibility engine from a **versioned JSON ruleset** (bundled with the app, with an optional remote-refresh hook for future updates). Tag every ruleset with a `schoolYear` and a `sourceVersion`, and surface "Rules as of [school year] — always confirm against the official Purchasing Guide" in the UI. A seed ruleset is provided in the Appendix.

3. **This is informational, not official guidance.** The eligibility check is a **helpful prediction**, never a guarantee. Every eligibility result must carry a disclaimer and a pointer to the official Purchasing Guide / Family Handbook. Include a clear in-app disclaimer (copy provided in §16).

4. **The data is sensitive** (children's names, disability program participation, financial receipts). Treat privacy as a first-class requirement: on-device by default, encrypted at rest, optional Face ID/Touch ID lock, no third-party analytics/trackers, no data leaves the device except the user's own iCloud backup if they enable it.

---

## 3. Domain primer — Florida ESA programs (the facts the app encodes)

> This section is the knowledge base. Encode the *rules* as data (Appendix), and use this prose to inform UX copy, the reference guide screen, and validation logic.

### 3.1 The two programs the app supports

**FES-UA — Family Empowerment Scholarship for Students with Unique Abilities** (Florida statute s. 1002.394)
- For Florida students age 3–4 or K–12-eligible who have an IEP **or** a diagnosed qualifying disability (autism, cerebral palsy, Down syndrome, intellectual disability, speech/language impairment, specific learning disabilities such as dyslexia/dyscalculia, traumatic brain injury, deaf/blind, rare disease, anaphylaxis, "high-risk" kindergartener, etc.). A 504 plan **alone** does not qualify.
- Average award ~**$10,000**; ranges roughly **$8,000–$34,000+** by grade, county, and documented level of need. No new funding once the account balance exceeds **$50,000**.
- **Broadest spending** — uniquely **includes specialized therapies** (see below).

**PEP — Personalized Education Program** (FTC-PEP, Florida statute s. 1002.395)
- For K–12 Florida residents **not enrolled full-time** in a public or private school (the homeschool / personalized-education population), any income (income-prioritized when oversubscribed). Student must be ≥5 by Sept 1.
- Award lower than FES-UA, roughly **$8,000–$10,000** for early grades, declining by grade and varying by district.
- Same flexible ESA structure, but **does NOT cover specialized therapies.**

**Administrators (Scholarship Funding Organizations / SFOs):** **Step Up For Students** (dominant; portal = **EMA**) and **AAA Scholarship Foundation** (portal = **SMP**). The **Florida Department of Education (FLDOE)** provides oversight/funding but does not process individual applications. The app should let the parent record which SFO and program their child is on, because terminology and some rules differ.

### 3.2 How money flows (3 paths)

1. **MyScholarShop (MSS)** — approved online store inside EMA; vendors paid **directly** from the account, no out-of-pocket. *(App role: parent can log these as "direct-pay" purchases for their own records; no reimbursement needed.)*
2. **Find Providers / direct pay** — approved tutors/therapists/providers bill the account directly. *(Same — log for records, no reimbursement.)*
3. **Reimbursement** — parent pays out of pocket, then submits receipts to be paid back. **This is the core flow the app optimizes.**

### 3.3 The reimbursement lifecycle (what the app tracks)

The parent's real-world steps in the official portal (the app mirrors/prepares these):
1. Set up a payout method once (ACH/direct deposit, check, or PayPal — processed via the portal's payments vendor).
2. Start a new reimbursement, select the student.
3. Upload an **itemized receipt/invoice** + a **separate proof of payment** (file types accepted by the portal: **PNG, JPG, PDF**).
4. Confirm the identified item(s), category, amount, and educational benefit.
5. Submit for approval.

**Claim statuses to model** (parent-maintained in this app):
`Draft → Ready to Submit → Submitted → Pending Review → On Hold (needs info) → Approved → Paid/Reimbursed`, with `Denied` as a terminal-but-reopenable branch (parent can resubmit/appeal). `On Hold` and `Denied` can return to earlier states.

### 3.4 Deadlines & timing (encode as data; they shift yearly)

- **Spending window:** purchases must occur **July 1 – June 30** of the school year.
- **Reimbursement submission deadline:** **July 31** following the school-year end (recently tightened from August; treat as data).
- **On Hold clock:** parent has **~30 days** to supply missing docs or the claim is denied.
- **Review time:** allow **up to 60 days** after all docs are in (commonly 2–4 weeks).
- **Disbursements:** funds typically deposited **quarterly** (~Feb 1, Apr 1, Aug 1, Nov 1). *(Flag: legislation has discussed moving to ten installments — keep this as data, not hard-coded.)*
- **Rollover:** unused funds generally roll over (FES-UA stops new funding above the $50k balance cap).

### 3.5 Eligible expense categories

**Shared by FES-UA and PEP:** instructional materials & curriculum; books; digital devices (laptop/Chromebook/tablet/e-reader, etc.) and peripherals subject to the device rule below; in-home internet & digital subscriptions/apps; online courses; tutoring (certified/eligible providers); private school tuition & fees (FES-UA); eligible postsecondary & dual-enrollment fees; standardized/AP/industry exam fees; sensory materials; P.E. and electives/enrichment; classroom furnishings; contributions to **Florida Prepaid / Florida College Savings** (*direct-pay only — NOT reimbursable*); annual evaluation by a certified teacher.

**FES-UA only:** **specialized services/therapies** — ABA, speech-language, occupational, physical, listening & spoken-language, psychotherapy/counseling, vision therapy — by **credentialed/licensed providers** (provider license # and dates of service required on the invoice).

**Device rule (important, enforce in engine):** generally **one device every 2 years** per student; the 2-year clock **follows the student across programs** (switching FES-UA↔PEP does not reset it); replacing sooner needs **pre-authorization**; multiples of a single peripheral over **$50** need pre-authorization. The app should track device purchase dates per student and **warn** when a new device is within the 2-year window.

### 3.6 Ineligible / commonly denied items (encode as keyword/category rules)

Cash payments to private sellers; medical services/devices (mobility aids, hearing aids, non-prescription eyeglasses — note PEP allows **one prescription pair/year**); items already paid by another source (insurance/HSA — no double-dipping); any refund/rebate routed back to the family; transportation/gas/mileage; lodging/meals; **family/multi-user** memberships & subscriptions when a single-user option exists; theme/water-park extras (parking, food, souvenirs, premium access, special-event tickets) and **theme-park admission over the cap (~$299 + tax, paid in full, one student per claim)**; concert/sporting/secondary-market/resale tickets; arcades; commercial-grade tools; motorized vehicles/scooters; pools/Jacuzzis; live animals; general household items; items below the manufacturer's minimum age; TVs over 55"; warranties; uniform accessories (belts, ties, socks, shoes); prohibited private-school fees (annual/registration, donations/fundraising, optional fees, food/lunch, before/after-care).

### 3.7 Documentation requirements (the rejection-prevention checklist)

For a clean reimbursement, each claim needs:
- **Itemized receipt/invoice** showing **vendor/provider name, purchase date, line-item description of each product/service, price breakdown (subtotal, tax, shipping, grand total).** A receipt that only says "PAID" is insufficient.
- **Separate proof of payment** (card/bank statement line, cleared-check screenshot, paid-in-full confirmation). EFT/PayPal may need a second proof of the funding source; ACH generally accepted.
- **Student name** matching the scholarship record **exactly** (required for providers, tutoring, theme parks, memberships).
- **Provider credentials/license # and dates of service** for services (FES-UA therapies, tutoring).
- **Educational Benefit Form** and/or **Pre-Authorization number** where required (e.g., field trips/theme parks, items not explicitly listed).
- **No handwritten alterations** on invoices (auto-hold).
- **One provider/service per claim** (split multiple providers into separate claims).
- Files in **PNG/JPG/PDF**.

The app should turn this into a **per-expense readiness checklist** that must be green before the parent marks an item "Ready to Submit."

---

## 4. Target platform & tech stack

| Concern | Choice | Notes |
|---|---|---|
| Platform | **iOS 17+** (iPhone first; iPad-compatible layouts) | Native, App Store distribution |
| Language/UI | **Swift 5.9+, SwiftUI** | MVVM architecture |
| Local persistence | **SwiftData** (Core Data acceptable fallback) | Local-first source of truth |
| Optional backup/sync | **CloudKit** (private database) via SwiftData's CloudKit integration | User toggle in Settings; off by default |
| Receipt capture | **VisionKit** `VNDocumentCameraViewController` (or `DataScannerViewController`) | Auto-crop, multi-page |
| OCR | **Apple Vision** `VNRecognizeTextRequest` (on-device) | No network; parse vendor/date/total/line items |
| PDF/CSV export | **PDFKit** + simple CSV writer | "Submission package" PDF per expense/claim |
| Local notifications | **UserNotifications** | Deadline & On-Hold reminders |
| Security | **LocalAuthentication** (Face ID/Touch ID), Data Protection (`.completeUnlessOpen`) | App-lock toggle |
| Charts (reports) | **Swift Charts** | Spend by category/status |
| Min. external deps | Prefer first-party frameworks only | Keeps it private & dependency-light |

**No backend server for v1.** No third-party SDKs for analytics/crash/ads. If crash reporting is desired later, use Apple's MetricKit.

---

## 5. Core features (the four pillars + supporting)

**Pillar 1 — Receipt capture & OCR.** Scan or import (camera, photo library, PDF, share-sheet). On-device OCR extracts **vendor, date, subtotal, tax, total, and line items**; parent reviews/corrects in a confirmation screen. Store original image(s) + structured data.

**Pillar 2 — Eligibility validation.** For each expense (and each line item), run the **rules engine** against the student's program (FES-UA/PEP) and return one of `Eligible / Likely Eligible / Needs Pre-Authorization / Likely Ineligible / Ineligible / Unknown`, with a plain-language reason and the relevant rule citation. Provide a **standalone "Can I buy this?" pre-purchase checker** too.

**Pillar 3 — Submission lifecycle tracking.** Each expense becomes (or joins) a **Claim** that the parent advances through the status state machine (§9). Track status history, denial reasons, appeal notes, reimbursement method, expected vs. actual payout, and dates. Reminders fire for deadlines and On-Hold clocks.

**Pillar 4 — Reports & export.** Filterable summaries (by student, category, status, school year), spend-vs-award progress, and **export**: per-expense "submission package" PDF (receipt + proof + structured summary + checklist), per-claim PDF, and CSV of all expenses for record-keeping/taxes.

**Supporting features:** multi-student support; per-student manual balance tracker (award amount, manual deductions, remaining); device-purchase 2-year tracker; documentation readiness checklist; reference/guide screen (eligible/ineligible categories + deadlines, data-driven, with disclaimers); Settings (iCloud backup, app lock, ruleset version, export-all, delete-all).

---

## 6. Data model

Model with SwiftData `@Model` classes. Suggested entities and key fields:

**Student**
- `id` (UUID), `displayName`, `program` (enum: `fesUA`, `pep`), `sfo` (enum: `stepUp`, `aaa`), `gradeLevel`, `county`, `schoolYear` (e.g., "2026-27"), `awardAmount` (Decimal, optional, manual), `notes`
- Relationships: `expenses [Expense]`, `claims [Claim]`, `devicePurchases [DevicePurchase]`

**Expense**
- `id`, `vendorName`, `purchaseDate`, `subtotal`, `tax`, `shipping`, `total` (Decimal), `currency`
- `category` (ref to `RuleCategory.key`), `subcategory`, `paymentMethod` (enum), `acquisitionPath` (enum: `reimbursement`, `marketplaceDirectPay`, `providerDirectPay`)
- `eligibilityResult` (enum + reason string + matched rule keys), `eligibilityCheckedAt`, `rulesetVersion`
- `educationalBenefitNote`, `requiresPreAuth` (Bool), `preAuthNumber` (optional)
- `readinessChecklist` (embedded value: booleans for itemizedReceipt, proofOfPayment, studentNamePresent, providerCredentials, educationalBenefitForm, preAuthIfRequired, noHandwrittenAlterations)
- Relationships: `student`, `lineItems [LineItem]`, `attachments [Attachment]`, `claim` (optional)

**LineItem**
- `id`, `descriptionText`, `quantity`, `unitPrice`, `amount`, `eligibilityFlag` (enum), `matchedRuleKey`

**Attachment**
- `id`, `type` (enum: `receipt`, `proofOfPayment`, `educationalBenefitForm`, `credential`, `other`), `fileData`/`fileURL`, `mimeType` (png/jpg/pdf), `ocrText`, `createdAt`

**Claim**
- `id`, `title`, `status` (enum, §9), `submittedDate`, `decisionDate`, `paidDate`
- `reimbursementMethod` (enum: `ach`, `check`, `paypal`), `expectedPayout`, `actualPayout` (Decimal)
- `denialReason` (enum + free text, §8), `appealNote`
- Relationships: `student`, `expenses [Expense]` (one provider/service per claim — enforce in UX), `statusEvents [StatusEvent]`

**StatusEvent**
- `id`, `status`, `date`, `note`

**DevicePurchase** (for the 2-year device rule)
- `id`, `deviceType`, `purchaseDate`, `amount`, `expenseRef` — used to compute the next eligible date (`purchaseDate + 2 years`) and warn.

**RuleCategory / Ruleset** (loaded from JSON, not stored as user data — see Appendix)
- Ruleset: `schoolYear`, `sourceVersion`, `lastUpdated`, `categories [RuleCategory]`, `deadlines`, `globalRules`
- RuleCategory: `key`, `displayName`, `programs [enum]`, `eligibility` (enum), `keywords [String]`, `ineligibleKeywords [String]`, `caps`, `requiresPreAuth`, `requiresStudentName`, `requiresProviderCredentials`, `notes`, `sourceCitation`

**Deadline / Reminder**
- `id`, `kind` (enum: `submissionDeadline`, `onHoldClock`, `custom`), `dueDate`, `relatedClaim` (optional), `notificationScheduled` (Bool)

---

## 7. Eligibility rules engine

Build a pure, testable `EligibilityEngine` that takes `(Expense or item description, Student.program, Ruleset)` and returns a structured `EligibilityResult { status, reasons[], matchedRuleKeys[], requiresPreAuth, citations[] }`.

Evaluation order (first decisive match wins, but collect all reasons):
1. **Hard-ineligible keyword/category match** → `Ineligible` (e.g., "gas", "lunch", "resale ticket", "hearing aid").
2. **Program-specific exclusion** → e.g., any therapy category when `program == .pep` → `Ineligible (PEP excludes therapies)`.
3. **Direct-pay-only category** (Florida Prepaid) when `acquisitionPath == .reimbursement` → `Ineligible for reimbursement (direct-pay only)`.
4. **Device 2-year rule:** if category is a device and student has a `DevicePurchase` within 2 years → `Needs Pre-Authorization`.
5. **Cap checks:** amount over a category cap (e.g., theme park > $299, TV > 55") → `Ineligible`/`Needs Pre-Authorization` per rule.
6. **Requires pre-auth flag** (item not explicitly listed / category flagged) → `Needs Pre-Authorization`.
7. **Eligible keyword/category match** → `Likely Eligible` (+ list documentation requirements: itemized receipt, proof of payment, student name, credentials, educational benefit form as applicable).
8. **No match** → `Unknown — confirm against Purchasing Guide`.

Every result includes: plain-language reason(s), the documentation checklist it implies, a `sourceCitation`, and the standard disclaimer. The engine must be unit-tested with a fixtures table (Appendix lists seed cases).

---

## 8. Denial reasons (enum to model + offer as quick-pick when parent logs an On-Hold/Denied)

`missingVendorName`, `notItemized`, `missingPriceBreakdown`, `missingProofOfPayment`, `studentNameMismatch`, `missingProviderCredentials`, `missingDatesOfService`, `handwrittenAlteration`, `ineligibleItem`, `multipleProvidersOneClaim`, `overPriceCap`, `missingEducationalBenefitForm`, `missingPreAuth`, `duplicateClaim`, `pastDeadline`, `illegibleImage`, `other`.

When a parent marks a claim On Hold/Denied with a reason, the app suggests the **specific fix** and re-opens the relevant checklist item.

---

## 9. Submission lifecycle state machine

States: `draft`, `readyToSubmit`, `submitted`, `pendingReview`, `onHold`, `approved`, `paidReimbursed`, `denied`.

Allowed transitions:
- `draft → readyToSubmit` (only when readiness checklist is fully green)
- `readyToSubmit → submitted` (parent records they submitted in the official portal; capture submitted date)
- `submitted → pendingReview → approved → paidReimbursed`
- `submitted/pendingReview → onHold` (capture reason + start 30-day reminder)
- `onHold → submitted` (after parent adds the missing doc) or `onHold → denied` (clock expired/closed)
- `approved → denied` and `denied → readyToSubmit/submitted` (resubmit/appeal path)
- Any state → `draft` (parent edits)

Each transition writes a `StatusEvent`. Show the lifecycle as a **visual timeline** on the claim detail screen and as a **segmented/Kanban board** on the claims list.

---

## 10. Screen-by-screen UX spec

1. **Onboarding & disclaimer.** Explain the app is an unofficial personal tracker (not connected to the state), the "rules as of [year]" caveat, and privacy. Add first student (name, program, SFO, grade, county, school year, optional award amount). Offer Face ID lock and iCloud backup toggles.

2. **Home / Dashboard (per student, switchable).** Cards: spent vs. award progress (manual), counts by claim status, **"Needs attention"** (On-Hold items, incomplete checklists, upcoming deadlines), and a **deadline countdown** (July 31 submission; device 2-year windows). Prominent **"Scan receipt"** button.

3. **Capture receipt.** VisionKit scanner → OCR → **Review & confirm** screen with editable extracted fields (vendor, date, subtotal/tax/total, detected line items). Assign student, category (engine suggests one), acquisition path. Instant **eligibility badge** with reason. Save as Draft expense.

4. **Expense detail.** All fields; attached images (receipt, proof of payment, etc.); eligibility result + rationale + citation; **documentation readiness checklist**; buttons to attach proof of payment, add educational-benefit note, set pre-auth number; "Add to / create Claim"; "Mark Ready to Submit" (gated on green checklist).

5. **"Can I buy this?" pre-purchase checker.** Free-text or category picker + amount + student → eligibility verdict, documentation it will require, and any device-window/pre-auth warnings. No receipt needed.

6. **Claims board.** Segmented or Kanban by status. Tap a claim → **Claim detail** with the lifecycle timeline, included expense(s), status-update control (with denial-reason quick-pick + suggested fix), reimbursement method, expected vs. actual payout, and dates.

7. **Reports & export.** Filters (student/category/status/school-year). Swift Charts visuals (spend by category, by status). Export buttons: **expense submission-package PDF**, **claim PDF**, **CSV of all expenses**. Year-end summary view.

8. **Reference guide.** Data-driven, read-only: eligible categories, ineligible items, device rule, documentation checklist, deadlines — each with the disclaimer and a link to the official Purchasing Guide / Family Handbook for the relevant program.

9. **Settings.** iCloud backup toggle; app-lock toggle; ruleset version + "check for updates" (future hook); notification preferences; export all data; delete all data (with confirmation).

Design for **accessibility** (Dynamic Type, VoiceOver labels on all controls, sufficient contrast) and a clean, calm, trustworthy visual tone (this is financial/records software for stressed parents).

---

## 11. OCR & parsing approach

- Use `VNDocumentCameraViewController` for capture (auto edge-detection, multi-page), fall back to photo library / PDF / share-sheet import.
- Run `VNRecognizeTextRequest` (accurate, on-device, with language correction).
- Parse with heuristics: **total** = largest currency value near keywords ("total", "amount due", "grand total"); **date** via `NSDataDetector`; **vendor** = top-of-receipt prominent text; **line items** = lines containing a description + trailing currency. Keep raw OCR text for fallback and search.
- Always show a **human-in-the-loop confirmation** screen; never auto-commit parsed values. Persist the original image as the legal record.

---

## 12. Storage, sync & security

- **SwiftData** local store is the source of truth (local-first; full offline functionality).
- **Optional CloudKit private-DB sync** via SwiftData (`ModelConfiguration` with CloudKit) — **off by default**, toggled in Settings; used for backup/restore and multi-device.
- Enable **Data Protection** on the store; store attachment images in the app container with file protection.
- **App lock** with Face ID/Touch ID (LocalAuthentication), optional, with passcode fallback.
- **No analytics, no trackers, no ad SDKs.** No data egress except the user's own iCloud. Provide **export-all** and **delete-all** for data ownership.

---

## 13. Notifications & reminders

Schedule local notifications for: the **annual submission deadline** (e.g., reminders at 30/7/1 days before July 31), each **On-Hold 30-day clock**, **device 2-year window** opening, and any **custom reminders** the parent sets per expense/claim. Respect notification permissions; degrade gracefully if denied.

---

## 14. Non-functional requirements

- iPhone-first, iPad-compatible; portrait primary.
- Smooth on a 3-year-old device; OCR off the main thread.
- Fully usable offline.
- Localizable strings (English first; structure for future Spanish given the Florida audience).
- Unit tests for the eligibility engine and lifecycle state machine; snapshot/UI tests for key flows.
- Clean MVVM separation; the rules engine and parsers are pure/testable with no UI deps.

---

## 15. Suggested project structure & phased build plan

```
ScholarKeep/
├─ App/                      // entry point, app-lock gate
├─ Models/                   // SwiftData @Model types
├─ Rules/                    // Ruleset loader, EligibilityEngine (+ JSON resources)
├─ Capture/                  // VisionKit + Vision OCR + parsers
├─ Features/
│   ├─ Onboarding/
│   ├─ Dashboard/
│   ├─ Expense/              // capture, review, detail, checklist
│   ├─ EligibilityChecker/
│   ├─ Claims/               // board, detail, lifecycle timeline
│   ├─ Reports/              // charts + PDF/CSV export
│   ├─ Reference/
│   └─ Settings/
├─ Services/                 // persistence, sync, notifications, export
├─ Resources/                // ruleset-2026-27.json, assets
└─ Tests/                    // engine + state machine + parser tests
```

**Milestone 1 — Foundations.** Project setup, SwiftData models, onboarding, add/switch students, local persistence, app-lock, disclaimer. *Done when:* a parent can create students and the data survives relaunch.

**Milestone 2 — Capture & OCR.** VisionKit scan + import, Vision OCR, review/confirm screen, save expenses with attachments. *Done when:* a scanned receipt becomes a structured, editable expense with the image stored.

**Milestone 3 — Eligibility engine.** Ruleset JSON + loader + `EligibilityEngine` + unit tests; eligibility badge on expenses; standalone "Can I buy this?" checker; device 2-year tracker. *Done when:* the seed test table passes and badges/reasons show correctly per program.

**Milestone 4 — Claims lifecycle.** Claim model, status state machine, claims board, claim detail with timeline, denial reasons + suggested fixes, readiness checklist gating "Ready to Submit." *Done when:* an expense can travel Draft → Paid with full history, and On-Hold/Denied reasons drive checklist fixes.

**Milestone 5 — Reports, export & reminders.** Filters, Swift Charts, submission-package PDF, claim PDF, CSV export, deadline & On-Hold notifications. *Done when:* a parent can export a rejection-proof submission package and gets timely reminders.

**Milestone 6 — Backup, polish, accessibility, tests.** CloudKit backup toggle, settings, export/delete-all, VoiceOver/Dynamic Type pass, reference guide screen, final QA against acceptance criteria.

---

## 16. In-app legal/disclaimer copy (include verbatim, adjust as counsel advises)

> **Not affiliated with the State of Florida, the Florida Department of Education, Step Up For Students, AAA Scholarship Foundation, or EMA.** ScholarKeep is a personal record-keeping and preparation tool. It does not connect to, submit to, or retrieve data from any official scholarship system. Eligibility results are estimates based on published program rules as of the [SCHOOL YEAR] school year and may be incomplete or out of date. **Always confirm purchases and requirements against your program's official Purchasing Guide and Family Handbook before buying or submitting.** You are responsible for your own submissions and records.

---

## 17. Acceptance criteria / definition of done

- A parent can add multiple students across FES-UA and PEP and switch between them.
- Scanning a receipt produces an editable, structured expense with the original image retained; OCR runs on-device with no network.
- Each expense shows an eligibility verdict appropriate to the student's program (e.g., a therapy on PEP reads Ineligible; a 2nd laptop within 2 years reads Needs Pre-Authorization), with a plain reason and citation.
- The "Can I buy this?" checker works without a receipt.
- A claim can move through the full lifecycle with status history; On-Hold starts a 30-day reminder; denial reasons surface specific fixes.
- "Ready to Submit" is gated until the documentation checklist is complete.
- The parent can export a per-expense submission-package PDF (image + structured summary + checklist), a claim PDF, and a CSV.
- Deadline and On-Hold reminders fire as local notifications.
- All data is local by default; iCloud backup is opt-in; app-lock works; export-all and delete-all work; no third-party trackers are present.
- Rules are loaded from versioned JSON, not hard-coded; the ruleset's school year is visible in the UI.
- Eligibility engine and lifecycle state machine have passing unit tests.

---

## 18. Out of scope (v1) / future ideas

Out of scope: any official-portal integration/auto-submit; real account-balance retrieval; Android/web; family-sharing multi-parent accounts. Future: remote ruleset updates, Spanish localization, OCR auto-categorization model, shared exports with a co-parent, provider-credential lookup helper.

---

## 19. Appendix A — Seed ruleset JSON (starter; verify & expand against current Purchasing Guides)

```json
{
  "schoolYear": "2026-27",
  "sourceVersion": "seed-draft-1",
  "lastUpdated": "2026-05-23",
  "disclaimer": "Estimates only. Confirm against the official Purchasing Guide and Family Handbook.",
  "deadlines": {
    "spendWindowStart": "--07-01",
    "spendWindowEnd": "--06-30",
    "reimbursementSubmissionDeadline": "--07-31",
    "onHoldDays": 30,
    "reviewDaysMax": 60,
    "disbursementDates": ["--02-01", "--04-01", "--08-01", "--11-01"]
  },
  "globalRules": {
    "deviceReplacementYears": 2,
    "peripheralPreAuthOver": 50.00,
    "balanceCapNoNewFundingFESUA": 50000.00
  },
  "categories": [
    {
      "key": "curriculum_materials",
      "displayName": "Curriculum & Instructional Materials",
      "programs": ["fesUA", "pep"],
      "eligibility": "eligible",
      "keywords": ["curriculum", "workbook", "textbook", "lesson", "instructional"],
      "requiresStudentName": false,
      "sourceCitation": "Purchasing Guide — Instructional Materials"
    },
    {
      "key": "books",
      "displayName": "Books",
      "programs": ["fesUA", "pep"],
      "eligibility": "eligible",
      "keywords": ["book", "reader", "novel"],
      "caps": {"frequency": "none", "annualAmount": "none"},
      "sourceCitation": "Purchasing Guide — Books"
    },
    {
      "key": "device",
      "displayName": "Digital Device (laptop/tablet/e-reader/etc.)",
      "programs": ["fesUA", "pep"],
      "eligibility": "eligible",
      "keywords": ["laptop", "chromebook", "tablet", "ipad", "e-reader", "desktop", "computer"],
      "requiresPreAuthIfWithinDeviceWindow": true,
      "sourceCitation": "Purchasing Guide — Digital Devices (1 per 2 years)"
    },
    {
      "key": "therapy_specialized",
      "displayName": "Specialized Therapy (ABA/Speech/OT/PT/etc.)",
      "programs": ["fesUA"],
      "eligibility": "eligible",
      "keywords": ["aba", "speech", "occupational therapy", "physical therapy", "counseling", "psychotherapy", "vision therapy"],
      "requiresStudentName": true,
      "requiresProviderCredentials": true,
      "ineligibleForProgram": {"pep": "PEP does not cover specialized therapies"},
      "sourceCitation": "FES-UA — Specialized Services"
    },
    {
      "key": "tutoring",
      "displayName": "Tutoring",
      "programs": ["fesUA", "pep"],
      "eligibility": "eligible",
      "keywords": ["tutor", "tutoring"],
      "requiresStudentName": true,
      "requiresProviderCredentials": true,
      "sourceCitation": "Purchasing Guide — Tutoring"
    },
    {
      "key": "exam_fees",
      "displayName": "Standardized / AP / Industry Exam Fees",
      "programs": ["fesUA", "pep"],
      "eligibility": "eligible",
      "keywords": ["ap exam", "psat", "sat", "act", "clep", "industry certification", "test fee"],
      "sourceCitation": "Purchasing Guide — Testing"
    },
    {
      "key": "florida_prepaid",
      "displayName": "Florida Prepaid / College Savings Contribution",
      "programs": ["fesUA", "pep"],
      "eligibility": "directPayOnly",
      "keywords": ["florida prepaid", "college savings"],
      "notes": "Direct-pay only; NOT reimbursable.",
      "sourceCitation": "Purchasing Guide — Florida Prepaid"
    },
    {
      "key": "theme_park",
      "displayName": "Educational Theme-Park Admission",
      "programs": ["fesUA", "pep"],
      "eligibility": "needsPreAuth",
      "keywords": ["theme park", "zoo", "museum", "aquarium", "admission"],
      "caps": {"maxAmount": 299.00, "perStudentPerClaim": true, "paidInFull": true},
      "requiresStudentName": true,
      "requiresEducationalBenefitForm": true,
      "sourceCitation": "Purchasing Guide — Field Trips/Admissions"
    },
    {
      "key": "ineligible_transport",
      "displayName": "Transportation / Gas / Mileage",
      "programs": ["fesUA", "pep"],
      "eligibility": "ineligible",
      "keywords": ["gas", "fuel", "mileage", "uber", "lyft", "airfare", "transportation"],
      "sourceCitation": "Purchasing Guide — Prohibited"
    },
    {
      "key": "ineligible_food_lodging",
      "displayName": "Food / Lodging / Meals",
      "programs": ["fesUA", "pep"],
      "eligibility": "ineligible",
      "keywords": ["lunch", "meal", "food", "hotel", "lodging", "snack"],
      "sourceCitation": "Purchasing Guide — Prohibited"
    },
    {
      "key": "ineligible_medical",
      "displayName": "Medical Services / Devices",
      "programs": ["fesUA", "pep"],
      "eligibility": "ineligible",
      "keywords": ["hearing aid", "mobility aid", "wheelchair", "medical", "non-prescription glasses"],
      "notes": "PEP allows one prescription eyeglasses pair/year — handle as exception.",
      "sourceCitation": "Purchasing Guide — Prohibited"
    },
    {
      "key": "ineligible_tickets",
      "displayName": "Concert / Sporting / Resale Tickets, Arcades",
      "programs": ["fesUA", "pep"],
      "eligibility": "ineligible",
      "keywords": ["concert", "sporting event", "resale", "stubhub", "arcade", "ticket reseller"],
      "sourceCitation": "Purchasing Guide — Prohibited"
    },
    {
      "key": "ineligible_household",
      "displayName": "General Household Items / TVs over 55\"",
      "programs": ["fesUA", "pep"],
      "eligibility": "ineligible",
      "keywords": ["television over 55", "furniture (home)", "appliance", "household"],
      "sourceCitation": "Purchasing Guide — Prohibited"
    }
  ]
}
```

## Appendix B — Seed eligibility test cases (drive unit tests)

| Item described | Program | Path | Expected result |
|---|---|---|---|
| "ABA therapy session, provider license #" | FES-UA | reimbursement | Likely Eligible (needs student name + credentials) |
| "ABA therapy session" | PEP | reimbursement | Ineligible (PEP excludes therapies) |
| "Chromebook" (no prior device) | PEP | reimbursement | Likely Eligible |
| "Chromebook" (laptop bought 8 months ago) | PEP | reimbursement | Needs Pre-Authorization (2-year device rule) |
| "Florida Prepaid contribution" | FES-UA | reimbursement | Ineligible for reimbursement (direct-pay only) |
| "Gas for co-op drive" | FES-UA | reimbursement | Ineligible (transportation) |
| "Zoo admission $250, one student" | PEP | reimbursement | Needs Pre-Authorization + Educational Benefit Form |
| "Theme park annual pass $480" | PEP | reimbursement | Ineligible/Needs review (over $299 cap) |
| "Math curriculum workbook" | PEP | reimbursement | Likely Eligible |
| "School lunch fee" | FES-UA | reimbursement | Ineligible (food) |

## Appendix C — Glossary

**ESA** Education Savings Account · **FES-UA** Family Empowerment Scholarship – Unique Abilities · **PEP** Personalized Education Program · **SFO** Scholarship Funding Organization (Step Up For Students; AAA Scholarship Foundation) · **EMA** Education Market Assistant (Step Up's parent portal) · **MyScholarShop** approved marketplace inside EMA · **Direct pay** vendor/provider billed straight from the account · **Reimbursement** parent pays out of pocket then claims back · **Proof of payment** separate evidence the receipt was paid · **Pre-authorization** advance approval required for certain items.

## Appendix D — Source references (for the developer to re-verify rules each school year)

- Step Up For Students — Unique Abilities (FES-UA): https://www.stepupforstudents.org/scholarships/unique-abilities/
- Step Up For Students — Personalized Education Program (PEP): https://www.stepupforstudents.org/scholarships/personalized-education-program/
- Step Up For Students — Spend (Marketplace / reimbursement / deadlines): https://www.stepupforstudents.org/scholarships/private-school/spend/
- Step Up For Students — MyScholarShop: https://www.stepupforstudents.org/scholarships/myscholarshop/
- FES-UA Purchasing Guide (current): https://go.stepupforstudents.org/hubfs/GUIDES/FES-UA-Purchasing-Guide.pdf
- PEP Purchasing Guide (current): https://go.stepupforstudents.org/hubfs/GUIDES/PEP-Purchasing-Guide.pdf
- FES-UA Parent Handbook: https://go.stepupforstudents.org/hubfs/HANDBOOKS/Parent%20Handbooks/FES-UA-Parent-Handbook.pdf
- PEP Family Handbook: https://go.stepupforstudents.org/hubfs/HANDBOOKS/Parent%20Handbooks/PEP-Family-Handbook.pdf
- How to Request Reimbursement in EMA (PDF): https://go.stepupforstudents.org/hubfs/Scholarship%20Info/Reimbursement-How-to-Submit-Final.pdf
- Guardians' Reimbursement Guide (denial reasons / proof of payment): https://go.stepupforstudents.org/hubfs/Scholarship%20Info/Guardians%20Reimbursement%20Guide.pdf
- FLDOE — Family Empowerment Scholarship: https://www.fldoe.org/schools/school-choice/k-12-scholarship-programs/fes/
- FLDOE — FES-UA FAQ (PDF): https://www.fldoe.org/core/fileparse.php/18766/urlt/FES-UA-FAQs.pdf
- AAA Scholarship Foundation — FES-UA (FL): https://www.aaascholarships.org/parents/florida/florida-disability-based-scholarships-fes-ua-formerly-gardiner-and-mckay/

> **Builder note:** Figures, caps, and deadlines above reflect 2024-26 program documents and may shift for 2026-27. Treat all rule values as data to confirm against the live Purchasing Guides before each school year; the app's ruleset JSON is the single place to update them.
