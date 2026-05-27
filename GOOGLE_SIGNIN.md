# Google Sign-In (iOS)

Mirrors Android `GOOGLE_SIGNIN.md` and `GoogleSignInClients.kt`.

## Env variables

| Variable | Purpose |
|----------|---------|
| `GOOGLE_WEB_CLIENT_ID` | OAuth **Web application** client id — passed as `serverClientID` so Google returns an ID token your backend can verify (`fash-auth-service` `GOOGLE_OAUTH_CLIENT_IDS`). |
| `GOOGLE_IOS_CLIENT_ID` | OAuth **iOS** client id for bundle `com.pc.fash-ios-mobile` (prod) or `com.pc.fash-ios-mobile.dev` (dev). Injected as `GIDClientID` and used in code. |

Set both in `env/dev.env` and `env/prod.env`, then run:

```powershell
python scripts/env_to_xcconfig.py
```

The script also derives `FASH_GOOGLE_URL_SCHEME` (`com.googleusercontent.apps.<prefix>`) for the OAuth redirect in `Info.plist`.

## Google Cloud Console

In project `fash-3526e` → **APIs & Services → Credentials**:

1. **Web application** — same id as `GOOGLE_WEB_CLIENT_ID` (already used by Android).
2. **iOS** — create one client per bundle id:
   - Dev: `com.pc.fash-ios-mobile.dev`
   - Prod: `com.pc.fash-ios-mobile`
3. Copy each iOS client id into the matching env file as `GOOGLE_IOS_CLIENT_ID`.

Auth-service must list the **Web** client id in `GOOGLE_OAUTH_CLIENT_IDS`.

## App flow

1. User taps **Google** on `LoginScreen`.
2. `GoogleSignInClients.signIn` presents the Google account picker (GoogleSignIn-iOS SDK).
3. ID token is sent to `POST /api/v1/auth/social-login` via `AuthRepository.socialLogin`.
4. Session is saved; `RootView.bootstrapSession()` runs onboarding gate like OTP login.
5. Logout calls `GIDSignIn.sharedInstance.signOut()` via `SocialAuthCacheClear`.

## Troubleshooting

- Button appears dimmed → `GOOGLE_IOS_CLIENT_ID` is empty or placeholder; fill env and regenerate xcconfig.
- Sign-in fails immediately → URL scheme / bundle id mismatch with the iOS OAuth client in GCP.
- API error after Google succeeds → check `GOOGLE_OAUTH_CLIENT_IDS` on auth-service matches `GOOGLE_WEB_CLIENT_ID`.

See also: [fash-android-mobile/GOOGLE_SIGNIN.md](../fash-android-mobile/GOOGLE_SIGNIN.md).
