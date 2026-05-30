# Push notifications (iOS) — cùng API với Android

iOS **không gọi APNs trực tiếp**. Backend Fash gửi qua **Firebase Cloud Messaging (FCM)**; trên iPhone, FCM dùng APNs làm transport. App iOS vẫn đăng ký token qua **cùng endpoint** với Android:

`POST {AUTH_SERVICE}/api/v1/auth/fcm/register`

```json
{
  "fcm_token": "<FCM registration token>",
  "device_platform": "ios",
  "client_locale": "vi"
}
```

Bearer JWT bắt buộc (sau login). Backend lưu vào bảng `fcm_tokens` — xem `docs/INTERVIEW-NOTIFICATION-TECHNICAL.md` §10–11.

## Luồng end-to-end (giống Android)

1. App cấu hình Firebase (`GoogleService-Info.plist`).
2. Xin quyền notification → đăng ký APNs.
3. Firebase SDK trả **FCM token** (không phải raw APNs token).
4. Sau login, app gọi `POST /auth/fcm/register` với Bearer JWT.
5. Server (notification-service) gửi push qua FCM Admin SDK → APNs → iPhone.

## Bước 1 — Firebase Console (project `fash-3526e`)

1. [Firebase Console](https://console.firebase.google.com/) → project **fash-3526e** (cùng project Android).
2. **Add app → iOS** — tạo **2 app** nếu build cả dev + prod:
   - `com.pc.fash-ios-mobile.dev` (Fash-Dev)
   - `com.pc.fash-ios-mobile` (Fash-Prod)
3. Tải **`GoogleService-Info.plist`** → copy thành `Fash/GoogleService-Info.plist` (xem `GoogleService-Info.plist.example`).
   - **TestFlight (CI):** lưu bản prod trong `secrets/GoogleService-Info.plist`, đẩy secret `GOOGLE_SERVICE_INFO_PLIST_BASE64` qua `scripts/push_github_ios_secrets.ps1` (xem `docs/CI.md`).
4. **Project settings → Cloud Messaging → Apple app configuration**:
   - Upload **APNs Authentication Key** (`.p8` từ Apple Developer → Keys → Apple Push Notifications service).

## Bước 2 — Apple Developer

1. App ID bật capability **Push Notifications**.
2. Provisioning profile include push entitlement.
3. `Fash/Fash.entitlements` có `aps-environment` (development / production).

## Bước 3 — Code iOS (trong repo)

| File | Vai trò |
|------|---------|
| `PushNotificationCoordinator.swift` | Permission, APNs register, FCM token |
| `FcmTokenRegistrar.swift` | `AuthRepository.registerFcm` + JWT refresh |
| `AppDelegate.swift` | APNs token → FCM |
| `FashFirebaseMessagingService.swift` | Parse payload, deep link |
| `RootView.bootstrapSession` | Register sau login |

Trigger giống Android `MainActivity`: sau session hợp lệ → `registerCurrentTokenIfSession()`; token refresh → register lại.

## Bước 4 — Build & test

```bash
python scripts/env_to_xcconfig.py
xcodegen generate
```

Test trên **thiết bị thật**. Simulator hỗ trợ push hạn chế.

## Payload server (parity Android)

| Key | Mục đích |
|-----|----------|
| `title`, `body` | Tray / in-app banner |
| `user_notification_id` | Inbox detail |
| `deep_link` | `fash://inbox/{uuid}` |
| `inbox_refresh=1` | Refetch unread |
| `recipient_user_id` | Multi-account |

## Troubleshooting

| Triệu chứng | Kiểm tra |
|-------------|----------|
| Log `GoogleService-Info.plist missing` | Thêm plist từ Firebase |
| Register 401 | JWT — registrar retry refresh |
| Register OK, không push | APNs key trên Firebase; bundle id; prod vs dev |
| Chỉ Android nhận | `device_platform: ios`; FCM iOS token |

Env dùng chung Android: `AUTH_SERVICE_BASE_URL`, `AUTH_FCM_REGISTER_PATH`.
