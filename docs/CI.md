# CI: GitLab → GitHub → Build iOS

Project **Fash iOS** không build trên GitLab Free (runner Linux). Luồng khuyến nghị:

```text
Windows / bất kỳ máy nào
        │
        ▼ git push
   GitLab (origin)
        │
        ▼ mirror (đã cấu hình)
   GitHub
        │
        ▼ GitHub Actions (macOS + Xcode 15.4)
   Build iOS Simulator (Fash-Dev + Fash-Prod)
```

## 1. GitLab mirror → GitHub

Trên GitLab (**Settings → Repository → Mirroring repositories**):

| Field | Giá trị |
|---|---|
| Git repository URL | `https://github.com/<user>/<repo>.git` |
| Mirror direction | Push |
| Authentication | GitHub PAT (`repo` scope) hoặc deploy key |

Branch mirror thường dùng: `main`, `master`, `develop` — khớp với trigger trong `.github/workflows/ios-build.yml`.

Sau mỗi `git push` lên GitLab, đợi mirror sync (vài giây–phút) rồi kiểm tra GitHub **Actions**.

## 2. Bật GitHub Actions

Trên GitHub repo:

1. **Settings → Actions → General** → Allow actions.
2. Push branch có file `.github/workflows/ios-build.yml` (đã có trong repo).
3. Tab **Actions** → workflow **iOS Build**.

Trigger:

- `push` / `pull_request` vào `main`, `master`, `develop`
- **Run workflow** thủ công (chọn scheme `Fash-Dev`, `Fash-Prod`, hoặc `both`)

Scheme theo branch (tự động):

| Branch | Scheme build |
|---|---|
| `develop` | **Fash-Dev** |
| `main` / `master` | **Fash-Prod** |
| PR vào `develop` | **Fash-Dev** |
| PR vào `main` / `master` | **Fash-Prod** |
| Run workflow thủ công | Chọn scheme (hoặc `both`) |

## 3. Workflow làm gì?

Giống `./scripts/build_mac.sh` trên Mac cloud:

1. Cài **XcodeGen** (`brew`)
2. `xcodegen generate` → tạo `Fash.xcodeproj`
3. Resolve **Kingfisher** (SwiftPM)
4. `xcodebuild` cho **iOS Simulator** (iPhone 15, iOS 17.5)
5. `CODE_SIGNING_ALLOWED=NO` — chỉ verify compile, chưa ký app

Mỗi push chỉ build **một scheme** theo branch (`develop` → Dev, `main`/`master` → Prod). Run workflow thủ công vẫn chọn được `both`.

Runner: `macos-14` + **Xcode 16.2** (iOS 17 SDK; `project.yml` pin `projectFormat: xcode15_0` để tránh lỗi format 77 trên Xcode 15).

## 4. Chi phí GitHub

| Loại repo | macOS runner |
|---|---|
| **Public** | Miễn phí (không giới hạn phút như Linux) |
| **Private** | ~200 phút macOS/tháng (gói Free), sau đó trả phí |

Nếu build thường xuyên và repo private, cân nhắc public repo hoặc GitHub Team.

## 5. GitLab pipeline

File `.gitlab-ci.yml` chỉ **thông báo** — job chạy trên runner Linux, không build iOS. Giúp team biết build thật nằm trên GitHub Actions.

## 6. TestFlight / cài iPhone (bước sau)

Workflow hiện tại **chỉ compile** — chưa upload TestFlight.

Cần thêm (khi sẵn sàng):

- Apple Developer Program (~99 USD/năm)
- GitHub Secrets: certificate `.p12`, provisioning profile, App Store Connect API key
- Workflow release riêng (archive + sign + upload)

## 7. Troubleshooting

| Triệu chứng | Cách xử lý |
|---|---|
| Push GitLab nhưng GitHub không build | Kiểm tra mirror sync; branch có trong workflow trigger? |
| Workflow không xuất hiện | File `.github/workflows/ios-build.yml` đã lên GitHub chưa? |
| Build fail Kingfisher / Swift | Xem log artifact `xcodebuild-log-*`; cần Xcode 15+ |
| Hết phút macOS (private repo) | Đổi repo public hoặc nâng gói GitHub |

## 8. Build local (Mac)

```bash
./scripts/build_mac.sh              # Fash-Dev
./scripts/build_mac.sh Fash-Prod    # Fash-Prod
```

Yêu cầu: macOS 14.7+ , Xcode 15.4+ (xem README).
