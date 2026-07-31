# App Store Connect release checklist

ScholarKeep 0.8.0 (build 17) adds an optional Gmail Receipt Inbox and improves
image/PDF receipt capture. The app remains useful without connecting Gmail.

## TestFlight build 17 evidence

- Uploaded successfully to App Store Connect on July 31, 2026.
- TestFlight build ID: `c55db31d-7676-4227-9528-869048188e42`.
- Status: Testing; expires in 90 days.
- Internal groups: `Carlos (internal)`, `Guys`, and `Reyes Family`.
- Test notes describe Gmail connection, bounded receipt scanning, candidate
  review, draft creation, image/PDF capture, OCR, reconnection, and regression
  checks.
- Google OAuth test access includes `carlos.reyesiii@gmail.com`.
- CloudKit development and production currently expose only the built-in
  `Users` record type and no deployable schema changes. Validate real-device
  persistence and initialize/deploy the SwiftData record schema before any
  public App Store submission.

## Before archiving

- Confirm the `ScholarKeep iOS` OAuth client remains registered to bundle ID
  `com.carlosreyes.scholarkeep` and Team ID `846N5D6TMK`.
- Confirm the reversed-client-ID callback scheme remains registered in the app.
- Confirm the public iOS client ID remains in the release build setting
  `SCHOLARKEEP_GOOGLE_CLIENT_ID`. Never add a client secret; an installed iOS
  app cannot keep one confidential.
- Complete the OAuth consent screen, authorize only
  `https://www.googleapis.com/auth/gmail.readonly`, and complete any Google
  verification required for production users.
- Exercise the new `ReceiptCandidate` model against the CloudKit development
  environment, then deploy its schema to production in CloudKit Console.
- Confirm the production privacy policy URL displays the July 30, 2026 Gmail
  disclosure.

## App Store Connect metadata

- Version: `0.8.0`
- Build: `17`
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
