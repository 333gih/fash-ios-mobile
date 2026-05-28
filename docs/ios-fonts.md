# Fash iOS — Custom fonts

Add Be Vietnam Pro font files under `Fash/Resources/Fonts/` (same family as Android `res/font/`):

- `BeVietnamPro-Regular.ttf`
- `BeVietnamPro-SemiBold.ttf`
- `BeVietnamPro-Bold.ttf`

Registered in `Fash/Info.plist` under `UIAppFonts`.

**Do not** add `README.md` inside `Fash/` — Xcode copies bundle resources by basename; duplicate `README.md` files break archive on CI.
