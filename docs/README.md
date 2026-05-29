# Fash iOS — Documentation index

Project phát triển chủ yếu trên **Windows + Cursor** (không Mac local). Build thật chạy trên **GitHub Actions**.

## Start here

| Audience | Document |
|----------|----------|
| **AI agents (Cursor, etc.)** | [../AGENTS.md](../AGENTS.md) |
| **Developer không có Mac** | [CURSOR_DEVELOPMENT.md](./CURSOR_DEVELOPMENT.md) |
| **Quy ước code Swift/SwiftUI** | [CODE_CONVENTIONS.md](./CODE_CONVENTIONS.md) |
| **Tiết kiệm phút CI macOS** | [CI_BUDGET.md](./CI_BUDGET.md) |
| **Trước mỗi push / release** | [BUILD_CHECKLIST.md](./BUILD_CHECKLIST.md) |

## CI & release

| Document | Nội dung |
|----------|----------|
| [CI.md](./CI.md) | GitLab → GitHub mirror, workflows, secrets, TestFlight |
| [BUILD_CHECKLIST.md](./BUILD_CHECKLIST.md) | Checklist chi tiết tránh lỗi archive |

## Architecture & parity

| Document | Nội dung |
|----------|----------|
| [../IOS_ARCHITECTURE.md](../IOS_ARCHITECTURE.md) | Layers, navigation, DI |
| [../PARITY.md](../PARITY.md) | Android ↔ iOS feature matrix |
| [IOS_BUSINESS_MODELS.md](./IOS_BUSINESS_MODELS.md) | Business models catalog |
| [DATA_LAYER.md](./DATA_LAYER.md) | Repositories, JSON parsing |
| [ios-data-layer.md](./ios-data-layer.md) | Data layer overview |
| [end-to-end-business-flow.md](./end-to-end-business-flow.md) | Commerce journeys |
| [common-service-api.md](./common-service-api.md) | common-service endpoints |
| [API_REFERENCE.md](./API_REFERENCE.md) | API reference |
| [ios-fonts.md](./ios-fonts.md) | Typography / fonts |

## Scripts

| Document | Nội dung |
|----------|----------|
| [../scripts/README.md](../scripts/README.md) | Validate, sync, CI helpers |

## Doc map (mental model)

```text
                    AGENTS.md
                        │
        ┌───────────────┼───────────────┐
        ▼               ▼               ▼
 CURSOR_DEVELOPMENT  CODE_CONVENTIONS  CI_BUDGET
        │               │               │
        └───────┬───────┴───────┬───────┘
                ▼               ▼
         BUILD_CHECKLIST      CI.md
                │
                ▼
         validate scripts (scripts/)
```

## Maintaining docs

- **Convention mới** sau incident CI → thêm vào `CODE_CONVENTIONS.md` + (nếu detectable) `validate_swift_syntax.py` hoặc `ci_swift_compile_preflight.sh`.
- **Workflow thay đổi** → cập nhật `CI.md` + `CI_BUDGET.md`.
- **Không** duplicate nội dung dài — link giữa các file.
