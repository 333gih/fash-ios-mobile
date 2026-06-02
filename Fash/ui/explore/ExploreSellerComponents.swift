import SwiftUI

// MARK: - Featured sellers story row (Explore sellers tab)

struct ExploreFeaturedSellersSection: View {
    @Environment(\.fashSpacing) private var spacing
    let sellers: [FeaturedSellerItem]
    var followingIds: Set<String> = []
    var onSellerClick: (FeaturedSellerItem) -> Void
    var onSeeAllClick: () -> Void

    var body: some View {
        if sellers.isEmpty { EmptyView() } else {
            VStack(alignment: .leading, spacing: spacing.spacing2) {
                HStack(alignment: .top) {
                    Text(L10n.exploreFeaturedSellers)
                        .font(FashTypography.titleSmall.weight(.semibold))
                        .foregroundStyle(FashColors.textPrimary)
                    Spacer(minLength: 8)
                    FashSeeAllButton(action: onSeeAllClick)
                }

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: spacing.spacing3) {
                        ForEach(sellers) { seller in
                            ExploreFeaturedSellerStoryChip(
                                seller: seller,
                                showAccentRing: !followingIds.contains(seller.userId)
                                    && !followingIds.contains(seller.username),
                                onClick: { onSellerClick(seller) }
                            )
                        }
                    }
                }
            }
        }
    }
}

private struct ExploreFeaturedSellerStoryChip: View {
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
                }
                .frame(width: outer, height: outer)
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

// MARK: - Seller TikTok-style card

struct ExploreSellerTikTokCard: View {
    @Environment(\.fashSpacing) private var spacing
    let user: UserSearchResult
    /// `nil` = previews still loading.
    let previewPosts: [ListingFeedItem]?
    var onSellerClick: () -> Void
    var onListingClick: (ListingFeedItem) -> Void

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: spacing.radiusSoftMin, style: .continuous)
        VStack(alignment: .leading, spacing: 10) {
            Button(action: onSellerClick) {
                HStack(spacing: 12) {
                    FashAvatarCircle(url: user.avatarUrl, size: 52)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.displayName.isEmpty ? user.username : user.displayName)
                            .font(FashTypography.titleSmall.weight(.semibold))
                            .foregroundStyle(FashColors.textPrimary)
                            .lineLimit(1)
                        if !user.username.isEmpty {
                            Text("@\(user.username)")
                                .font(FashTypography.bodySmall)
                                .foregroundStyle(FashColors.textSecondary)
                                .lineLimit(1)
                        }
                        Text(sellerStatsLine)
                            .font(FashTypography.labelSmall)
                            .foregroundStyle(FashColors.textSecondary)
                            .lineLimit(2)
                    }
                    Spacer(minLength: 0)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(FashColors.brandPrimary.opacity(0.75))
                }
            }
            .buttonStyle(.plain)

            previewStrip
        }
        .padding(12)
        .background(FashColors.surfaceContainerLow)
        .clipShape(shape)
    }

    private var sellerStatsLine: String {
        let followers = "\(ProfileFormatting.formatCount(user.followerCount)) \(L10n.exploreFollowers)"
        if user.listingCount > 0 {
            return "\(followers) · \(L10n.productSellerListings(user.listingCount))"
        }
        return followers
    }

    @ViewBuilder
    private var previewStrip: some View {
        if previewPosts == nil {
            FashSkeleton.box(height: 132, cornerRadius: spacing.radiusSoftMin)
        } else if previewPosts?.isEmpty == true {
            ExploreSellerNoListingsBanner()
        } else {
            HStack(spacing: 5) {
                ForEach(0..<3, id: \.self) { index in
                    let item = previewPosts?.indices.contains(index) == true ? previewPosts?[index] : nil
                    ExploreSellerPreviewSlot(item: item, onTap: item.map { listing in { onListingClick(listing) } })
                }
            }
        }
    }
}

private struct ExploreSellerPreviewSlot: View {
    let item: ListingFeedItem?
    var onTap: (() -> Void)?

