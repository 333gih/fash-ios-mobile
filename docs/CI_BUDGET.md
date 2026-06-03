# CI budget & branching — tiết kiệm macOS minutes

GitHub Actions macOS runner **đắt** (private repo ~200 phút/tháng free tier; team plan có giới hạn ~4000 phút tùy gói).  
Mỗi lần push fail → retry → **lãng phí gấp bội** (archive ~3–7 phút/run).

---

## Chi phí theo workflow

| Workflow | Trigger | Runner | ~Thời gian | Mức độ strict |
|----------|---------|--------|------------|---------------|
| **iOS Build** | `develop`, `main`, PR | macos-14 | 3–8 ph | Simulator compile |
| **iOS Release** | `releases/*` push | macos-26 | 5–10 ph | Archive iphoneos + WMO + TestFlight |

**Release strict hơn Build** — nhiều lỗi chỉ lộ ở archive (WMO, type-check, signing).

---

## Chiến lược branching

```text
feature/xyz ──PR──► develop ──(stable)──► releases/1.0 ──► TestFlight
                         │                        │
                    iOS Build                 iOS Release
                    (rẻ hơn)                  (đắt — dùng ít)
```

### Rules

1. **develop = integration branch** — push thường xuyên sau gate local.
2. **PR preferred** — một lần review + một lần CI cho nhiều commit (squash merge).
3. **releases/* = release only** — không debug compile ở đây.
4. **Batch fixes** — một push sửa hết lỗi compile, không 49→50→51→52→53.
5. **Concurrency** — iOS Build có `cancel-in-progress: true`; push liên tục hủy run cũ (tiết kiệm nhưng dễ nhầm run nào pass).

---

## Trước khi tiêu phút Release

Checklist bắt buộc ([BUILD_CHECKLIST.md](./BUILD_CHECKLIST.md)):

```powershell
.\scripts\check_before_push.ps1
```

Tuỳ chọn thêm (nếu develop đang xanh):

- Merge/rebase `develop` → `releases/*` thay vì commit trực tiếp lên release
- Chỉ 1 push release sau khi agent chạy gate + review diff

---

## Khi nào chạy workflow thủ công

| Mục đích | Cách |
|----------|------|
| Test compile Prod không push release | Actions → **iOS Build** → scheme `Fash-Prod` |
| TestFlight có kiểm soát | Actions → **iOS Release** → checkbox TestFlight |
| Không upload TF | iOS Release, bỏ tick TestFlight |

Tránh push `releases/*` chỉ để kích hoạt CI khi có thể dùng `workflow_dispatch`.

---

## Mirror GitLab ↔ GitHub

- Push `origin` (GitLab) → mirror → GitHub (delay vài giây–phút)
- Push trực tiếp khi gấp: `git push techheart <branch>`
- Remote GitHub Actions: `techheart-in-my-heart/fash-ios-mobile`

---

## Lỗi job fail ~3 giây — billing (không phải Xcode)

Nếu log/annotation:

> The job was not started because recent account payments have failed or your spending limit needs to be increased.

**Không có bước checkout/archive** — sửa tài khoản GitHub, không sửa Swift:

1. [GitHub Settings → Billing & plans](https://github.com/settings/billing)
2. Thanh toán invoice quá hạn hoặc tăng **Spending limit** (Actions)
3. Chờ vài phút, rồi:

```powershell
gh workflow run ios-release.yml --ref releases/1.0 -f scheme=Fash-Prod -f upload_testflight=true
gh run watch
```

Push `github` remote (repo chạy Actions): `git push github releases/1.0`

---

## Monitor & debug (không tốn thêm phút)

```powershell
# Runs gần nhất
gh run list --repo techheart-in-my-heart/fash-ios-mobile --limit 5

# Log lỗi Swift
gh run view <id> --repo techheart-in-my-heart/fash-ios-mobile --log-failed

# Artifact log
# Actions → failed run → fash-ios-release-logs-*
```

Pattern grep: `\.swift:[0-9]+:[0-9]+: error:`

---

## KPI gợi ý cho team

| Metric | Mục tiêu |
|--------|----------|
| Release pushes / version | ≤ 2 (1 feature + 1 hotfix tối đa) |
| Pre-push gate pass rate | 100% trước mọi push |
| iOS Build pass trên develop | > 90% |
| iOS Release first-try pass | > 70% (tăng dần nhờ convention + script) |

---

## Cải tiến dài hạn (backlog)

Các hạng mục giảm fail **không cần Mac local**:

1. Mở rộng `validate_swift_syntax.py`: duplicate type, `AnimatedContent` without availability, markdown chars in swift
2. Thêm job **ubuntu** chạy validate scripts trên mọi PR (0 macOS minutes)
3. Chỉ job macOS chạy khi `Fash/**` hoặc `project.yml` đổi (path filter)
4. Bắt buộc PR → develop pass iOS Build trước khi merge vào `releases/*`

---

## Liên kết

- [CI.md](./CI.md) — setup chi tiết
- [CURSOR_DEVELOPMENT.md](./CURSOR_DEVELOPMENT.md) — workflow Cursor
- [BUILD_CHECKLIST.md](./BUILD_CHECKLIST.md)
