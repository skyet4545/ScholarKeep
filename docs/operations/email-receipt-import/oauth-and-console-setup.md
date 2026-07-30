# Google OAuth and Console Setup

The feature compiles and the rest of ScholarKeep remains usable without a
Google credential. Gmail connection is disabled until the configuration below
is completed.

## Google Cloud

1. Create or select a Google Cloud project owned by the ScholarKeep publisher.
2. Enable the Gmail API.
3. Configure the OAuth consent screen:
   - App name: `ScholarKeep`
   - Support email: the published ScholarKeep support address
   - Audience: External
   - Scope: `https://www.googleapis.com/auth/gmail.readonly`
4. Add the verified production homepage, privacy policy, and terms URLs.
5. Create an OAuth client:
   - Application type: iOS
   - Bundle ID: `com.carlosreyes.scholarkeep`
6. Submit the production app for Google's restricted-scope verification.

## Xcode configuration

Set the generated Info.plist value:

```text
SCHOLARKEEP_GOOGLE_CLIENT_ID = <ios-client-id>.apps.googleusercontent.com
```

The registered callback is:

```text
com.carlosreyes.scholarkeep:/oauth2redirect
```

The URL scheme `com.carlosreyes.scholarkeep` is declared by the app target.

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
