#!/usr/bin/env bash
# Sanity checks for incremental masonry layout APIs used by Home/Profile feeds.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "${ROOT}"

fail=0

if ! grep -q 'extendStableColumnLayout' Fash/ui/feed/ListingMasonryGrid.swift; then
  echo "::error::ListingMasonryGrid.extendStableColumnLayout missing"
  fail=1
fi

if ! grep -q 'FeedMasonryChunkedGrid' Fash/ui/feed/FeedMasonryChunkedGrid.swift; then
  echo "::error::FeedMasonryChunkedGrid missing"
  fail=1
fi

if ! grep -q 'parseFeedItems' Fash/data/listing/ListingFeedParseSupport.swift; then
  echo "::error::ListingFeedParseSupport.parseFeedItems missing"
  fail=1
fi

if [[ "${fail}" -ne 0 ]]; then
  exit 1
fi

echo "Masonry layout self-check passed."
