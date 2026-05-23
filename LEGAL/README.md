# Legal docs — ScholarKeep

These are AI-drafted (Claude Opus 4.7) starting points. **Have a Florida lawyer review them before publishing**, especially if you're charging.

- `privacy-policy.md` — sane defaults for an app that stores everything locally, uses Sign in with Apple + StoreKit + Apple Vision + iCloud, and has no backend / no analytics / no third-party SDKs.
- `terms-of-service.md` — sane defaults including the subscription terms (Pro Monthly $4.99 + Pro Yearly $39.99, 7-day trial, Family Sharing, auto-renewal, Apple-managed billing, cancellation policy), a strong "not affiliated with FLDOE / Step Up / AAA / EMA" disclaimer, and a Florida-governing-law clause.

## Where you need to host these

Apple requires a **Privacy Policy URL** in App Store Connect (App Information). They also need a **Support URL** (can be a contact page). Submitting Pro subscriptions for review additionally needs a **Terms of Use URL**.

Two easy hosting options:

1. **GitHub Pages from this repo** — push the `LEGAL/` folder to a public branch, enable Pages on the branch's root, and the URLs become:
   - `https://<your-github-username>.github.io/ScholarKeep/LEGAL/privacy-policy`
   - `https://<your-github-username>.github.io/ScholarKeep/LEGAL/terms-of-service`
2. **Carrd / Netlify / GitHub Gist** — paste the markdown into a free static-site host, copy the resulting URLs.

Once hosted, paste the URLs into:

- **App Store Connect → App Information → Privacy Policy URL**
- **App Store Connect → App Information → Subscription Terms** (links to the Terms)
- **App Store Connect → App Information → Support URL** (any contact page; even a Notion page works)

## What to ask your lawyer to look at

1. The liability cap in §8 of the ToS ($20 or 12 months of subscription fees). That's a defensible cap for a $4.99/mo app but a Florida consumer-protection attorney should confirm it's enforceable for Florida residents.
2. The governing-law and venue clause (§11). Some jurisdictions limit consumers' ability to be bound to a specific venue.
3. The indemnification clause (§9). Sometimes consumer-protection statutes limit how broadly an indemnity can run.
4. The "not affiliated with Step Up / AAA / EMA" disclaimer (top of ToS and §1). If those organizations ever object, the language is what your lawyer will defend.
5. Whether you need to register as a "preparer" or fiduciary in Florida for any reason (probably not — the app is purely informational — but a Florida attorney will confirm).

## What's intentionally NOT in here

- DPA or GDPR-specific clauses. The app doesn't collect data; if you ever stand up a backend, add EU/UK clauses then.
- COPPA-specific compliance steps. The app is marketed to parents (adults), and we explicitly state we don't knowingly collect from kids under 13. If the marketing ever shifts toward kids using it directly, add COPPA flow.
- HIPAA. ESA therapy invoices can include health info, but they're stored only on-device and never transmitted, so HIPAA's "covered entity" obligations don't attach to us. A lawyer should confirm this is the right read for Florida.
- A formal arbitration clause. Florida law makes individual-action arbitration enforceable, but many indie devs skip it. Add if you want.
