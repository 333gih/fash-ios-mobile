#!/usr/bin/env bash
# macOS CI/dev: resize Android mipmap-xxxhdpi/ic_launcher.png into iOS AppIcon.appiconset.
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ANDROID="${FASH_ANDROID_ROOT:-$(cd "$ROOT/../fash-android-mobile" 2>/dev/null && pwd || true)}"
OUT="$ROOT/Fash/Assets.xcassets/AppIcon.appiconset"
mkdir -p "$OUT"

src=""
for d in mipmap-xxxhdpi mipmap-xxhdpi mipmap-xhdpi mipmap-hdpi; do
  cand="$ANDROID/app/src/main/res/$d/ic_launcher.png"
  if [[ -f "$cand" ]]; then src="$cand"; break; fi
done

if [[ -z "$src" ]]; then
  echo "error: missing Android mipmap-xxxhdpi/ic_launcher.png" >&2
  exit 1
fi

echo "Source: $src"
sizes=(40 58 60 80 87 120 152 167 180 1024)
for px in "${sizes[@]}"; do
  out="$OUT/AppIcon-${px}.png"
  sips -z "$px" "$px" "$src" --out "$out" >/dev/null
  echo "  AppIcon-${px}.png (${px}x${px})"
done

cat > "$OUT/Contents.json" <<'EOF'
{
  "images" : [
    { "filename" : "AppIcon-40.png", "idiom" : "iphone", "scale" : "2x", "size" : "20x20" },
    { "filename" : "AppIcon-60.png", "idiom" : "iphone", "scale" : "3x", "size" : "20x20" },
    { "filename" : "AppIcon-58.png", "idiom" : "iphone", "scale" : "2x", "size" : "29x29" },
    { "filename" : "AppIcon-87.png", "idiom" : "iphone", "scale" : "3x", "size" : "29x29" },
    { "filename" : "AppIcon-80.png", "idiom" : "iphone", "scale" : "2x", "size" : "40x40" },
    { "filename" : "AppIcon-120.png", "idiom" : "iphone", "scale" : "3x", "size" : "40x40" },
    { "filename" : "AppIcon-120.png", "idiom" : "iphone", "scale" : "2x", "size" : "60x60" },
    { "filename" : "AppIcon-180.png", "idiom" : "iphone", "scale" : "3x", "size" : "60x60" },
    { "filename" : "AppIcon-152.png", "idiom" : "ipad", "scale" : "2x", "size" : "76x76" },
    { "filename" : "AppIcon-167.png", "idiom" : "ipad", "scale" : "2x", "size" : "83.5x83.5" },
    { "filename" : "AppIcon-1024.png", "idiom" : "universal", "platform" : "ios", "size" : "1024x1024" }
  ],
  "info" : { "author" : "xcode", "version" : 1 }
}
EOF

echo "Done AppIcon.appiconset"
