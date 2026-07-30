# Decision Log

## 2026-07-30 — Gmail-first automatic import

Decision: Build Gmail as the only automatic provider in the first release.

Reason: U.S. research places Gmail far ahead of other consumer mailbox
providers, while every additional provider introduces separate authentication,
privacy, implementation, and support costs.

## 2026-07-30 — Universal manual fallback

Decision: Keep camera, Photos, Files, and Share as first-class paths.

Reason: Gmail use is not universal, people maintain multiple addresses, and
many retailer emails contain links rather than reimbursement-ready documents.

## 2026-07-30 — On-device polling

Decision: Scan on demand in v1 rather than operating Gmail push infrastructure.

Reason: Gmail push requires Google Cloud Pub/Sub and a backend. On-device
polling preserves ScholarKeep's current local-first posture and materially
reduces the security surface.

## 2026-07-30 — Parent review required

Decision: Never turn a detected message directly into a completed expense or
claim without review.

Reason: Receipt classification and scholarship-category inference are
probabilistic, while assignment to a student and reimbursement category can
affect eligibility.

## 2026-07-30 — No portfolio registry entry

Decision: Do not add ScholarKeep to the governed Jarvis portfolio control
system.

Reason: The workspace governance file limits that registry to named portfolio
products and excludes personal/household projects. This product work remains in
its own repository and operating folder.
