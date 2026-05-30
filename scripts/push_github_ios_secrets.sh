#!/usr/bin/env bash
# Push iOS release secrets from secrets/ios-release.env → GitHub Actions.
# Usage: ./scripts/push_github_ios_secrets.sh [secrets/ios-release.env] [owner/repo]
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ENV_FILE="${1:-secrets/ios-release.env}"
REPO="${2:-}"

if ! command -v gh >/dev/null 2>&1; then
  echo "error: install GitHub CLI (gh) and run: gh auth login" >&2
  exit 1
fi

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "error: missing ${ENV_FILE} — copy secrets/ios-release.env.example" >&2
  exit 1
fi

# shellcheck disable=SC1090
set -a
source <(grep -v '^\s*#' "${ENV_FILE}" | grep -v '^\s*$' | sed 's/\r$//')
set +a

REPO_ARGS=()
if [[ -n "${REPO}" ]]; then
  REPO_ARGS=(-R "${REPO}")
fi

set_secret() {
  local name="$1"
  local value="${2:-}"
  if [[ -z "${value}" ]]; then
    echo "skip ${name} (empty)"
    return
  fi
  echo "set  ${name}"
  printf '%s' "${value}" | gh secret set "${name}" "${REPO_ARGS[@]}"
}

file_to_b64() {
  local rel="$1"
  local full="${ROOT}/${rel}"
  [[ -f "${full}" ]] || { echo "error: file not found: ${full}" >&2; exit 1; }
  base64 < "${full}" | tr -d '\n'
}

CERT_B64="${IOS_DISTRIBUTION_CERTIFICATE_BASE64:-}"
if [[ -z "${CERT_B64}" && -n "${IOS_DISTRIBUTION_CERTIFICATE_PATH:-}" ]]; then
  CERT_B64="$(file_to_b64 "${IOS_DISTRIBUTION_CERTIFICATE_PATH}")"
fi

PROFILE_B64="${IOS_PROVISIONING_PROFILE_BASE64:-}"
if [[ -z "${PROFILE_B64}" && -n "${IOS_PROVISIONING_PROFILE_PATH:-}" ]]; then
  PROFILE_B64="$(file_to_b64 "${IOS_PROVISIONING_PROFILE_PATH}")"
fi

P8="${APP_STORE_CONNECT_API_PRIVATE_KEY:-}"
if [[ -z "${P8}" && -n "${APP_STORE_CONNECT_API_PRIVATE_KEY_PATH:-}" ]]; then
  P8="$(cat "${ROOT}/${APP_STORE_CONNECT_API_PRIVATE_KEY_PATH}")"
fi

set_secret "APPLE_TEAM_ID" "${APPLE_TEAM_ID:-}"
set_secret "IOS_DISTRIBUTION_CERTIFICATE_PASSWORD" "${IOS_DISTRIBUTION_CERTIFICATE_PASSWORD:-}"
set_secret "IOS_PROVISIONING_PROFILE_SPECIFIER" "${IOS_PROVISIONING_PROFILE_SPECIFIER:-}"
set_secret "IOS_DISTRIBUTION_CERTIFICATE_BASE64" "${CERT_B64}"
set_secret "IOS_PROVISIONING_PROFILE_BASE64" "${PROFILE_B64}"
set_secret "APP_STORE_CONNECT_ISSUER_ID" "${APP_STORE_CONNECT_ISSUER_ID:-}"
set_secret "APP_STORE_CONNECT_API_KEY_ID" "${APP_STORE_CONNECT_API_KEY_ID:-}"
set_secret "APP_STORE_CONNECT_API_PRIVATE_KEY" "${P8}"

PLIST_B64="${GOOGLE_SERVICE_INFO_PLIST_BASE64:-}"
if [[ -z "${PLIST_B64}" && -n "${GOOGLE_SERVICE_INFO_PLIST_PATH:-}" ]]; then
  PLIST_B64="$(file_to_b64 "${GOOGLE_SERVICE_INFO_PLIST_PATH}")"
fi
set_secret "GOOGLE_SERVICE_INFO_PLIST_BASE64" "${PLIST_B64}"

echo ""
echo "Done. Verify: gh secret list ${REPO_ARGS[*]}"
echo "Then: Actions → iOS Release → Run workflow"
