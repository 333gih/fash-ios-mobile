#!/usr/bin/env python3
"""
Ensure fash-android-mobile has complete vi/en strings, then vendor + generate iOS L10n.

Android is the single source of truth for labels. iOS never hand-edits Localizable.strings.

Usage (from fash-ios-mobile):
  FASH_ANDROID_ROOT=../fash-android-mobile python3 scripts/sync_from_android.py
"""
from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
SCRIPTS = ROOT / "scripts"
sys.path.insert(0, str(SCRIPTS))
from fash_paths import android_root  # noqa: E402

XML_KEY = re.compile(r'<string\s+name="([^"]+)"')

# English for keys present in Android values/ but missing in values-en/
EN_FROM_VI: dict[str, str] = {
    "appointment_card_ticket": "Viewing appointment ticket",
    "badge_review_load_error": "Could not load badges. Try again later.",
    "badge_review_required": "Select at least 1 badge to submit a review",
    "badge_review_subtitle": "Choose up to 3 badges that reflect your experience",
    "badge_review_title": "Give the seller a badge",
    "browse_location_chip": "Area: %1$s",
    "browse_location_pick": "Choose area",
    "chat_detail_back_cd": "Go back",
    "chat_detail_back_inbox_unread_cd": "Back to inbox · %1$d unread in other conversations",
    "chat_detail_header_profile_cd": "View seller profile",
    "chat_detail_other_inbox_unread": "%1$d unread in other conversations",
    "chat_quick_replies_label": "Quick send",
    "chat_quick_reply_available": "Is this still available?",
    "chat_quick_reply_meetup": "Where can we meet?",
    "chat_quick_reply_photos": "Do you have more photos?",
    "explore_interest_chips_label": "Quick filter by style",
    "home_section_for_you_subtitle": "Based on your recent activity",
    "home_section_for_you_title": "Picked for you",
    "home_section_similar_to_saved_subtitle": "Because you saved items in this style",
    "home_section_similar_to_saved_title": "Similar to saved items",
    "home_section_trending_styles_subtitle": "Tap to filter on Explore",
    "home_section_trending_styles_title": "Trending styles",
    "listing_badge_just_listed": "Just listed",
    "listing_badge_saved_count": "%1$d saves",
    "listing_commitment_badge": "On-site check",
    "listing_commitment_body": "I agree to let the buyer inspect the item on-site and cancel the deal at no cost if it does not match the description.",
    "listing_commitment_title": "Safe transaction commitment",
    "onboarding_aesthetic_error": "Could not save style preferences. Try again.",
    "onboarding_sizing_optional_hint": "Optional — helps us suggest better sizes.",
    "onboarding_sizing_screen_title": "Sizing",
    "onboarding_username_screen_title": "Username",
    "post_condition_defect_photo_hint": "Remember to photograph the defects you selected in detail.",
    "post_condition_defects_label": "Defects (if any)",
    "post_condition_score_label": "Condition score: %1$d/99",
    "post_defect_fading": "Fading",
    "post_defect_missing_button": "Missing button",
    "post_defect_odor": "Odor",
    "post_defect_pilling": "Pilling",
    "post_defect_stains": "Stains",
    "post_defect_worn": "Worn",
    "product_action_follow_seller": "Follow",
    "product_action_following_seller": "Following",
    "product_save_nudge": "Saved — Message the seller?",
    "product_save_nudge_cta": "Message now",
    "product_save_nudge_dismiss": "Dismiss",
    "profile_height_cm": "Height %1$d cm",
    "profile_weight_kg": "Weight %1$s kg",
}

# Shared vi/en keys used by both apps (HTTP errors, delivering screen, …)
SHARED_VI: dict[str, str] = {
    "home_delivering_coming_soon_body": "Tính năng giao hàng với thanh toán trong app sắp ra mắt. Bạn sẽ quản lý giao hàng tại đây khi tính năng mở.",
    "home_delivering_coming_soon_title": "Sắp ra mắt",
    "home_delivering_list_intro": "Đơn hàng đang giao tới người mua. Theo dõi trạng thái và cập nhật thông tin giao hàng tại đây.",
    "home_delivering_screen_title": "Đang giao",
    "error_generic": "Đã xảy ra lỗi. Vui lòng thử lại.",
    "error_http_bad_request": "Yêu cầu không hợp lệ",
    "error_http_unauthorized": "Cần đăng nhập",
    "error_http_forbidden": "Không có quyền truy cập",
    "error_http_not_found": "Không tìm thấy",
    "error_http_conflict": "Không khả dụng",
    "error_http_server": "Lỗi máy chủ",
    "error_http_status": "Lỗi HTTP %1$s",
    "error_network_unavailable": "Không có kết nối mạng. Kiểm tra Internet và thử lại.",
    "session_expired_message": "Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.",
}

