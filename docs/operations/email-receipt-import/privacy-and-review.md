# Privacy and Store Review

## Material privacy change

ScholarKeep's published policy currently says it does not connect to third-party
email or transmit records outside the device except through the user's private
iCloud account. Gmail import adds a user-directed connection to Google and must
be disclosed before release.

## Required disclosures

The updated policy must explain:

- Gmail connection is optional.
- ScholarKeep requests read-only access.
- The app searches and downloads likely receipt messages on the device.
- ScholarKeep cannot send, delete, archive, label, or modify mail.
- OAuth credentials are stored in Keychain.
- Imported receipts may sync through the user's private iCloud account.
- Disconnecting removes local credentials; the user can also revoke access in
  their Google Account.
- No mailbox data is sold, used for advertising, or used to train a generalized
  AI model.

## App Store review notes

Review notes should provide:

- A test account or a video when Google testing access cannot be shared.
- Exact navigation: `More -> Settings -> Connected email`.
- A statement that Gmail is optional and all core receipt features work through
  camera, Photos, Files, and Share.
- A description of the OAuth consent screen and read-only scope.
- A statement that ScholarKeep does not submit reimbursement claims.

## App privacy labels

Reassess App Store Connect privacy answers for:

- Email address.
- Emails or text messages.
- Photos or videos.
- Other user content.
- Identifiers.

The final answers depend on Apple's then-current definition of “collected,”
especially for data retrieved directly to the device and private CloudKit data.
Do not reuse the current “no data collected” answers without review.

## Google Limited Use

Public copy and internal handling must comply with Google API Services User Data
Policy and the additional requirements for restricted Gmail scopes. Access must
remain limited to the user-facing receipt organization feature.
