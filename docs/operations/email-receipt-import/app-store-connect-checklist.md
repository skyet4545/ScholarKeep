# App Store Connect release checklist

ScholarKeep 0.8.0 (build 16) adds an optional Gmail Receipt Inbox and improves
image/PDF receipt capture. The app remains useful without connecting Gmail.

## Before archiving

- Create an iOS OAuth client for ScholarKeep in Google Cloud.
- Register `com.carlosreyes.scholarkeep:/oauth2redirect`.
- Put the client ID in the release build setting
  `SCHOLARKEEP_GOOGLE_CLIENT_ID`. Never commit a client secret; an installed
  iOS app cannot keep one confidential.
- Complete the OAuth consent screen, authorize only
  `https://www.googleapis.com/auth/gmail.readonly`, and complete any Google
  verification required for production users.
- Exercise the new `ReceiptCandidate` model against the CloudKit development
  environment, then deploy its schema to production in CloudKit Console.
- Confirm the production privacy policy URL displays the July 30, 2026 Gmail
  disclosure.

## App Store Connect metadata

- Version: `0.8.0`
- Build: `16`
- Suggested subtitle: `Receipts organized for reimbursement`
- Suggested What’s New:

  > ScholarKeep can now find likely purchase receipts in an optional connected
  > Gmail account and place them in a private Receipt Inbox for your review.
  > You can also share or attach receipt images and PDFs, with on-device text
  > recognition helping fill in purchase details. ScholarKeep never submits a
  > receipt without your approval.

## App Review notes

- Gmail connection is optional and located at **More → Receipt Inbox**.
- The app requests read-only Gmail access. It does not send, delete, label, or
  mark email as read.
- A bounded scan retrieves likely purchase messages. Candidates are reviewed
  before they become draft expenses.
- Receipt OCR is performed on device.
- OAuth tokens are stored in the iOS Keychain and removed when the parent
  disconnects Gmail.
- The reviewer can test the rest of ScholarKeep without a Gmail account.
- If Google keeps the production OAuth app in test mode, provide a test-user
  Gmail account in App Review Information; do not place credentials in source.

## Submission checks

- Archive the Release configuration with the production Google client ID.
- Verify Sign in with Apple and iCloud entitlements remain present.
- Confirm Privacy Nutrition Label answers remain accurate. Gmail content is not
  sent to a ScholarKeep-operated server; saved records may sync through the
  user’s private iCloud database.
- Upload one build only after the local unit and UI tests pass.
- Do not submit until the Google OAuth production state and CloudKit production
  schema are ready.
