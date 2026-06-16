import SwiftUI

/// Compact Pinterest-style spinner — fixed height so scroll position stays stable while loading.
struct FashFeedLoadMoreIndicator: View {
    @State private var isPulsing = false

    var body: some View {
        ProgressView()
            .controlSize(.regular)
            .tint(FashColors.brandPrimary)
            .scaleEffect(isPulsing ? 1.08 : 0.92)
            .opacity(isPulsing ? 1 : 0.72)
            .animation(
                .easeInOut(duration: 0.9).repeatForever(autoreverses: true),
                value: isPulsing
            )
            .frame(maxWidth: .infinity)
            .onAppear { isPulsing = true }
            .onDisappear { isPulsing = false }
    }
}

/// End-of-feed pagination — one auto-load per visit; re-arm after user scrolls away.
struct FeedLoadMoreFooter: View {
    enum LoadingPresentation {
        case spinner
        case skeleton(rows: Int)
    }

    let enabled: Bool
    let isLoadingMore: Bool
    /// When false, only shows loading UI — parent detects scroll proximity (profile/seller grids).
    var triggersLoadOnAppear: Bool = true
    /// Re-arm auto-load after a page completes — disable for home following (tile prefetch owns triggers).
    var rearmAfterLoadComplete: Bool = true
    /// Extra gate — e.g. home feed only loads more near scroll bottom while moving down.
    var canAutoLoad: () -> Bool = { true }
    var loadingPresentation: LoadingPresentation = .spinner
    let onLoadMore: () -> Void

    private static let spinnerHeight: CGFloat = 48
    private static let sentinelHeight: CGFloat = 28

    @State private var mayAutoLoad = false

    var body: some View {
        Group {
            if isLoadingMore {
                loadingMoreContent
            } else {
                Color.clear
                    .frame(maxWidth: .infinity)
                    .frame(height: Self.sentinelHeight)
            }
        }
        .frame(maxWidth: .infinity)
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
            guard rearmAfterLoadComplete else { return }
            guard wasLoading, !loading else { return }
            guard enabled else { return }
            // Re-arm at footer after a page lands — user often stays at the bottom while scrolling the grid.
            Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(380))
                guard enabled, !isLoadingMore, canAutoLoad() else { return }
                mayAutoLoad = true
                triggerLoadIfNeeded()
            }
        }
    }

    @ViewBuilder
    private var loadingMoreContent: some View {
        switch loadingPresentation {
        case .spinner:
            FashFeedLoadMoreIndicator()
                .frame(height: Self.spinnerHeight)
        case .skeleton(let rows):
            FashSkeleton.listingGrid(rows: max(1, rows), staggered: true)
                .frame(maxWidth: .infinity, alignment: .top)
                .padding(.top, 4)
                .padding(.bottom, 8)
        }
    }

    private func triggerLoadIfNeeded() {
        guard triggersLoadOnAppear, enabled, !isLoadingMore, mayAutoLoad, canAutoLoad() else { return }
        mayAutoLoad = false
        onLoadMore()
    }
}

/// @deprecated — use [FeedLoadMoreFooter].
typealias FeedPaginationSentinel = FeedLoadMoreFooter
