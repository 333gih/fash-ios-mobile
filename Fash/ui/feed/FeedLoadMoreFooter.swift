import SwiftUI

/// Compact Pinterest-style spinner — fixed height so scroll position stays stable while loading.
struct FashFeedLoadMoreIndicator: View {
    var body: some View {
        ProgressView()
            .controlSize(.regular)
            .tint(FashColors.brandPrimary)
            .frame(maxWidth: .infinity)
    }
}

/// End-of-feed pagination — one auto-load per visit; re-arm after user scrolls away.
struct FeedLoadMoreFooter: View {
    let enabled: Bool
    let isLoadingMore: Bool
    /// When false, only shows loading UI — parent detects scroll proximity (profile/seller grids).
    var triggersLoadOnAppear: Bool = true
    let onLoadMore: () -> Void

    private static let sentinelHeight: CGFloat = 48

    @State private var mayAutoLoad = false

    var body: some View {
        ZStack {
            if isLoadingMore {
                FashFeedLoadMoreIndicator()
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: Self.sentinelHeight)
        .padding(.vertical, 4)
        .onAppear {
            mayAutoLoad = true
            triggerLoadIfNeeded()
        }
        .onDisappear {
            mayAutoLoad = false
        }
        .onChange(of: enabled) { _, _ in
            triggerLoadIfNeeded()
        }
        .onChange(of: isLoadingMore) { wasLoading, loading in
            guard wasLoading, !loading, enabled else { return }
            // After a page lands, wait until the user leaves and returns — avoids hammering at the footer.
            mayAutoLoad = false
        }
    }

    private func triggerLoadIfNeeded() {
        guard triggersLoadOnAppear, enabled, !isLoadingMore, mayAutoLoad else { return }
        mayAutoLoad = false
        onLoadMore()
    }
}

/// @deprecated — use [FeedLoadMoreFooter].
typealias FeedPaginationSentinel = FeedLoadMoreFooter
