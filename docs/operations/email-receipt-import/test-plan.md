# Test and Release Plan

## Automated tests

- Receipt subject/body classification.
- Currency and vendor extraction from email text.
- Gmail base64url decoding.
- Gmail multipart body and attachment parsing.
- Deduplication by provider plus message ID.
- Candidate lifecycle transitions.
- Shared image OCR parsing.
- PDF page rendering and parsing.
- OAuth state and PKCE helper behavior.
- Configuration-disabled behavior.

## Manual functional matrix

| Scenario | Expected result |
| --- | --- |
| No Google client ID | Gmail UI explains setup is unavailable; app remains usable |
| Connect approved Gmail account | Account email is displayed |
| User cancels OAuth | No account or token is retained |
| Scan recent mail | Pending receipt candidates appear |
| Scan twice | Existing Gmail messages are not duplicated |
| Candidate has PDF | PDF is preserved and fields are prefilled |
| Candidate has no attachment | Email text is preserved and missing proof is visible |
| Import candidate | Draft expense is created for selected student |
| Dismiss candidate | Email remains untouched; candidate leaves pending list |
| Disconnect Gmail | Local token is removed and future scans require reconnection |
| Share screenshot | OCR-prefilled receipt review appears |
| Share PDF | Rendered PDF text prefills the expense |

## Security checks

- Search build products and logs for OAuth tokens.
- Confirm tokens are absent from SwiftData/iCloud records.
- Confirm the app requests only `gmail.readonly`.
- Confirm Gmail messages are never modified.
- Confirm disconnect clears Keychain entries.
- Confirm OAuth response state is validated.

## Release gates

- Unit tests pass.
- UI tests for existing onboarding, students, checker, and settings pass.
- Archive succeeds with distribution signing.
- The new `ReceiptCandidate` CloudKit schema is exercised in development and
  deployed to production in CloudKit Console before release.
- Privacy policy and support pages are deployed before App Store submission.
- Google OAuth verification is approved or the feature remains limited to
  approved testers.
- App Store Connect privacy answers are reviewed and updated.
