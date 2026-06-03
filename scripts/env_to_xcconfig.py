#!/usr/bin/env python3
"""Generate Dev.xcconfig / Prod.xcconfig + GeneratedBuildConfig_*.swift from Android env/*.env."""
from __future__ import annotations

import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(Path(__file__).resolve().parent))
from fash_paths import env_dir  # noqa: E402

ANDROID_ENV = env_dir()
CONFIG = ROOT / "Config"

AUTH_PATH_DEFAULTS = {
    "AUTH_OTP_REQUEST_PATH": "api/v1/auth/otp/request",
    "AUTH_OTP_VERIFY_PATH": "api/v1/auth/otp/verify",
    "AUTH_LOGIN_PATH": "api/v1/auth/login",
    "AUTH_REFRESH_PATH": "api/v1/auth/refresh",
    "AUTH_LOGOUT_PATH": "api/v1/auth/logout",
    "AUTH_LOGOUT_ALL_PATH": "api/v1/auth/logout-all",
    "AUTH_FCM_REGISTER_PATH": "api/v1/auth/fcm/register",
    "AUTH_CHANGE_PASSWORD_PATH": "api/v1/auth/change-password",
    "AUTH_ME_PATH": "api/v1/auth/me",
    "AUTH_SOCIAL_LOGIN_PATH": "api/v1/auth/social-login",
    "CORE_USER_ACCESS_STATUS_PATH": "api/v1/users/me/setup-status",
    "CORE_PAYMENT_INITIATE_PATH": "api/v1/orders/%s/payments/initiate",
}


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


def env_bool(env: dict[str, str], key: str, default: bool) -> bool:
    v = env.get(key, "")
    if not v:
        return default
    return v.lower() in ("true", "1", "yes")


def swift_escape(s: str) -> str:
    return s.replace("\\", "\\\\").replace('"', '\\"')


def read_google_ios_client_id_from_plist(flavor: str) -> str:
    """CLIENT_ID from Fash/GoogleService-Info*.plist when env GOOGLE_IOS_CLIENT_ID is empty."""
    name = "GoogleService-Info-Dev" if flavor == "dev" else "GoogleService-Info"
    path = ROOT / "Fash" / f"{name}.plist"
    if not path.is_file():
        return ""
    try:
        import plistlib

        data = plistlib.loads(path.read_bytes())
        if isinstance(data, dict):
            value = data.get("CLIENT_ID")
            if isinstance(value, str):
                return value.strip()
    except Exception:
        return ""
    return ""


def resolve_google_ios_client_id(env: dict[str, str], flavor: str) -> str:
    explicit = env.get("GOOGLE_IOS_CLIENT_ID", "").strip()
    if explicit:
        return explicit
    return read_google_ios_client_id_from_plist(flavor)


def google_reversed_url_scheme(ios_client_id: str) -> str:
    trimmed = ios_client_id.strip()
    suffix = ".apps.googleusercontent.com"
    if not trimmed or not trimmed.endswith(suffix):
        return ""
    prefix = trimmed[: -len(suffix)]
    return f"com.googleusercontent.apps.{prefix}"


