#!/usr/bin/env python3
"""Generate Dev.xcconfig / Prod.xcconfig from Android env/*.env files."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
ANDROID_ENV = ROOT.parent / "fash-android-mobile/env"
CONFIG = ROOT / "Config"


def load_env(path: Path) -> dict[str, str]:
    out: dict[str, str] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        if "=" not in line:
            continue
        k, v = line.split("=", 1)
        out[k.strip()] = v.strip()
    return out


def bool_str(v: str, default: str = "NO") -> str:
    if not v:
        return default
    return "YES" if v.lower() in ("true", "1", "yes") else "NO"


def xcconfig(env: dict[str, str], flavor: str) -> str:
    auth_prefix = env.get("AUTH_API_USE_LANGUAGE_PREFIX") or env.get("CORE_API_USE_LANGUAGE_PREFIX", "true")
    core_prefix = env.get("CORE_API_USE_LANGUAGE_PREFIX", "true")
    bundle = "com.pc.fash-ios-mobile.dev" if flavor == "dev" else "com.pc.fash-ios-mobile"
    lines = [
        f"// Generated from fash-android-mobile/env/{flavor}.env",
        f"FASH_ENVIRONMENT_NAME = {env.get('ENVIRONMENT_NAME', flavor)}",
        f"FASH_FLAVOR = {flavor}",
        f"PRODUCT_BUNDLE_IDENTIFIER = {bundle}",
        f"FASH_AUTH_SERVICE_BASE_URL = {env.get('AUTH_SERVICE_BASE_URL', '')}",
        f"FASH_API_BASE_URL = {env.get('API_BASE_URL', '')}",
        f"FASH_COMMON_SERVICE_BASE_URL = {env.get('COMMON_SERVICE_BASE_URL', '')}",
        f"FASH_REALTIME_BASE_URL = {env.get('REALTIME_BASE_URL', '')}",
        f"FASH_AUTH_CLIENT_ID = {env.get('AUTH_CLIENT_ID', 'fash-ios-dev')}",
        f"FASH_AUTH_APPLICATION_ID = {env.get('AUTH_APPLICATION_ID', 'web')}",
        f"FASH_AUTH_CLIENT_SECRET = {env.get('AUTH_CLIENT_SECRET', '')}",
        f"FASH_INTERNAL_SECRET = {env.get('INTERNAL_SECRET', '')}",
        f"FASH_INTERNAL_SERVICE_BEARER_TOKEN = {env.get('INTERNAL_SERVICE_BEARER_TOKEN', '')}",
        f"FASH_CORE_API_USE_LANGUAGE_PREFIX = {bool_str(core_prefix)}",
        f"FASH_AUTH_API_USE_LANGUAGE_PREFIX = {bool_str(auth_prefix)}",
        f"FASH_GOOGLE_WEB_CLIENT_ID = {env.get('GOOGLE_WEB_CLIENT_ID', '')}",
        f"FASH_FACEBOOK_APP_ID = {env.get('FACEBOOK_APP_ID', '')}",
        f"FASH_FACEBOOK_CLIENT_TOKEN = {env.get('FACEBOOK_CLIENT_TOKEN', '')}",
        f"FASH_FACEBOOK_LOGIN_ENABLED = {bool_str(env.get('FACEBOOK_LOGIN_ENABLED', 'false'))}",
        f"FASH_LISTING_SHARE_BASE_URL = {env.get('LISTING_SHARE_BASE_URL', 'https://fash.app/p/l')}",
        f"FASH_LEGAL_PORTAL_BASE_URL = {env.get('LEGAL_PORTAL_BASE_URL', 'https://fashandcurious.com')}",
        f"FASH_PAYMENT_REDIRECT_URL = {env.get('PAYMENT_REDIRECT_URL', 'https://fash.app/payment/callback')}",
        f"FASH_PUBLIC_BROWSE_CLIENT_ID = {env.get('PUBLIC_BROWSE_CLIENT_ID', 'fash-android')}",
        f"FASH_PUBLIC_BROWSE_CLIENT_TOKEN = {env.get('PUBLIC_BROWSE_CLIENT_TOKEN', '')}",
        f"FASH_SKIP_SIZING_REFERENCE = {bool_str(env.get('SKIP_SIZING_REFERENCE_COMPLETED', 'false'))}",
        f"FASH_SHIPPING_ENABLED = {bool_str(env.get('SHIPPING', 'true'))}",
        f"FASH_C2C_SHIP_FULFILLMENT = {bool_str(env.get('C2C_SHIP_FULFILLMENT_ENABLED', 'true'))}",
        f"FASH_C2C_SHIP_ONLINE_PAYMENT = {bool_str(env.get('C2C_SHIP_ONLINE_PAYMENT_ENABLED', 'true'))}",
        f"FASH_POST_REQUIRE_IMAGES = {bool_str(env.get('POST_REQUIRE_LISTING_IMAGES', 'true'))}",
        f"CHAT_MAX_OFFERS = {env.get('CHAT_MAX_OFFERS_PER_CONVERSATION', '3')}",
    ]
    paths = [
        ("AUTH_OTP_REQUEST_PATH", "api/v1/auth/otp/request"),
        ("AUTH_OTP_VERIFY_PATH", "api/v1/auth/otp/verify"),
        ("AUTH_LOGIN_PATH", "api/v1/auth/login"),
        ("AUTH_REFRESH_PATH", "api/v1/auth/refresh"),
        ("AUTH_LOGOUT_PATH", "api/v1/auth/logout"),
        ("AUTH_LOGOUT_ALL_PATH", "api/v1/auth/logout-all"),
        ("AUTH_FCM_REGISTER_PATH", "api/v1/auth/fcm/register"),
        ("AUTH_CHANGE_PASSWORD_PATH", "api/v1/auth/change-password"),
        ("AUTH_ME_PATH", "api/v1/auth/me"),
        ("CORE_USER_ACCESS_STATUS_PATH", "api/v1/users/me/setup-status"),
    ]
    for key, default in paths:
        val = env.get(key, default)
        swift_key = "FASH_" + key
        lines.append(f"{swift_key} = {val}")
    lines.append("FASH_AUTH_SOCIAL_LOGIN_PATH = api/v1/auth/social-login")
    return "\n".join(lines) + "\n"


def swift_build_config(env: dict[str, str], flavor: str) -> str:
    """Compile-time config — works without xcconfig injection into Info.plist."""
    bundle = "com.pc.fash-ios-mobile.dev" if flavor == "dev" else "com.pc.fash-ios-mobile"
    keys = [
        ("environmentName", env.get("ENVIRONMENT_NAME", flavor)),
        ("flavor", flavor),
        ("bundleId", bundle),
        ("authServiceBaseURL", env.get("AUTH_SERVICE_BASE_URL", "")),
        ("apiBaseURL", env.get("API_BASE_URL", "")),
        ("commonServiceBaseURL", env.get("COMMON_SERVICE_BASE_URL", "")),
        ("realtimeBaseURL", env.get("REALTIME_BASE_URL", "")),
        ("authClientId", env.get("AUTH_CLIENT_ID", "fash-ios-dev")),
        ("authApplicationId", env.get("AUTH_APPLICATION_ID", "web")),
        ("googleWebClientId", env.get("GOOGLE_WEB_CLIENT_ID", "")),
        ("listingShareBaseURL", env.get("LISTING_SHARE_BASE_URL", "https://fash.app/p/l")),
        ("legalPortalBaseURL", env.get("LEGAL_PORTAL_BASE_URL", "https://fashandcurious.com")),
        ("publicBrowseClientId", env.get("PUBLIC_BROWSE_CLIENT_ID", "fash-android")),
        ("publicBrowseClientToken", env.get("PUBLIC_BROWSE_CLIENT_TOKEN", "")),
        ("internalSecret", env.get("INTERNAL_SECRET", "")),
        ("internalServiceBearer", env.get("INTERNAL_SERVICE_BEARER_TOKEN", "")),
        ("userAccessStatusPath", env.get("CORE_USER_ACCESS_STATUS_PATH", "api/v1/users/me/setup-status")),
    ]
    lines = [
        "// Generated from env/%s.env — re-run scripts/env_to_xcconfig.py" % flavor,
        "import Foundation",
        "",
        f"enum GeneratedBuildConfig_{flavor.capitalize()} {{",
    ]
    for swift_name, val in keys:
        escaped = val.replace("\\", "\\\\").replace("\"", "\\\"")
        lines.append(f'    static let {swift_name}: String = "{escaped}"')
    for key in ("CORE_API_USE_LANGUAGE_PREFIX", "AUTH_API_USE_LANGUAGE_PREFIX", "SHIPPING", "SKIP_SIZING_REFERENCE_COMPLETED"):
        v = env.get(key, "")
        if key == "SHIPPING":
            b = v.lower() != "false" if v else True
        elif key == "SKIP_SIZING_REFERENCE_COMPLETED":
            b = v.lower() == "true"
        else:
            b = v.lower() == "true" if v else key.startswith("CORE") or key.startswith("AUTH")
        lines.append(f"    static let {key}: Bool = {'true' if b else 'false'}")
    lines.append("}")
    lines.append("")
    return "\n".join(lines)


def main() -> None:
    CONFIG.mkdir(parents=True, exist_ok=True)
    (CONFIG / "Dev.xcconfig").write_text(xcconfig(load_env(ANDROID_ENV / "dev.env"), "dev"), encoding="utf-8")
    (CONFIG / "Prod.xcconfig").write_text(xcconfig(load_env(ANDROID_ENV / "prod.env"), "prod"), encoding="utf-8")
    gen_dir = ROOT / "Fash" / "config" / "generated"
    gen_dir.mkdir(parents=True, exist_ok=True)
    (gen_dir / "GeneratedBuildConfig_Dev.swift").write_text(
        swift_build_config(load_env(ANDROID_ENV / "dev.env"), "dev"), encoding="utf-8"
    )
    (gen_dir / "GeneratedBuildConfig_Prod.swift").write_text(
        swift_build_config(load_env(ANDROID_ENV / "prod.env"), "prod"), encoding="utf-8"
    )
    print(f"Wrote {CONFIG}/Dev.xcconfig, Prod.xcconfig, and GeneratedBuildConfig_*.swift")


if __name__ == "__main__":
    main()
