#!/usr/bin/env bash
# Inject CI signing into project.yml (Fash target release configs only) before xcodegen.
# Usage: ci_patch_release_signing.sh <TEAM_ID> <PROVISIONING_PROFILE_NAME>
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

TEAM_ID="${1:?TEAM_ID required}"
PROFILE_NAME="${2:?PROVISIONING_PROFILE_NAME required}"

if [[ ! -f project.yml ]]; then
  echo "project.yml not found"
  exit 1
fi

if ! grep -q '__CI_TEAM_ID__' project.yml; then
  echo "project.yml missing __CI_TEAM_ID__ placeholder"
  exit 1
fi

# macOS sed (GitHub Actions macos-14)
sed -i '' "s|__CI_TEAM_ID__|${TEAM_ID}|g" project.yml
sed -i '' "s|__CI_PROVISIONING_PROFILE__|${PROFILE_NAME}|g" project.yml

echo "Patched project.yml for manual signing (Fash release configs only)"
