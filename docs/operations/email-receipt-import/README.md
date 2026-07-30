# ScholarKeep Email Receipt Import

This folder is the operating record for ScholarKeep's Gmail-first receipt
capture feature.

## Product outcome

Parents can:

1. Connect a Gmail account with Google's OAuth consent flow.
2. Scan recent mail for likely receipts without giving ScholarKeep a password.
3. Review detected receipts before anything is added to their records.
4. Assign a receipt to a student and save it as a draft expense.
5. Use the same review pipeline for screenshots, receipt photos, PDFs, and
   content shared from Mail, Gmail, Safari, or Files.

The first release deliberately does not:

- Send or modify email.
- Upload mailbox data to a ScholarKeep-operated server.
- Submit claims to EMA, SMP, Step Up For Students, or another SFO.
- Promise uninterrupted background mailbox monitoring.
- Support Yahoo, Outlook, iCloud Mail, or generic IMAP automatically.

## Operating documents

- [Product requirements](product-requirements.md)
- [Technical architecture](architecture.md)
- [Google OAuth and console setup](oauth-and-console-setup.md)
- [Privacy and store review](privacy-and-review.md)
- [Test and release plan](test-plan.md)
- [App Store Connect checklist](app-store-connect-checklist.md)
- [Decision log](decision-log.md)

## Source and branch

- Product repository: `https://github.com/skyet4545/ScholarKeep`
- Feature branch: `codex/gmail-receipt-import`
- Bundle identifier: `com.carlosreyes.scholarkeep`
- Deployment target: iOS/iPadOS 17+

## Current implementation status

The code is designed so that photo, PDF, and share-sheet capture work without a
Google credential. Gmail connection becomes available when the production iOS
OAuth client ID is placed in the generated Info.plist configuration described
in `oauth-and-console-setup.md`.
