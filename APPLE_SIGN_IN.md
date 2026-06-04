# Sign in with Apple (iOS)

## App (Xcode / Apple Developer)

1. [Apple Developer](https://developer.apple.com) → **Identifiers** → App ID `com.pc.fash-ios-mobile` (và `.dev` nếu dùng Fash-Dev).
2. Bật capability **Sign in with Apple** (đã có trong `Fash/Fash-Prod.entitlements` và `Fash-Dev.entitlements`).
3. Provisioning profile App Store / Development phải include capability này (tạo lại profile sau khi bật).

## Auth service (bắt buộc để đăng nhập thành công)

Trên `fash-auth-service` (prod / staging):

```env
APPLE_SIGN_IN_BUNDLE_IDS=com.pc.fash-ios-mobile,com.pc.fash-ios-mobile.dev
```

Chạy migration `0011_apple_sign_in.up.sql` nếu chưa có cột `apple_user_id`.

Sau deploy, `POST /api/v1/auth/social-login` với `provider=apple` và `providerToken=<identityToken>` sẽ verify JWT với Apple JWKS.

## Kiểm tra trên thiết bị

- Cần đăng nhập **Apple ID** trên iPhone (Settings → Apple Account).
- Simulator: **Settings → Apple Account** (hoặc đăng nhập trong Simulator menu).
- Nếu bấm nút Apple không hiện sheet: cập nhật build mới nhất; lỗi sẽ hiện dialog (không im lặng).

## Troubleshooting

| Triệu chứng | Nguyên nhân thường gặp |
|-------------|-------------------------|
| Không hiện sheet Apple | App chưa foreground / thiếu window — đã xử lý trong `AppleSignInClients`. |
| Sheet hiện, sau đó lỗi API | `APPLE_SIGN_IN_BUNDLE_IDS` sai hoặc auth-service chưa deploy Apple verifier. |
| Lỗi “not handled” | Capability chưa có trên profile ký app. |

Xem thêm: `fash-auth-service/.env.example` → `APPLE_SIGN_IN_BUNDLE_IDS`.
