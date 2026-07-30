# Product Requirements

## Problem

Florida ESA families lose receipts, cannot find detailed invoices later, and
discover missing documentation only after a reimbursement is placed on hold or
denied. Purchase evidence commonly arrives by email, but parents must manually
download, rename, and associate it with a student and claim.

## Users

The initial user is an adult parent or guardian administering one or more
Florida ESA scholarship students. ScholarKeep is not designed for children to
connect or search their mailboxes.

## Primary jobs

- Capture purchase evidence before it is lost.
- Reduce duplicate data entry from a receipt.
- Surface incomplete evidence before EMA/SMP submission.
- Preserve an auditable copy of the source receipt.
- Keep the parent in control of what becomes an expense.

## Functional requirements

### Universal capture

- Import a screenshot or receipt image from Photos.
- Scan a paper receipt with the camera.
- Import an image or PDF from Files.
- Receive an image, PDF, URL, or text through the iOS share sheet.
- Run images and rendered PDF pages through on-device Apple Vision OCR.
- Prefill vendor, purchase date, subtotal, tax, total, and line items.
- Require review before saving.

### Gmail connection

- Use browser-based Google OAuth with PKCE.
- Request read-only Gmail access.
- Never ask for or store a Google password.
- Store refresh and access tokens in the iOS Keychain.
- Let the parent disconnect and remove the local grant.
- Search a bounded recent window for likely purchase messages.
- Retrieve message bodies and receipt-like image/PDF attachments on-device.
- Deduplicate using Gmail message IDs.
- Show candidates in a Receipt Inbox before import.
- Permit rejection of false positives without deleting the email.

### Receipt Inbox

- Show pending, imported, and dismissed states.
- Display source, sender, subject, received date, and extracted amount.
- Allow selection of the scholarship student.
- Save the original receipt attachment when available.
- Preserve source-message context in expense notes.
- Never create an EMA/SMP submission automatically.

## Non-functional requirements

- Local-first and usable without Gmail.
- No ScholarKeep-operated mail-processing backend.
- No analytics or advertising SDK.
- OAuth failure must not block the rest of the app.
- All network failures must be recoverable with a retry.
- Candidate scanning must be explicitly initiated by the user in v1.
- The scan must be bounded by message count and time window.

## Success measures

Because the app currently has no analytics backend, initial validation is
qualitative and test-based:

- A parent can connect Gmail and see candidates in under two minutes.
- A representative emailed receipt imports without retyping vendor, date, and
  total.
- A screenshot imports through the same review path.
- Re-running a Gmail scan does not duplicate existing candidates.
- A disconnected or expired account fails safely and explains how to reconnect.
- No email is sent, altered, labeled, archived, or deleted.

## Later candidates

- Outlook/Hotmail through Microsoft Graph.
- Privacy-preserving background refresh.
- Step Up on-hold and denial message classification.
- Provider-specific parsers for high-volume merchants.
- A web or server push architecture only after demonstrated demand and a new
  security/privacy review.
