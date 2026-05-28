#!/usr/bin/env bash
# Fail CI if Localizable.strings are missing from the exported IPA (root cause of L10n showing keys).
set -euo pipefail

IPA="${1:?IPA path required}"
SAMPLE_KEY="${2:-nav_home}"

WORK="$(mktemp -d)"
trap 'rm -rf "${WORK}"' EXIT
unzip -q "${IPA}" -d "${WORK}"

APP_DIR="$(find "${WORK}/Payload" -maxdepth 1 -type d -name '*.app' | head -1)"
if [[ -z "${APP_DIR}" ]]; then
  echo "::error::No .app found inside ${IPA}"
  exit 1
fi

echo "App bundle: ${APP_DIR}"
find "${APP_DIR}" -name 'Localizable.strings' -print | sort

lookup_plist_key() {
  local file="$1"
  local key="$2"
  /usr/libexec/PlistBuddy -c "Print :${key}" "${file}" 2>/dev/null || true
}

missing=0
for tag in vi en; do
  found="$(find "${APP_DIR}" -path "*/${tag}.lproj/Localizable.strings" -print -quit)"
  if [[ -z "${found}" ]]; then
    echo "::error::Missing ${tag}.lproj/Localizable.strings in IPA — L10n will show raw keys at runtime"
    missing=1
    continue
  fi
  size="$(wc -c < "${found}" | tr -d ' ')"
  if [[ "${size}" -lt 100 ]]; then
    echo "::error::${found} is too small (${size} bytes)"
    missing=1
    continue
  fi
  echo "OK: ${found} (${size} bytes)"

  # Xcode ships .strings as binary plist in Release — grep on source text fails; use PlistBuddy.
  value="$(lookup_plist_key "${found}" "${SAMPLE_KEY}")"
  if [[ -z "${value}" ]]; then
    echo "::error::${found} has no PlistBuddy key '${SAMPLE_KEY}' (binary strings table empty or wrong)"
    missing=1
    continue
  fi
  echo "  sample ${SAMPLE_KEY} (${tag}): ${value}"
  if [[ "${value}" == "${SAMPLE_KEY}" ]]; then
    echo "::error::${tag} ${SAMPLE_KEY} is untranslated (value equals key)"
    missing=1
  fi
done

if [[ "${missing}" -ne 0 ]]; then
  echo "::error::i18n bundle check failed. See project.yml sources (vi/en .lproj) and L10nBundle.swift"
  exit 1
fi

echo "OK: vi/en Localizable.strings are packaged in the IPA with translated ${SAMPLE_KEY}"
