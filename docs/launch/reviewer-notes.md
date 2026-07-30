# App Review — Reviewer Notes + What's New (paste-ready)

## Reviewer Notes (App Store Connect → App Review Information → Notes)

```
ScholarKeep is a local-first record-keeping app for Florida ESA scholarship
families. No account or sign-in is required — launch the app and complete the
4-step onboarding (any name works for the student).

QUICK DEMO DATA: launch the app, complete onboarding with any student name,
then add a receipt via the + button (top right of Home) using any photo, or
type a purchase into the Check tab (e.g. "Chromebook $349") to see an
eligibility verdict with its Purchasing Guide citation.

SHARE EXTENSION TESTING: the app includes a Share Extension for importing
email receipts. To test: open Safari or Photos, tap Share on any image or
web page, select "ScholarKeep" from the share sheet, then return to the app —
an import review sheet appears on next foreground.

OPTIONAL GMAIL IMPORT: More → Receipt Inbox contains the optional Gmail
connection. It requests read-only Gmail access solely to find likely receipts
and invoices. It cannot send, delete, archive, label, or otherwise modify mail.
Messages are processed on-device and require parent review before import. The
feature remains disabled when this review build has no approved Google OAuth
test credential; camera, Photos, Files, and Share remain fully testable.

SUBSCRIPTIONS: Pro Monthly ($4.99) and Pro Yearly ($39.99) unlock PDF export,
CSV export, and year-end summaries. The free tier is fully functional for
eligibility checks, receipt tracking, claims, and reminders. Note: builds
installed before our public launch date include a complimentary "Beta
Founder" Pro entitlement — this is intentional (a thank-you to beta testers),
implemented locally via first-launch date, not a server flag.

PRIVACY: records are stored on-device (SwiftData) and sync only through the
user's own iCloud account via a CloudKit private database. We operate no
records or email-processing server. Gmail OAuth tokens remain in the iOS
Keychain and are excluded from SwiftData/iCloud. Sign in with Apple appears
only as an OPTIONAL item in Settings → Account.

NOT AFFILIATED with Step Up For Students, AAA Scholarship Foundation, or the
Florida DOE — the app states this prominently in onboarding, Settings, and
the app description. Eligibility verdicts cite the publicly published
Purchasing Guides and are labeled as estimates.
```

## What's New (first App Store release)

```
Welcome to ScholarKeep 1.0 — built by two Florida homeschool dads for their
own families, now ready for yours.

• Scan receipts in one tap (or forward them from Mail)
• Optionally connect Gmail to find likely receipts automatically
• Check eligibility instantly, with the official Purchasing Guide line cited
• Track every claim from draft to paid
• Export submission-ready PDFs before the July 31 deadline
• Syncs across iPhone and iPad through your own iCloud
• Works for FES-UA, FES-EO, and PEP

Everything stays in your hands. No accounts, no analytics, no data selling.
```

## Screenshot upload order (docs/launch/screenshots/, 1320×2868 = iPhone 6.9")

1. `01-dashboard.png` — balance hero + "Next cliff 17d" urgency + submission helper
2. `02-check.png` — the killer feature: cited eligibility verdicts (theme-park cap + ABA approval)
3. `03-claims.png` — claim statuses (Submitted / On hold / Paid)
4. `04-welcome.png` — onboarding hero with privacy trust strip

(First 3 appear on the App Store install sheet — order matters.)

## Regenerating screenshots

```bash
# Build for iPhone 17 Pro Max sim, then per screen:
xcrun simctl launch <SIM> com.carlosreyes.scholarkeep --demo --tab home   # or check / claims
xcrun simctl io <SIM> screenshot out.png
# Onboarding shot: launch with --reset instead of --demo
```

`--demo` seeds realistic sample data into an in-memory store (never touches real records) — also used for FPEA booth demos.