def xcconfig(env: dict[str, str], flavor: str) -> str:
    auth_prefix = env.get("AUTH_API_USE_LANGUAGE_PREFIX") or env.get("CORE_API_USE_LANGUAGE_PREFIX", "true")
    core_prefix = env.get("CORE_API_USE_LANGUAGE_PREFIX", "true")
    bundle = "com.pc.fash-ios-mobile.dev" if flavor == "dev" else "com.pc.fash-ios-mobile"
    google_ios_client_id = resolve_google_ios_client_id(env, flavor)
    lines = [
        f"// Generated from env/{flavor}.env",
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
        f"FASH_GOOGLE_IOS_CLIENT_ID = {google_ios_client_id}",
        f"FASH_GOOGLE_URL_SCHEME = {google_reversed_url_scheme(google_ios_client_id)}",
        f"FASH_FACEBOOK_APP_ID = {env.get('FACEBOOK_APP_ID', '')}",
        f"FASH_FACEBOOK_CLIENT_TOKEN = {env.get('FACEBOOK_CLIENT_TOKEN', '')}",
        f"FASH_FACEBOOK_LOGIN_ENABLED = {bool_str(env.get('FACEBOOK_LOGIN_ENABLED', 'false'))}",
        f"FASH_LISTING_SHARE_BASE_URL = {env.get('LISTING_SHARE_BASE_URL', 'https://fash.app/p/l')}",
        f"FASH_LEGAL_PORTAL_BASE_URL = {env.get('LEGAL_PORTAL_BASE_URL', 'https://fashandcurious.com')}",
        f"FASH_PAYMENT_REDIRECT_URL = {env.get('PAYMENT_REDIRECT_URL', 'https://fash.app/payment/callback')}",
        f"FASH_IDENTITY_REVERIFY_URL = {env.get('IDENTITY_REVERIFY_URL', '')}",
        f"FASH_PUBLIC_BROWSE_CLIENT_ID = {env.get('PUBLIC_BROWSE_CLIENT_ID', 'fash-android')}",
        f"FASH_PUBLIC_BROWSE_CLIENT_TOKEN = {env.get('PUBLIC_BROWSE_CLIENT_TOKEN', '')}",
        f"FASH_SKIP_SIZING_REFERENCE = {bool_str(env.get('SKIP_SIZING_REFERENCE_COMPLETED', 'false'))}",
        f"FASH_SHIPPING_ENABLED = {bool_str(env.get('SHIPPING', 'true'))}",
        f"FASH_C2C_SHIP_FULFILLMENT = {bool_str(env.get('C2C_SHIP_FULFILLMENT_ENABLED', 'true'))}",
        f"FASH_C2C_SHIP_ONLINE_PAYMENT = {bool_str(env.get('C2C_SHIP_ONLINE_PAYMENT_ENABLED', 'true'))}",
        f"FASH_POST_REQUIRE_IMAGES = {bool_str(env.get('POST_REQUIRE_LISTING_IMAGES', 'true'))}",
        f"CHAT_MAX_OFFERS = {env.get('CHAT_MAX_OFFERS_PER_CONVERSATION', '3')}",
    ]
    for key, default in AUTH_PATH_DEFAULTS.items():
        lines.append(f"FASH_{key} = {env.get(key, default)}")
    return "\n".join(lines) + "\n"


