#!/usr/bin/env bash
# Fail Prod release builds if Sign in with Apple is disabled (App Store Guideline 4.8).
set -euo pipefail

SCHEME="${1:-Fash-Prod}"
ENV_FILE="${2:-env/prod.env}"
GENERATED="${3:-Fash/config/generated/GeneratedBuildConfig_Prod.swift}"

if [[ "${SCHEME}" != "Fash-Prod" ]]; then
  echo "Skip Apple login verify for scheme=${SCHEME}"
  exit 0
fi

if [[ ! -f "${ENV_FILE}" ]]; then
  echo "::error::Missing ${ENV_FILE}"
  exit 1
fi

ENV_VAL="$(grep -E '^APPLE_LOGIN_ENABLED=' "${ENV_FILE}" | cut -d= -f2- | tr -d ' \r' | tr '[:upper:]' '[:lower:]' || true)"
if [[ "${ENV_VAL}" != "true" && "${ENV_VAL}" != "1" && "${ENV_VAL}" != "yes" ]]; then
  echo "::error::${ENV_FILE} must set APPLE_LOGIN_ENABLED=true for Fash-Prod (App Store Guideline 4.8). Got: ${ENV_VAL:-<unset>}"
  exit 1
fi

if [[ ! -f "${GENERATED}" ]]; then
  echo "::error::Missing ${GENERATED} — run python3 scripts/env_to_xcconfig.py"
  exit 1
fi

if ! grep -q 'static let appleLoginEnabled: Bool = true' "${GENERATED}"; then
  echo "::error::${GENERATED} must compile appleLoginEnabled=true for Fash-Prod"
  exit 1
fi

echo "Sign in with Apple enabled for ${SCHEME} (env + GeneratedBuildConfig OK)"
