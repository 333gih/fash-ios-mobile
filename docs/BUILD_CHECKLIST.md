# Checklist build iOS — tránh lỗi CI / TestFlight

Dùng checklist này **trước mỗi push** lên `releases/*` (TestFlight) hoặc `develop` / `main` (build simulator).

> **Entry point (Cursor / không Mac):** [CURSOR_DEVELOPMENT.md](./CURSOR_DEVELOPMENT.md) · [CODE_CONVENTIONS.md](./CODE_CONVENTIONS.md) · [CI_BUDGET.md](./CI_BUDGET.md) · [../AGENTS.md](../AGENTS.md)

> **Lưu ý:** Script `validate_swift_syntax.py` bắt được một phần lỗi cú pháp, nhưng **không thay thế** `xcodebuild archive`. Release CI dùng Xcode 26 + Swift 6 strict hơn — luôn chạy đủ bước bên dưới.

---

## 1. Trước khi code

- [ ] Đọc convention hiện có trong file lân cận (tên, `@MainActor`, closure `@escaping`, parser JSON…).
- [ ] Nếu thêm chuỗi UI: sync từ Android hoặc cập nhật đủ `vendor/`, `Localizable.strings`, `L10n.swift` (xem [scripts/README.md](../scripts/README.md)).
- [ ] Nếu thêm file Swift mới: đảm bảo nằm dưới `Fash/` — XcodeGen quét theo `project.yml`, không cần sửa pbxproj tay.

---

## 2. Kiểm tra local (bắt buộc trước push)

Chạy trên máy có Python 3 (Windows / Mac đều được):

```bash
cd fash-ios-mobile

# Bước CI chạy trong Prepare Xcode project
bash scripts/ci_validate_i18n.sh
bash scripts/ci_swift_compile_preflight.sh
python scripts/validate_swift_syntax.py
```

- [ ] Cả 3 lệnh trên exit `0` (in `OK: ...`).
- [ ] Nếu có Mac: chạy thêm `bash scripts/build_mac.sh Fash-Prod` hoặc archive local với scheme release.

**Trên Windows (không có Xcode):** chạy `.\scripts\check_before_push.ps1` (gộp 3 lệnh trên) + review checklist mục 3–6.

---

## 3. Swift — cú pháp & style (script bắt được)

| Quy tắc | Sai ❌ | Đúng ✅ |
|--------|--------|---------|
| `guard` phải có `else` trước `{` | `guard x { return }` | `guard x else { return }` |
| Không trailing comma trước `)` (Swift 5.9) | `foo(a, b,)` | `foo(a, b)` |
| Token `FashTypography.*` / `FashColors.*` phải tồn tại | `FashTypography.headingX` (không có) | Dùng token trong `FashTypography.swift` / `Color.swift` |
| Cân bằng `{` / `}` | thiếu `}` | đếm brace trước khi commit |
| Không trùng chữ ký `func` trong cùng type | hai `func load()` giống params | đổi tên hoặc gộp logic |

---

## 4. Swift — extension & access control

`private` trong Swift = **file-scoped**, không phải type-scoped.

- [ ] **Không** tạo `Type+Something.swift` rồi gọi `private func` / `private let client` từ `Type.swift`.
- [ ] Nếu extension cần helper: chuyển helper sang file extension **hoặc** bỏ `private` (dùng `fileprivate` / `internal`).
- [ ] Hàm `internal` trả về `private struct` → compiler báo *"method must be declared fileprivate"* → đổi hàm thành `private` hoặc nâng access level của type.

**Ví dụ đã lỗi trên CI:**

```swift
// CommonServiceRepository.swift — getAddressTree() trả về private AddressTreeNodeInternal
private func getAddressTree() async -> Result<[AddressTreeNodeInternal], Error>
```

---

## 5. Swift — MainActor & concurrency (Swift 6)

- [ ] Code mutate `AppRouter`, `@Published`, UI state → gọi từ `@MainActor` (View, ViewModel `@MainActor`, hoặc `await MainActor.run { ... }`).
- [ ] Enum/helper mutate router (vd. `AppPromoNavigation`) → gắn `@MainActor` trên enum hoặc từng hàm.

```swift
@MainActor
enum AppPromoNavigation {
    static func applyPrimary(campaign: AppPromoCampaign, router: AppRouter) { ... }
}
```

- [ ] Closure lưu vào property / truyền qua nhiều tầng → tham số `@escaping`.
- [ ] Optional closure `(() -> Void)?` **không** viết `(@escaping () -> Void)?` — optional closure đã escaping sẵn.

---

## 6. Swift — Optional & kiểu dữ liệu hay sai

| Tình huống | Sai ❌ | Đúng ✅ |
|-----------|--------|---------|
| `RepositoryHttp.optString(...)` trả `String`, không phải `Optional` | `guard let id = optString(...)` | `let id = optString(...); guard !id.isEmpty` |
| `.nilIfEmpty` trên `String?` sau `flatMap` | `obj.flatMap { optString($0, "name") }.nilIfEmpty` | `obj.flatMap { optString($0, "name").nilIfEmpty }` |
| Optional trước method `String` | `sellerUsername.trimmingCharacters(...)` | `sellerUsername?.trimmingCharacters(...)` |
| `String.prefix` → `Substring` cho `String(format:)` / `L10n` | `L10n.foo(created.prefix(16))` | `L10n.foo(String(created.prefix(16)))` |
| So sánh không phân biệt hoa thường | `!a.caseInsensitiveCompare(b).orderedSame` | `a.caseInsensitiveCompare(b) != .orderedSame` |
| Truyền `[String]` vào variadic `String...` | `optString(obj, keys)` với `keys: [String]` | loop keys hoặc helper `firstNonEmptyString(obj, keys: keys)` |
| API Kotlin/Android không có trên iOS | `text.lineSequence()` | `text.split(separator: "\n", omittingEmptySubsequences: false)` |

