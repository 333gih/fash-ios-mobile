# Home Feed — Cursor Pagination + Sliding Window

TikTok-style infinite scroll for tab **Following** (`GET /listings/home`).

## Backend (core-service)

```
GET /listings/home?pagination=cursor&limit=20
GET /listings/home?pagination=cursor&limit=20&cursor={created_at_nano}:{listing_id}
```

Response:

```json
{
  "listings": [],
  "has_more": true,
  "next_cursor": "1718352000000000000:550e8400-e29b-41d4-a716-446655440000"
}
```

- Sort: `ORDER BY created_at DESC, id DESC` (stable keyset)
- Legacy `offset` still returns bare array for Android until migrated

## iOS

| Layer | Responsibility |
|-------|----------------|
| `ListingRepository.getHomeFeedPage` | Cursor API |
| `FeedSlidingWindow` | Max 80 items in RAM; trim front when index > buffer |
| `HomeFeedScrollCoordinator` | Scroll delta after trim; preserve on append near bottom |
| `HomeViewModel` | Single `isLoadingMoreFollowing` guard; append-only |

### Sliding window

- `bufferBefore = 30`, `bufferAfter = 30`, `maxItems = 80`
- Trim only when visible index ≥ 38 and count > 80
- UIKit adjusts `contentOffset.y -= estimatedRemovedHeight` (no top gap)

### Prefetch

- Tile `onAppear` when `index > count - 10` (Explore policy)
- Footer = spinner only (`triggersLoadOnAppear: false`)