SHARED_EN: dict[str, str] = {
    "home_delivering_coming_soon_body": "Shipping with in-app payment is coming soon. You'll manage deliveries here when it launches.",
    "home_delivering_coming_soon_title": "Coming soon",
    "home_delivering_list_intro": "Orders on the way to buyers. Track status and update delivery details here.",
    "home_delivering_screen_title": "In transit",
    "error_generic": "Something went wrong. Please try again.",
    "error_http_bad_request": "Bad request",
    "error_http_unauthorized": "Authentication required",
    "error_http_forbidden": "Permission denied",
    "error_http_not_found": "Not found",
    "error_http_conflict": "Not available",
    "error_http_server": "Server error",
    "error_http_status": "HTTP error %1$s",
    "error_network_unavailable": "No network connection. Check your internet and try again.",
    "session_expired_message": "Session expired. Please sign in again.",
}


def xml_keys(path: Path) -> set[str]:
    return set(XML_KEY.findall(path.read_text(encoding="utf-8")))


def append_android_strings(path: Path, entries: dict[str, str], comment: str) -> int:
    if not path.is_file():
        raise SystemExit(f"Missing {path}")
    present = xml_keys(path)
    to_add = {k: v for k, v in entries.items() if k not in present}
    if not to_add:
        return 0
    lines = ["", f"    <!-- {comment} -->"]
    for key in sorted(to_add.keys()):
        val = (
            to_add[key]
            .replace("&", "&amp;")
            .replace("<", "&lt;")
            .replace(">", "&gt;")
            .replace("'", "\\'")
            .replace('"', "&quot;")
        )
        lines.append(f'    <string name="{key}">{val}</string>')
    text = path.read_text(encoding="utf-8")
    if not text.rstrip().endswith("</resources>"):
        raise SystemExit(f"Unexpected format: {path}")
    text = text.rstrip()[:- len("</resources>")] + "\n".join(lines) + "\n</resources>\n"
    path.write_text(text, encoding="utf-8")
    return len(to_add)


def patch_android_strings(android: Path) -> None:
    vi_path = android / "app/src/main/res/values/strings.xml"
    en_path = android / "app/src/main/res/values-en/strings.xml"
    vi_keys = xml_keys(vi_path)
    en_keys = xml_keys(en_path)
    missing_en = {k: EN_FROM_VI[k] for k in sorted(vi_keys - en_keys) if k in EN_FROM_VI}
    # Fallback: copy vi text for keys we lack explicit EN (should not happen)
    for k in sorted(vi_keys - en_keys):
        if k not in missing_en:
            print(f"warning: no EN translation map for {k}", file=sys.stderr)
    n_vi = append_android_strings(vi_path, SHARED_VI, "sync_from_android — shared vi")
    n_en_shared = append_android_strings(en_path, SHARED_EN, "sync_from_android — shared en")
    n_en_missing = append_android_strings(en_path, missing_en, "sync_from_android — en parity")
    print(
        f"Patched Android strings: vi+{n_vi}, en+{n_en_shared + n_en_missing} "
        f"({len(missing_en)} vi-to-en parity keys)"
    )


def run_py(script: str) -> None:
    rc = subprocess.call([sys.executable, str(SCRIPTS / script)], cwd=ROOT)
    if rc != 0:
        raise SystemExit(rc)


def main() -> int:
    android = android_root()
    if not android:
        print(
            "error: set FASH_ANDROID_ROOT or clone fash-android-mobile next to fash-ios-mobile",
            file=sys.stderr,
        )
        return 1

    patch_android_strings(android)
    run_py("vendor_from_android.py")
    run_py("android_strings_to_ios.py")
    run_py("validate_strings.py")
    run_py("validate_l10n_swift.py")

    vi = xml_keys(ROOT / "vendor/android-res/values/strings.xml")
    en = xml_keys(ROOT / "vendor/android-res/values-en/strings.xml")
    print(f"Done: Android vi={len(vi)} en={len(en)} -> iOS Localizable.strings + L10n.swift")
    if vi - en:
        print(f"warning: {len(vi - en)} keys still missing in values-en", file=sys.stderr)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
