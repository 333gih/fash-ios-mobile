import SwiftUI

/// End-of-feed pagination — triggers [onLoadMore] only when the user scrolls to the bottom.
/// Shows a branded loading row while the next page fetches (no mid-scroll prefetch).
struct FeedLoadMoreFooter: View {
    let enabled: Bool
    let isLoadingMore: Bool
    let onLoadMore: () -> Void

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
            guard enabled, !isLoadingMore else { return }
            onLoadMore()
        }
    }
}

/// @deprecated — use [FeedLoadMoreFooter].
typealias FeedPaginationSentinel = FeedLoadMoreFooter
