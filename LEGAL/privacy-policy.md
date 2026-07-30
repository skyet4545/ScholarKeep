# Privacy Policy — ScholarKeep

**Effective date:** May 23, 2026
**Last updated:** July 30, 2026

This Privacy Policy explains what data the ScholarKeep mobile application ("ScholarKeep", "the app", "we", "us", "our") collects, stores, and shares. ScholarKeep is operated by **Carlos Reyes** ("we", "our") as an independent iOS application available through the Apple App Store.

> **Plain English summary.** ScholarKeep is local-first. We do not operate servers that hold your records, sell your data, or use it for advertising. If you optionally connect Gmail, ScholarKeep uses Google's authorization screen to receive read-only access and searches for likely receipts on your device. Imported records may sync through your private iCloud account.

---

## 1. The information we do NOT collect

ScholarKeep does not:

- collect or transmit usage analytics
- include any third-party SDKs that collect data
- track you across other apps or websites
- send your records, receipts, claims, providers, or personal information to any server we operate (we don't operate any)
- sell, rent, license, or share your information with any third party
- use your data for advertising of any kind

We do not have a backend. There is no ScholarKeep-operated records cloud. Your records live on your device and in your personal iCloud account when CloudKit sync is available. Optional Gmail access connects your device directly to Google's Gmail API.

## 2. The information ScholarKeep stores locally on your device

All of the following is stored exclusively in the app's private container on your device:

- Student profiles you create (name, scholarship program, SFO, grade level, county, school year, optional award amount, optional SLP-approved date for PEP)
- Expenses you record (vendor, date, amounts, payment method, eligibility result, attachments, notes)
- Line items extracted by on-device OCR from receipts you scan or import
- Receipt images and proof-of-payment files you attach
- Providers you save (name, license number, type, license state)
- Pre-authorization requests you track
- Refunds you log
- Balance ledger entries you record
- Claims you create and their status history
- Possible receipt messages found through an optional Gmail connection, including sender, subject, message excerpt, extracted purchase details, and an image or PDF attachment when present

ScholarKeep does not transmit this information to a developer-operated server. Records may sync through your private iCloud account as described below.

## 3. Sign in with Apple

ScholarKeep uses **Sign in with Apple** to gate access to the app. When you sign in, Apple shares with the app a stable identifier (a long opaque string unique to ScholarKeep + your Apple ID), and — only the very first time, only if you choose — your name and a relay email address. We store this identifier in your device's local preferences and use it solely to verify, on each launch, that the current Apple ID still owns the account. The identifier never leaves your device. Apple may transmit information as part of the sign-in flow under Apple's own privacy practices (https://www.apple.com/legal/privacy/).

## 4. Optional Gmail receipt import

If you choose to connect Gmail, ScholarKeep opens Google's system-browser authorization flow and requests the read-only `gmail.readonly` permission. ScholarKeep never receives your Google password and cannot send, delete, archive, label, or modify email.

The app searches a bounded set of recent messages for likely receipts and invoices. Message text and image/PDF attachments needed for this feature are downloaded directly from Google to your device and analyzed there. Possible receipts remain in a review inbox until you import or dismiss them.

OAuth access and refresh tokens are stored in the iOS Keychain. They are not stored in ScholarKeep's SwiftData database or iCloud. You can disconnect Gmail inside ScholarKeep and can independently revoke ScholarKeep in your Google Account. Google's privacy practices apply to the Gmail service and authorization flow.

ScholarKeep does not sell Gmail data, use it for advertising, or use it to train a generalized artificial-intelligence model.

## 5. Subscriptions (StoreKit 2)

Pro is delivered as an in-app subscription processed by **Apple via StoreKit 2**. When you subscribe or restore purchases, Apple handles payment, taxation, and billing. The app receives a StoreKit transaction object locally and checks subscription entitlement on-device. Apple may collect payment and account information under Apple's own terms; we do not.

## 6. On-device OCR (Apple Vision)

When you scan a receipt, ScholarKeep uses **Apple Vision** to extract text on the device itself. The receipt image is **not transmitted off the device** for OCR. The image and extracted text remain in the app's local container.

## 7. Notifications (UserNotifications)

If you opt in to reminders, ScholarKeep schedules **local notifications** for deadlines, on-hold clocks, and device-window dates. These are scheduled by iOS on your device. We do not run a push notification server; there are no remote pushes.

## 8. iCloud sync

ScholarKeep records are synced through your personal iCloud account using Apple's private CloudKit database when you are signed in to iCloud. The data is encrypted in transit by Apple and stored under your Apple ID. Gmail OAuth tokens are excluded from SwiftData and do not sync through CloudKit. You can remove ScholarKeep iCloud data through your iCloud account.

## 9. Diagnostics (MetricKit)

iOS may share with us, on Apple's terms, aggregated and anonymized performance and crash metrics via the **MetricKit** system framework. These payloads do not contain your records and are written to a local diagnostics folder. We do not transmit them to a server (there is no server).

## 10. Children's privacy

ScholarKeep is designed for parents and guardians who manage Florida ESA scholarships for children. It is intended for use by **adults**. ScholarKeep does not knowingly collect personal information from children under 13. If you believe a child has provided information through ScholarKeep, contact us and we will help you remove the affected account from the device.

## 11. Your choices and rights

Because all your ScholarKeep records remain on your device, you control them directly:

- **Access and export:** Settings → Export all expenses (CSV).
- **Deletion:** Settings → Delete all data on this device (double-confirmation required).
- **Sign-out:** Settings → Account → Sign out. Removes the Apple credential link; SwiftData remains on disk until you sign back in or delete the app.
- **Disconnect Gmail:** Receipt Inbox → Disconnect Gmail. Removes local Gmail credentials. You may also revoke access through your Google Account.
- **App removal:** Deleting the app from iOS removes all locally-stored ScholarKeep data.

If iCloud backup is enabled, you may additionally remove ScholarKeep data through your iCloud account at iCloud.com or via Settings → [your name] → iCloud → Manage Storage.

## 12. Other services we do not use

ScholarKeep does **not** integrate, embed, or transmit data to:

- Google Analytics, Firebase Analytics, Mixpanel, Amplitude, Segment, or any analytics service
- Facebook, Meta, TikTok, Google Ads, or any advertising network
- Sentry, Bugsnag, Crashlytics, or any third-party crash reporting tool
- Step Up For Students, AAA Scholarship Foundation, EMA, SMP, MyScholarShop, Tipalti, FLDOE, or any state of Florida system

ScholarKeep is a personal record-keeping tool. The official record of your scholarship account lives in the scholarship organization's portal; ScholarKeep does not interact with it.

Google Gmail is used only when a parent explicitly connects it for read-only receipt discovery, as described in Section 4.

## 13. Changes to this policy

We may update this policy when we change how the app handles data. The "Last updated" date at the top reflects the most recent revision. Material changes will be highlighted in the next app release notes.

## 14. Contact

Questions about this policy? Email **carlos.reyesiii@gmail.com**.

ScholarKeep · Carlos Reyes · Florida, USA
