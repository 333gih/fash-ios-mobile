#!/usr/bin/env python3
"""Backfill missing English strings in vendor/android-res for iOS sync parity."""
from __future__ import annotations

import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
EN_PATH = ROOT / "vendor" / "android-res" / "values-en" / "strings.xml"
VI_PATH = ROOT / "vendor" / "android-res" / "values" / "strings.xml"

# English translations for keys present in vi but missing in values-en.
MISSING_EN: dict[str, str] = {
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
    "listing_badge_saved_count": "%1$s saves",
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
    "profile_height_cm": "Height %1$s cm",
    "profile_weight_kg": "Weight %1$s kg",
}

# iOS + Android shared HTTP / auth fallbacks (also added to vi).
IOS_HTTP_ERRORS_VI: dict[str, str] = {
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

IOS_HTTP_ERRORS_EN: dict[str, str] = {
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


def existing_names(path: Path) -> set[str]:
    text = path.read_text(encoding="utf-8")
    return set(re.findall(r'<string\s+name="([^"]+)"', text))


def append_strings(path: Path, entries: dict[str, str]) -> int:
    if not path.is_file():
        raise SystemExit(f"Missing {path}")
    present = existing_names(path)
    to_add = {k: v for k, v in entries.items() if k not in present}
    if not to_add:
        return 0
    lines = ["", "    <!-- iOS backfill / shared HTTP errors -->"]
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


def main() -> int:
    n_en = append_strings(EN_PATH, {**MISSING_EN, **IOS_HTTP_ERRORS_EN})
    n_vi = append_strings(VI_PATH, IOS_HTTP_ERRORS_VI)
    print(f"Added {n_en} keys to values-en, {n_vi} keys to values")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
