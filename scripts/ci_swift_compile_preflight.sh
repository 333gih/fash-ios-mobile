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

if grep -q 'static func optBool' Fash/data/chat/ChatRepository+Offers.swift 2>/dev/null; then
  echo "::error::ChatRepository+Offers redeclares RepositoryHttp.optBool — remove private extension."
  fail=1
fi

if grep -q 'AppDependencies.shared.isGuestBrowseActive' Fash/App/AppDependencies.swift 2>/dev/null; then
  echo "::error::AppDependencies init must not read isGuestBrowseActive via shared from @Sendable closures."
  fail=1
fi

if grep -q 'L10n\.dialogCancel' Fash/ui/chat/ChatDetailComponents.swift 2>/dev/null; then
  echo "::error::Use L10n.createListingCancel — dialog_cancel is not in vendor/android-res."
  fail=1
fi

if grep -q 'private enum OrderCancelledChatPayload' Fash/ui/chat/ChatInboxPreview.swift 2>/dev/null; then
  echo "::error::Remove private OrderCancelledChatPayload from ChatInboxPreview — use Fash/data/chat/OrderCancelledChatPayload.swift."
  fail=1
fi

if ! grep -q 'orderIdPrefix' Fash/data/chat/OrderCancelledChatPayload.swift 2>/dev/null; then
  echo "::error::OrderCancelledChatPayload.swift must define orderIdPrefix for inbox preview parsing."
  fail=1
fi

if [[ "${fail}" -ne 0 ]]; then
  exit 1
fi

echo "OK: Swift compile preflight (ChatRepository + ListingGridCard)"
