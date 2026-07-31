# Google OAuth and Console Setup

ScholarKeep is configured with its public iOS OAuth client. Gmail connection
remains limited to explicit test users until the Google consent screen is ready
for production.

## Google Cloud

1. Google Cloud project: `ScholarKeep` (`scholarkeep-receipts`).
2. Gmail API: enabled.
3. OAuth consent screen:
   - App name: `ScholarKeep`
   - Support email: the published ScholarKeep support address
   - Audience: External
   - Scope: `https://www.googleapis.com/auth/gmail.readonly`
4. Before production verification, add the verified production homepage,
   privacy policy, and terms URLs.
5. iOS OAuth client: `ScholarKeep iOS`
   - Application type: iOS
   - Bundle ID: `com.carlosreyes.scholarkeep`
   - Team ID: `846N5D6TMK`
   - Client ID: `277822482276-g1pjqj5i0j5da69jnrt1pu2u2d8iq7v9.apps.googleusercontent.com`
6. Before public release, submit the app for Google's restricted-scope
   verification.

## Xcode configuration

Set the generated Info.plist value:

```text
SCHOLARKEEP_GOOGLE_CLIENT_ID = 277822482276-g1pjqj5i0j5da69jnrt1pu2u2d8iq7v9.apps.googleusercontent.com
```

The registered callback is:

```text
com.googleusercontent.apps.277822482276-g1pjqj5i0j5da69jnrt1pu2u2d8iq7v9:/oauth2redirect
```

The reversed-client-ID URL scheme
`com.googleusercontent.apps.277822482276-g1pjqj5i0j5da69jnrt1pu2u2d8iq7v9`
is declared by the app target.

Do not commit refresh tokens, access tokens, downloaded OAuth JSON files, or a
client secret. An installed iOS OAuth client is public by design and does not
rely on a client secret.

## Test users

While the OAuth consent screen is in testing mode, add only explicit ScholarKeep
test accounts. Testing-mode refresh-token behavior may differ from a verified
production app, so release testing must include token refresh and reconnection.

## Verification evidence package

Google may require:

- A public homepage under a verified domain.
- Privacy policy and terms links.
- A demonstration video of the connect, scan, import, and disconnect flows.
- An explanation that email data is processed on-device.
- Justification for `gmail.readonly`: receipt bodies and attachments are
  required; Gmail metadata alone cannot provide them.
- Confirmation that ScholarKeep does not sell, advertise against, or train
  generalized models on mailbox data.
