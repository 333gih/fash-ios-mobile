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

/// Pinterest-style bottom sentinel — one load per footer visit; re-arms only after leaving the viewport.
struct FeedLoadMoreFooter: View {
    enum LoadingPresentation {
        case spinner
        case skeleton(rows: Int)
    }

    let enabled: Bool
    let isLoadingMore: Bool
    /// Item count when the sentinel last consumed a load — prevents hold-at-bottom loops after append.
    var anchorItemCount: Int = 0
    /// When false, parent owns pagination (legacy scroll proximity).
    var triggersLoadOnAppear: Bool = true
    var loadingPresentation: LoadingPresentation = .spinner
    let onLoadMore: () -> Void

    /// Fixed slot — spinner/sentinel swap must not change layout height (avoids onAppear thrash).
    private static let slotHeight: CGFloat = 48

    @State private var visitArmed = true
    /// Last `anchorItemCount` when `onLoadMore` fired — allows chained loads after append while held at bottom.
    @State private var lastTriggeredAtCount = -1
    @State private var disarmTask: Task<Void, Never>?

    var body: some View {
        ZStack {
            if isLoadingMore {
                loadingMoreContent
            } else {
                Color.clear
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, minHeight: Self.slotHeight, maxHeight: Self.slotHeight)
        .padding(.vertical, 4)
        .id("fash_feed_load_more_footer")
        .onAppear { tryLoadOnVisit() }
        .onDisappear { scheduleRearmAfterLeavingViewport() }
        .onChange(of: anchorItemCount) { oldCount, newCount in
            guard triggersLoadOnAppear, newCount > oldCount else { return }
            visitArmed = true
            tryLoadOnVisit()
        }
        .onChange(of: isLoadingMore) { wasLoading, loading in
            guard wasLoading, !loading else { return }
            visitArmed = true
            tryLoadOnVisit()
        }
        .onChange(of: enabled) { _, isEnabled in
            guard isEnabled else { return }
            visitArmed = true
            tryLoadOnVisit()
        }
    }

    @ViewBuilder
    private var loadingMoreContent: some View {
        switch loadingPresentation {
        case .spinner:
            FashFeedLoadMoreIndicator()
        case .skeleton(let rows):
            FashSkeleton.listingGrid(rows: max(1, rows), staggered: true)
                .frame(maxWidth: .infinity, alignment: .top)
                .padding(.top, 4)
                .padding(.bottom, 8)
        }
    }

    private func tryLoadOnVisit() {
        disarmTask?.cancel()
        disarmTask = nil
        guard triggersLoadOnAppear, enabled, !isLoadingMore, visitArmed else { return }
        guard anchorItemCount > lastTriggeredAtCount else { return }
        visitArmed = false
        lastTriggeredAtCount = anchorItemCount
        onLoadMore()
    }

    /// Debounce re-arm so masonry relayout flicker does not immediately re-trigger while held at bottom.
    private func scheduleRearmAfterLeavingViewport() {
        disarmTask?.cancel()
        disarmTask = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(280))
            guard !Task.isCancelled else { return }
            lastTriggeredAtCount = -1
            visitArmed = true
        }
    }
}

/// @deprecated — use [FeedLoadMoreFooter].
typealias FeedPaginationSentinel = FeedLoadMoreFooter