    var body: some View {
        GeometryReader { geo in
            Group {
                if let item, let onTap {
                    Button(action: onTap) {
                        ZStack(alignment: .bottom) {
                            if let url = FeedImageUrl.resolveListingImageUrlOrNil(item.coverImageUrl) {
                                FashAsyncImage(url: url)
                                    .frame(width: geo.size.width, height: geo.size.width)
                                    .clipped()
                            } else {
                                FashColors.surfaceContainerHigh
                            }
                            Text(FeedPriceFormat.format(item.priceVnd))
                                .font(FashTypography.labelSmall.weight(.semibold))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.horizontal, 4)
                                .padding(.vertical, 4)
                                .background(Color.black.opacity(0.42))
                        }
                    }
                    .buttonStyle(.plain)
                } else {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(FashColors.surfaceContainerHigh)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

struct ExploreSellerNoListingsBanner: View {
    @Environment(\.fashSpacing) private var spacing

    var body: some View {
        VStack(spacing: 6) {
            Text(L10n.exploreSellerNoListingsTitle)
                .font(FashTypography.titleSmall.weight(.semibold))
                .foregroundStyle(FashColors.textPrimary)
                .multilineTextAlignment(.center)
            Text(L10n.exploreSellerNoListingsSubtitle)
                .font(FashTypography.bodySmall)
                .foregroundStyle(FashColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 14)
        .padding(.vertical, 16)
        .background(FashColors.surfaceContainerHigh)
        .clipShape(RoundedRectangle(cornerRadius: spacing.radiusSoftMin, style: .continuous))
    }
}

// MARK: - Search banner

struct ExploreActiveSearchQueryBanner: View {
    @Environment(\.fashSpacing) private var spacing
    let query: String
    var onClear: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Text(query)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textPrimary)
                .lineLimit(1)
            Spacer(minLength: 0)
            Button(L10n.exploreSearchClearActive, action: onClear)
                .font(FashTypography.labelMedium)
                .foregroundStyle(FashColors.brandPrimary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(FashColors.surfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: spacing.radiusSoftMin, style: .continuous))
    }
}

// MARK: - Quick interest chips

struct ExploreInterestChipsRow: View {
    @Environment(\.fashSpacing) private var spacing
    let chips: [String]
    let selectedChipNames: Set<String>
    var onChipClick: (String) -> Void

    var body: some View {
        if chips.isEmpty { EmptyView() } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(chips, id: \.self) { chip in
                        let selected = selectedChipNames.contains { $0.caseInsensitiveCompare(chip) == .orderedSame }
                        Button { onChipClick(chip) } label: {
                            Text(chip)
                                .font(FashTypography.labelMedium)
                                .foregroundStyle(selected ? FashColors.onBrandPrimary : FashColors.textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(selected ? FashColors.brandPrimary : FashColors.surfaceContainer)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, spacing.editorialStart)
            }
        }
    }
}

// MARK: - Personal filter pills

struct ExploreActivePersonalFilterChips: View {
    @Environment(\.fashSpacing) private var spacing
    var sizingActive: Bool
    var seasonContextLabel: String? = nil
    var onClearSizing: () -> Void
    var onOpenFilters: () -> Void

    var body: some View {
        let season = seasonContextLabel?.trimmingCharacters(in: .whitespaces)
        if !sizingActive && (season == nil || season?.isEmpty == true) {
            EmptyView()
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    if sizingActive {
                        filterPill(L10n.exploreFilterSummarySizingMatch, onClear: onClearSizing)
                    }
                    if let season, !season.isEmpty {
                        seasonPill(season)
                    }
                    Button(L10n.exploreFiltersShow, action: onOpenFilters)
                        .font(FashTypography.labelMedium)
                        .foregroundStyle(FashColors.brandPrimary)
                }
                .padding(.horizontal, spacing.editorialStart)
            }
        }
    }

    private func seasonPill(_ label: String) -> some View {
        Text(label)
            .font(FashTypography.labelMedium)
            .foregroundStyle(FashColors.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(FashColors.surfaceVariant.opacity(0.65))
            .clipShape(Capsule())
            .lineLimit(1)
    }

    private func filterPill(_ label: String, onClear: @escaping () -> Void) -> some View {
        HStack(spacing: 4) {
            Text(label)
                .font(FashTypography.labelMedium)
                .foregroundStyle(FashColors.brandPrimary)
            Button(action: onClear) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(FashColors.brandPrimary)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(FashColors.brandPrimary.opacity(0.12))
        .clipShape(Capsule())
    }
}
