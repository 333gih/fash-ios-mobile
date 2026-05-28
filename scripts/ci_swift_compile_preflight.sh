#!/usr/bin/env bash
# Fast checks for Swift issues that fail ProdRelease archive on CI (before xcodebuild).
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"

fail=0

if grep -q 'private func postJSON' Fash/data/chat/ChatRepository.swift 2>/dev/null; then
  echo "::error::ChatRepository.postJSON is still private — ChatRepository+Offers.swift cannot compile. Remove private (commit db56ad3)."
  fail=1
fi

if grep -q 'private func parseMessageObj' Fash/data/chat/ChatRepository.swift 2>/dev/null; then
  echo "::error::ChatRepository.parseMessageObj is still private — ChatRepository+Offers.swift cannot compile."
  fail=1
fi

if grep -q 'sessionStore\.read' Fash/data/chat/ChatRepository+Offers.swift 2>/dev/null; then
  echo "::error::ChatRepository+Offers must use currentUserId, not private sessionStore."
  fail=1
fi

if grep -qE 'listingAestheticTag\)\.flatMap \{ tag in' Fash/ui/feed/ListingGridCard.swift 2>/dev/null; then
  echo "::error::ListingGridCard flatMap needs explicit (tag: String) -> String? (see db56ad3)."
  fail=1
fi

if [[ "${fail}" -ne 0 ]]; then
  exit 1
fi

echo "OK: Swift compile preflight (ChatRepository + ListingGridCard)"
