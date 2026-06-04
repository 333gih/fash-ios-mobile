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

## Enable on Firebase (recommended)

1. Firebase Console → project `fash-3526e` → **Authentication** → **Sign-in method** → enable **Google**.
2. Re-download **GoogleService-Info.plist** for each iOS app (prod + dev). The file must include `CLIENT_ID` and `REVERSED_CLIENT_ID`.
3. Replace `Fash/GoogleService-Info.plist` and `Fash/GoogleService-Info-Dev.plist`, then run `python scripts/env_to_xcconfig.py` (or set `GOOGLE_IOS_CLIENT_ID` in `env/*.env`).

## Why Android works but iOS button is dimmed

| Platform | Minimum config |
|----------|----------------|
| **Android** | `GOOGLE_WEB_CLIENT_ID` only (already in `env/*.env`) |
| **iOS** | `GOOGLE_WEB_CLIENT_ID` **and** `GOOGLE_IOS_CLIENT_ID` (or `CLIENT_ID` inside bundled `GoogleService-Info.plist`) |

Plist chỉ có FCM (`GOOGLE_APP_ID`, `ANDROID_CLIENT_ID`) **không đủ** — phải bật **Google** trong Firebase Authentication cho app iOS rồi tải lại plist; file mới có `CLIENT_ID` + `REVERSED_CLIENT_ID`.

Kiểm tra nhanh (PowerShell):

```powershell
Select-String -Path Fash\GoogleService-Info.plist -Pattern "CLIENT_ID"
```

Nếu không thấy `CLIENT_ID` → làm bước **Enable on Firebase** bên dưới.

### GitHub Actions / TestFlight

1. Cập nhật secret `GOOGLE_SERVICE_INFO_PLIST_BASE64` = plist prod **có** `CLIENT_ID`.
2. (Tuỳ chọn) Thêm secret `GOOGLE_IOS_CLIENT_ID` = iOS OAuth client id — workflow sẽ inject vào build CI.
3. Workflow in cảnh báo nếu plist sau decode vẫn thiếu `CLIENT_ID`.

## Troubleshooting

- Button appears dimmed → `GOOGLE_IOS_CLIENT_ID` / plist `CLIENT_ID` is missing; follow **Enable on Firebase** above. Tap button shows `login_google_ios_setup` message.
- Sign-in fails immediately → URL scheme / bundle id mismatch with the iOS OAuth client in GCP.
- API error after Google succeeds → check `GOOGLE_OAUTH_CLIENT_IDS` on auth-service matches `GOOGLE_WEB_CLIENT_ID`.

See also: [fash-android-mobile/GOOGLE_SIGNIN.md](../fash-android-mobile/GOOGLE_SIGNIN.md), [APPLE_SIGN_IN.md](./APPLE_SIGN_IN.md).