---

## 7. SwiftUI — component & layout

- [ ] Không khai báo trùng tên type module-level (`FlowLayout` đã có trong `ProfileComponents` → dùng tên riêng, vd. `ProductDetailTagFlowLayout`).
- [ ] Trong `@ViewBuilder`, biến cục bộ không có trong scope con — dùng `viewModel.detail?.id` thay vì `detail.id` nếu `detail` chỉ tồn tại ở scope khác.
- [ ] Closure truyền vào `Button(action:)` / helper lưu closure → tham số hàm helper cần `@escaping`.

---

## 8. JSON parser & data layer

- [ ] Dùng `RepositoryHttp.optString` / `optLong` / `optBool` thay vì cast tay khi parse API.
- [ ] Field API Android có thể là `items` vs `addresses` — đối chiếu Android repository trước khi assume key.
- [ ] Parser full detail: nested object dùng pattern `parentObj.flatMap { RepositoryHttp.optString($0, "name", "Name").nilIfEmpty }`.

---

## 9. Localization & assets (CI fail sớm nếu thiếu)

File **phải commit** (CI không sync Android):

- [ ] `vendor/android-res/values/strings.xml`
- [ ] `vendor/android-res/values-en/strings.xml`
- [ ] `Fash/Resources/vi.lproj/Localizable.strings`
- [ ] `Fash/Resources/en.lproj/Localizable.strings`
- [ ] `Fash/Localization/L10n.swift`
- [ ] App icon PNG trong `Fash/Assets.xcassets/AppIcon.appiconset/`

Quy tắc:

- [ ] Key mới: có trong cả `vi` + `en` + `L10n.swift`.
- [ ] Không dùng key không có trong vendor Android (preflight có thể bắt, vd. `L10n.dialogCancel`).

---

## 10. Version & release

Trước push lên `releases/*`:

- [ ] Tăng `CURRENT_PROJECT_VERSION` (build number) trong `project.yml`.
- [ ] `MARKETING_VERSION` đúng version app (vd. `1.0.12`).
- [ ] Commit message mô tả thay đổi (fix build / feature / parity).

```yaml
# project.yml
MARKETING_VERSION: "1.0.13"
CURRENT_PROJECT_VERSION: "48"   # tăng mỗi lần upload TestFlight
```

- [ ] Push `origin` (GitLab) → đợi mirror → GitHub Actions **iOS Release** chạy.
- [ ] Không push build number trùng build đã upload App Store Connect.

---

## 11. CI — workflow nào chạy khi nào?

| Trigger | Workflow | Việc làm |
|---------|----------|----------|
| Push `develop` | **iOS Build** | Compile simulator, Fash-Dev |
| Push `main` / `master` | **iOS Build** | Compile simulator, Fash-Prod |
| PR vào các branch trên | **iOS Build** | Compile check |
| Push `releases/*` / `release/*` | **iOS Release** | Archive + IPA + TestFlight |
| Push tag `ios/v*` | **iOS Release** | Archive + IPA |

Release pipeline (`ios-release.yml`):

1. `ci_ios_prepare.sh` — i18n + preflight + `validate_swift_syntax.py` + XcodeGen + SPM
2. `xcodebuild archive` — **ProdRelease**, iOS device (strict nhất)
3. Export IPA + verify version + upload TestFlight

---

## 12. Khi CI fail — debug nhanh

1. GitHub Actions → run failed → step **Print xcodebuild errors**
2. Tải artifact `fash-ios-release-logs-<run>` hoặc `xcodebuild-archive.log`
3. Grep: `\.swift:[0-9]+:[0-9]+: error:`
4. Sửa → tăng build number → push lại

Lỗi thường gặp ngoài Swift compile:

| Lỗi | Hướng xử lý |
|-----|-------------|
| Missing signing secrets | Xem [docs/CI.md](./CI.md) |
| README.md in Copy Bundle Resources | Không add README vào Resources trong `project.yml` |
| IPA version mismatch | `project.yml` build ≠ Info.plist sau generate |
| TestFlight duplicate build | Tăng `CURRENT_PROJECT_VERSION` |

---

## 13. Checklist nhanh (copy trước mỗi release)

```text
[ ] python scripts/validate_swift_syntax.py
[ ] bash scripts/ci_validate_i18n.sh
[ ] bash scripts/ci_swift_compile_preflight.sh
[ ] Không dùng private member cross-file extension
[ ] @MainActor cho router / UI mutation
[ ] @escaping cho closure lưu trữ (không @escaping trên optional closure)
[ ] optString / optional / nilIfEmpty đúng kiểu
[ ] Không trùng tên struct module-level
[ ] project.yml: CURRENT_PROJECT_VERSION đã tăng
[ ] Push GitLab → mirror GitHub → theo dõi iOS Release
```

---

## Tham chiếu

- [docs/CI.md](./CI.md) — mirror GitLab → GitHub, secrets, TestFlight
- [scripts/README.md](../scripts/README.md) — danh sách script validate
- [PARITY.md](../PARITY.md) — đối chiếu Android khi port feature
