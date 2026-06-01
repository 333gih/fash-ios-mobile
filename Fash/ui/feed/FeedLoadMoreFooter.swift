import SwiftUI

/// End-of-feed pagination — triggers [onLoadMore] only when the user scrolls to the bottom.
/// Shows a branded loading row while the next page fetches (no mid-scroll prefetch).
struct FeedLoadMoreFooter: View {
    let enabled: Bool
    let isLoadingMore: Bool
    /// Avoid auto-pagination when the grid is shorter than one page (footer stays on screen).
    var minimumItemsForAutoLoad: Int = 0
    var loadedItemCount: Int = 0
    let onLoadMore: () -> Void

    private var mayAutoLoad: Bool {
        guard enabled, !isLoadingMore else { return false }
        guard minimumItemsForAutoLoad <= 0 else {
            return loadedItemCount >= minimumItemsForAutoLoad
        }
        return true
    }

    var body: some View {
        VStack(spacing: 10) {
            if isLoadingMore {
                ProgressView()
                    .tint(FashColors.brandPrimary)
                Text(L10n.feedLoadingMore)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
                    .multilineTextAlignment(.center)
            } else {
                Color.clear
                    .frame(height: 1)
            }
        }
        .frame(maxWidth: .infinity)
        .frame(minHeight: isLoadingMore ? 72 : 1)
        .padding(.vertical, isLoadingMore ? 12 : 0)
        .onAppear {
            guard mayAutoLoad else { return }
            onLoadMore()
        }
    }
}

/// @deprecated — use [FeedLoadMoreFooter].
typealias FeedPaginationSentinel = FeedLoadMoreFooter
