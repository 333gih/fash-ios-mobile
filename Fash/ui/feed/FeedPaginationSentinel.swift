import SwiftUI

/// Triggers [onPrefetch] when scrolled near the feed bottom — Android `snapshotFlow` on staggered grid.
struct FeedPaginationSentinel: View {
    let enabled: Bool
    let isLoadingMore: Bool
    let onPrefetch: () -> Void

    private let triggerHeight: CGFloat = 1

    var body: some View {
        Color.clear
            .frame(height: triggerHeight)
            .onAppear(perform: prefetchIfNeeded)
            .onChange(of: isLoadingMore) { wasLoading, loading in
                if wasLoading, !loading { prefetchIfNeeded() }
            }
    }

    private func prefetchIfNeeded() {
        guard enabled, !isLoadingMore else { return }
        onPrefetch()
    }
}
