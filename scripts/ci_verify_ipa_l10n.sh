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

missing=0
for tag in vi en; do
  found="$(find "${APP_DIR}" -path "*/${tag}.lproj/Localizable.strings" -print -quit)"
  if [[ -z "${found}" ]]; then
    echo "::error::Missing ${tag}.lproj/Localizable.strings in IPA — L10n will show raw keys at runtime"
    missing=1
    continue
  fi
  echo "OK: ${found}"
  if ! grep -q "\"${SAMPLE_KEY}\"" "${found}"; then
    echo "::error::${found} does not contain key ${SAMPLE_KEY}"
    missing=1
    continue
  fi
  value="$(grep "\"${SAMPLE_KEY}\"" "${found}" | head -1)"
  echo "  sample ${SAMPLE_KEY}: ${value}"
  if [[ "${value}" == *" = \"${SAMPLE_KEY}\";"* ]] || [[ "${value}" == *"= ${SAMPLE_KEY};"* ]]; then
    echo "::error::${tag} ${SAMPLE_KEY} is untranslated (value equals key)"
    missing=1
  fi
done

if [[ "${missing}" -ne 0 ]]; then
  echo "::error::i18n bundle check failed. See project.yml sources (vi/en .lproj) and L10nBundle.swift"
  exit 1
fi

echo "OK: vi/en Localizable.strings are packaged in the IPA"
