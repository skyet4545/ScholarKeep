# Technical Architecture

## Design choice

The first release is an on-device Gmail polling client. It does not use Gmail
push notifications or a ScholarKeep backend.

```text
Google OAuth in system browser
          |
          v
iOS Keychain (tokens)
          |
          v
Gmail REST API -- read only
          |
          v
Receipt detector and MIME parser
          |
          v
SwiftData ReceiptCandidate
          |
          v
Parent review -> Expense + Attachment
          |
          v
Private CloudKit database (existing ScholarKeep sync)
```

## Components

### `GoogleOAuthService`

- Uses `ASWebAuthenticationSession`.
- Generates a per-request PKCE verifier/challenge and state value.
- Exchanges authorization codes directly with Google's token endpoint.
- Stores tokens in Keychain.
- Refreshes access tokens when required.
- Requests only `gmail.readonly`.

### `GmailAPIClient`

- Lists candidate message identifiers using a bounded Gmail search query.
- Downloads message metadata, body parts, and image/PDF attachments.
- Does not call Gmail send, modify, label, archive, trash, or settings APIs.

### `EmailReceiptDetector`

- Scores message subject, sender, snippet, body text, receipt keywords, and
  currency patterns.
- Rejects obvious newsletters and unrelated security/account messages.
- Produces a candidate only above a conservative threshold.
- Leaves final classification to the parent.

### `ReceiptCandidate`

SwiftData model containing:

- Stable source message ID and provider.
- Sender, subject, received date, and text excerpt.
- Extracted vendor, purchase date, and total.
- Optional original PDF/image attachment in external storage.
- Pending/imported/dismissed lifecycle.

Gmail IDs are deduplicated in application logic because CloudKit does not
support SwiftData unique constraints reliably.

### Universal document reader

Images are recognized with Apple Vision. PDFs are rendered page-by-page using
PDFKit and then passed to the same OCR and parser. Shared images and PDFs use
this path before expense creation.

## Security boundaries

- Google passwords never enter ScholarKeep.
- OAuth tokens are not placed in SwiftData, UserDefaults, logs, or iCloud.
- Tokens are stored in Keychain as device-local credentials.
- Receipt records may sync through the user's existing private CloudKit
  database, matching ScholarKeep's current data model.
- The app never transmits mailbox contents to a developer-operated service.

## Operational constraints

- iOS background scheduling is not guaranteed, so v1 scans on demand.
- Gmail search is heuristic and can return false positives or miss unusual
  receipts.
- Emails containing only an account link may not contain reimbursement-ready
  evidence; ScholarKeep should identify them as incomplete rather than imply
  readiness.
- Google production OAuth verification is required before broad public use of
  the restricted Gmail read-only scope.
