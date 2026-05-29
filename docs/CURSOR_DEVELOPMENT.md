# Phát triển Fash iOS bằng Cursor (không Mac)

Tài liệu này mô tả **quy trình chuẩn** khi bạn chỉ có Windows + Cursor: viết code local, build/verify trên GitHub Actions.

## Bối cảnh

| Thành phần | Vai trò |
|------------|---------|
| **Cursor / AI agent** | Viết & sửa Swift trong `Fash/` |
| **Scripts Python/Bash** | Bắt lỗi sớm **không cần Xcode** |
| **GitHub Actions** | `xcodebuild` trên macOS runner |
| **GitLab `origin`** | Remote chính (mirror → GitHub) |
| **GitHub `techheart`** | Remote Actions: `techheart-in-my-heart/fash-ios-mobile` |

**Giới hạn thực tế:** Script local **không thay thế** compiler Swift đầy đủ (WMO, Swift 6 concurrency, type-check phức tạp). Mục tiêu: giảm tỷ lệ fail release từ ~50% xuống mức chấp nhận được bằng gate + convention.

---

## Luồng làm việc khuyến nghị

```text
┌─────────────────────────────────────────────────────────────┐
│ 1. PLAN — đọc Android + Swift lân cận, scope nhỏ          │
└────────────────────────────┬────────────────────────────────┘
                             ▼
┌─────────────────────────────────────────────────────────────┐
│ 2. CODE — Cursor agent, theo CODE_CONVENTIONS.md          │
└────────────────────────────┬────────────────────────────────┘
                             ▼
┌─────────────────────────────────────────────────────────────┐
│ 3. GATE — check_before_push.ps1 (bắt buộc)                  │
└────────────────────────────┬────────────────────────────────┘
                             ▼
┌─────────────────────────────────────────────────────────────┐
│ 4. COMMIT — message rõ ràng, 1 logical change / commit     │
└────────────────────────────┬────────────────────────────────┘
                             ▼
         ┌───────────────────┴───────────────────┐
         ▼                                       ▼
┌─────────────────┐                   ┌─────────────────────┐
│ push develop    │                   │ push releases/*     │
│ → iOS Build     │                   │ → iOS Release + TF  │
│ (simulator)     │                   │ (archive iphoneos)  │
└─────────────────┘                   └─────────────────────┘
```

### Khi nào push branch nào?

- **Hàng ngày / feature:** `develop` hoặc `feature/xxx` → PR vào `develop`.
- **TestFlight:** chỉ `releases/*` sau khi gate pass + user yêu cầu release.
- **Không** dùng `releases/*` để debug compile — tốn phút macOS và dễ lặp build 49→53.

---

## Thiết lập Windows

### Bắt buộc

- **Git**
- **Python 3.10+** (`python --version`)
- **Git Bash** (đi kèm Git for Windows) — chạy `bash scripts/*.sh`

### Khuyến nghị

- **GitHub CLI:** `gh auth login` — theo dõi CI
- **Cursor rules:** file `.cursor/rules/fash-ios-mobile.mdc` (auto-load)

### Kiểm tra môi trường

```powershell
cd fash-ios-mobile
python scripts/validate_swift_syntax.py
bash scripts/ci_validate_i18n.sh
```

---

## Cổng kiểm tra trước push (Pre-push gate)

### Một lệnh (Windows)

```powershell
.\scripts\check_before_push.ps1
```

Script chạy tuần tự:

1. `validate_swift_syntax.py` — cú pháp, typography/color tokens, guard, duplicate func, brace balance
2. `ci_validate_i18n.sh` — vendor strings, Localizable, L10n
3. `ci_swift_compile_preflight.sh` — pattern đã từng fail archive

**Exit code 0** = được phép push. Agent **phải** chạy script này trước khi đề xuất push release.

### Sau push — monitor CI

```powershell
gh run list --repo techheart-in-my-heart/fash-ios-mobile --branch develop --limit 3
gh run watch <run-id> --repo techheart-in-my-heart/fash-ios-mobile
```

Release branch:

```powershell
gh run list --repo techheart-in-my-heart/fash-ios-mobile --branch releases/1.0 --workflow "iOS Release"
```

---

## Quy ước làm việc với Cursor

### Prompt / task cho agent

Luôn nêu rõ:

- File Android tham chiếu (nếu port)
- Scope (vd. “chỉ ExploreScreen, không đụng Home”)
- **Không push releases** trừ khi user yêu cầu TestFlight

### Agent PHẢI

1. Đọc file Swift **cùng module** trước khi thêm type/helper.
2. Chạy `check_before_push.ps1` sau khi sửa Swift.
3. Gộp fix CI vào **một commit** khi có thể (tránh 5 push release liên tiếp).
4. Tăng `CURRENT_PROJECT_VERSION` mỗi lần upload TestFlight.

### Agent KHÔNG NÊN

- Tạo `FlowLayout`, `displayLabel()` extension trùng file khác
- Dùng API chỉ có iOS 17+ (`AnimatedContent`) mà không `#available` hoặc fallback
- Để ký tự markdown (`` ` ``) thừa trong `.swift`
- Push thẳng `releases/*` để “thử build”
- Thêm file `.md` trong `Fash/` (Xcode có thể copy vào bundle)

---

## Sync strings từ Android (khi cần)

```powershell
$env:FASH_ANDROID_ROOT = "..\fash-android-mobile"
python scripts/sync_from_android.py
# Commit vendor/, Resources/, L10n.swift, AppIcon
```

CI **không** chạy sync — phải commit sẵn.

---

## Release TestFlight (tóm tắt)

1. Gate local pass
2. `project.yml`: tăng `CURRENT_PROJECT_VERSION`
3. Commit + push `releases/1.0` (GitLab + GitHub)
4. Workflow **iOS Release** → archive → IPA → TestFlight
5. App Store Connect → TestFlight → processing 5–30 phút

Chi tiết secrets: [CI.md](./CI.md).

---

## Xử lý khi không có Mac

| Việc | Cách làm |
|------|----------|
| Compile check nhanh | Push `develop` → iOS Build |
| Compile strict (release) | Push `releases/*` hoặc manual workflow |
| Debug lỗi Swift | Log GitHub → grep `\.swift:.*: error:` |
| Chạy app | TestFlight trên iPhone |
| Simulator .app | Artifact `fash-ios-simulator-*` từ iOS Build pass |

---

## Mở rộng hệ thống (maintainers)

Khi CI fail pattern mới:

1. Document trong [CODE_CONVENTIONS.md](./CODE_CONVENTIONS.md)
2. Thêm grep/rule vào `validate_swift_syntax.py` hoặc `ci_swift_compile_preflight.sh`
3. Cập nhật [BUILD_CHECKLIST.md](./BUILD_CHECKLIST.md) mục tương ứng

Mục tiêu: **mỗi incident CI → một rule tự động**, giảm lặp lại.

---

## Liên kết

- [CODE_CONVENTIONS.md](./CODE_CONVENTIONS.md)
- [CI_BUDGET.md](./CI_BUDGET.md)
- [BUILD_CHECKLIST.md](./BUILD_CHECKLIST.md)
- [../AGENTS.md](../AGENTS.md)