def swift_build_config(env: dict[str, str], flavor: str) -> str:
    bundle = "com.pc.fash-ios-mobile.dev" if flavor == "dev" else "com.pc.fash-ios-mobile"
    google_ios_client_id = resolve_google_ios_client_id(env, flavor)
    string_keys = [
        ("environmentName", env.get("ENVIRONMENT_NAME", flavor)),
        ("flavor", flavor),
        ("bundleId", bundle),
        ("authServiceBaseURL", env.get("AUTH_SERVICE_BASE_URL", "")),
        ("apiBaseURL", env.get("API_BASE_URL", "")),
        ("commonServiceBaseURL", env.get("COMMON_SERVICE_BASE_URL", "")),
        ("realtimeBaseURL", env.get("REALTIME_BASE_URL", "")),
        ("authClientId", env.get("AUTH_CLIENT_ID", "fash-ios-dev")),
        ("authApplicationId", env.get("AUTH_APPLICATION_ID", "web")),
        ("authClientSecret", env.get("AUTH_CLIENT_SECRET", "")),
        ("googleWebClientId", env.get("GOOGLE_WEB_CLIENT_ID", "")),
        ("googleIosClientId", google_ios_client_id),
        ("googleUrlScheme", google_reversed_url_scheme(google_ios_client_id)),
        ("facebookAppId", env.get("FACEBOOK_APP_ID", "")),
        ("facebookClientToken", env.get("FACEBOOK_CLIENT_TOKEN", "")),
        ("listingShareBaseURL", env.get("LISTING_SHARE_BASE_URL", "https://fash.app/p/l")),
        ("legalPortalBaseURL", env.get("LEGAL_PORTAL_BASE_URL", "https://fashandcurious.com")),
        ("paymentRedirectURL", env.get("PAYMENT_REDIRECT_URL", "https://fash.app/payment/callback")),
        ("identityReverifyURL", env.get("IDENTITY_REVERIFY_URL", "")),
        ("publicBrowseClientId", env.get("PUBLIC_BROWSE_CLIENT_ID", "fash-android")),
        ("publicBrowseClientToken", env.get("PUBLIC_BROWSE_CLIENT_TOKEN", "")),
        ("internalSecret", env.get("INTERNAL_SECRET", "")),
        ("internalServiceBearer", env.get("INTERNAL_SERVICE_BEARER_TOKEN", "")),
        ("userAccessStatusPath", env.get("CORE_USER_ACCESS_STATUS_PATH", "api/v1/users/me/setup-status")),
        ("corePaymentInitiatePath", env.get("CORE_PAYMENT_INITIATE_PATH", "api/v1/orders/%s/payments/initiate")),
    ]
    for env_key, swift_suffix in [
        ("AUTH_OTP_REQUEST_PATH", "authOtpRequestPath"),
        ("AUTH_OTP_VERIFY_PATH", "authOtpVerifyPath"),
        ("AUTH_LOGIN_PATH", "authLoginPath"),
        ("AUTH_REFRESH_PATH", "authRefreshPath"),
        ("AUTH_LOGOUT_PATH", "authLogoutPath"),
        ("AUTH_LOGOUT_ALL_PATH", "authLogoutAllPath"),
        ("AUTH_FCM_REGISTER_PATH", "authFcmRegisterPath"),
        ("AUTH_CHANGE_PASSWORD_PATH", "authChangePasswordPath"),
        ("AUTH_ME_PATH", "authMePath"),
        ("AUTH_SOCIAL_LOGIN_PATH", "authSocialLoginPath"),
    ]:
        string_keys.append((swift_suffix, env.get(env_key, AUTH_PATH_DEFAULTS[env_key])))

    lines = [
        f"// Generated from env/{flavor}.env — mirrors Android BuildConfig injectFromEnv",
        "import Foundation",
        "",
        f"enum GeneratedBuildConfig_{flavor.capitalize()} {{",
    ]
    for swift_name, val in string_keys:
        lines.append(f'    static let {swift_name}: String = "{swift_escape(val)}"')

    bool_defs = [
        ("coreApiUseLanguagePrefix", "CORE_API_USE_LANGUAGE_PREFIX", True),
        ("authApiUseLanguagePrefix", "AUTH_API_USE_LANGUAGE_PREFIX", None),
        ("shippingEnabled", "SHIPPING", True),
        ("skipSizingReferenceCompleted", "SKIP_SIZING_REFERENCE_COMPLETED", False),
        ("c2cShipFulfillmentEnabled", "C2C_SHIP_FULFILLMENT_ENABLED", True),
        ("c2cShipOnlinePaymentEnabled", "C2C_SHIP_ONLINE_PAYMENT_ENABLED", True),
        ("postRequireListingImages", "POST_REQUIRE_LISTING_IMAGES", True),
        ("facebookLoginEnabled", "FACEBOOK_LOGIN_ENABLED", False),
    ]
    for swift_name, env_key, default in bool_defs:
        if env_key == "AUTH_API_USE_LANGUAGE_PREFIX" and env_key not in env:
            b = env_bool(env, "CORE_API_USE_LANGUAGE_PREFIX", True)
        else:
            b = env_bool(env, env_key, default if default is not None else False)
        lines.append(f"    static let {swift_name}: Bool = {'true' if b else 'false'}")

    chat_max = env.get("CHAT_MAX_OFFERS_PER_CONVERSATION", "3")
    lines.append(f"    static let chatMaxOffersPerConversation: Int = {chat_max}")
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
