import SwiftUI

struct HomeRecommendedSellersSection: View {
    @Environment(\.fashSpacing) private var spacing
    let sellers: [FeaturedSellerItem]
    var followingIds: Set<String> = []
    var onSellerClick: (FeaturedSellerItem) -> Void
    var onSeeAllClick: () -> Void
    var includeHorizontalEdgePadding: Bool = true

    var body: some View {
        if sellers.isEmpty { EmptyView() } else {
            let edgeStart = includeHorizontalEdgePadding ? spacing.editorialStart : 0
            let edgeEnd = includeHorizontalEdgePadding ? spacing.editorialEnd : 0
            VStack(alignment: .leading, spacing: spacing.spacing1) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.homeSectionRecommendedSellersTitle)
                            .font(FashTypography.titleSmall.weight(.bold))
                            .foregroundStyle(FashColors.brandPrimary)
                        Text(L10n.homeSectionRecommendedSellersSubtitle)
                            .font(FashTypography.bodySmall)
                            .foregroundStyle(FashColors.textSecondary)
                    }
                    Spacer(minLength: 8)
                    FashSeeAllButton(action: onSeeAllClick)
                }
                .padding(.leading, edgeStart)
                .padding(.trailing, edgeEnd)
                .padding(.top, spacing.spacing2)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: spacing.spacing3) {
                        ForEach(sellers) { seller in
                            HomeCompactSellerStory(
                                seller: seller,
                                showAccentRing: !followingIds.contains(seller.userId) && !followingIds.contains(seller.username),
                                onClick: { onSellerClick(seller) }
                            )
                        }
                    }
                    .padding(.leading, edgeStart)
                    .padding(.trailing, edgeEnd)
                    .padding(.bottom, spacing.spacing4)
                }
            }
        }
    }
}

private struct HomeCompactSellerStory: View {
    let seller: FeaturedSellerItem
    var showAccentRing: Bool
    let onClick: () -> Void

    private let innerSize: CGFloat = 52
    private let ringStroke: CGFloat = 2
    private let ringGap: CGFloat = 2

    var body: some View {
        let handle = seller.username.isEmpty
            ? (seller.displayName.isEmpty ? "@…" : "@\(seller.displayName.prefix(18))")
            : "@\(seller.username)"
        let outer = innerSize + ringStroke * 2 + ringGap * 2

        Button(action: onClick) {
            VStack(spacing: 4) {
                ZStack {
                    if showAccentRing {
                        Circle()
                            .strokeBorder(FashColors.brandPrimary, lineWidth: ringStroke)
                            .frame(width: outer, height: outer)
                    }
                    FashAvatarCircle(url: seller.avatarUrl, size: innerSize)
                        .frame(width: innerSize, height: innerSize)
                        .clipShape(Circle())
                }
                .frame(width: outer, height: outer)
                .clipped()
                Text(handle)
                    .font(FashTypography.labelSmall)
                    .foregroundStyle(FashColors.textPrimary)
                    .lineLimit(1)
                    .frame(width: 76)
            }
        }
        .buttonStyle(.plain)
    }
}
