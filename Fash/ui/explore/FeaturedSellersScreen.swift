import SwiftUI

struct FeaturedSellersScreen: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps
    @Bindable var viewModel: FeaturedSellersViewModel
    var isGuestMode: Bool = false
    var onDismiss: () -> Void = {}
    var onSellerClick: (FeaturedSellerItem) -> Void = { _ in }
    var onListingClick: (String, String?) -> Void = { _, _ in }

    var body: some View {
        OverlayScreenHost(title: L10n.featuredSellersAllTitle, onDismiss: onDismiss) {
            ScrollView {
                if viewModel.isLoading && viewModel.items.isEmpty {
                    loadingSkeleton
                } else if viewModel.loadError && viewModel.items.isEmpty {
                    FashEmptyStateView(
                        title: L10n.feedLoadError,
                        subtitle: viewModel.loadErrorDetail,
                        actionTitle: L10n.feedRetry
                    ) {
                        Task { await viewModel.load(deps: deps, isGuestMode: isGuestMode) }
                    }
                    .padding(.horizontal, spacing.editorialStart)
                    .padding(.vertical, spacing.spacing4)
                } else if viewModel.items.isEmpty {
                    FashEmptyStateView(
                        title: L10n.feedEmptyTitle,
                        subtitle: L10n.feedEmptySubtitle
                    )
                    .padding(.horizontal, spacing.editorialStart)
                    .padding(.vertical, spacing.spacing4)
                } else {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        Text(L10n.featuredSellersAllSubtitle)
                            .font(FashTypography.bodyMedium)
                            .foregroundStyle(FashColors.textSecondary)
                            .padding(.bottom, 4)

                        ForEach(viewModel.items) { seller in
                            FeaturedSellerFullCard(
                                seller: seller,
                                previewCoverUrls: viewModel.previewCoverUrlsBySellerKey[seller.sellerKey] ?? [],
                                onSellerClick: { onSellerClick(seller) },
                                onListingClick: { listingId in
                                    onListingClick(listingId, seller.userId.isEmpty ? nil : seller.userId)
                                }
                            )
                            .task(id: seller.sellerKey) {
                                await viewModel.ensurePreviewCoversLoaded(seller, deps: deps, isGuestMode: isGuestMode)
                            }
                        }
                    }
                    .padding(.horizontal, spacing.editorialStart)
                    .padding(.top, 8)
                    .padding(.bottom, 24)
                }
            }
            .refreshable {
                await viewModel.refresh(deps: deps, isGuestMode: isGuestMode)
            }
        }
        .task {
            await viewModel.ensureLoaded(deps: deps, isGuestMode: isGuestMode)
        }
    }

    private var loadingSkeleton: some View {
        VStack(spacing: spacing.spacing3) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: spacing.spacing3) {
                    ForEach(0..<8, id: \.self) { _ in
                        VStack(spacing: 6) {
                            FashSkeleton.box(width: 60, height: 60, cornerRadius: 30)
                            FashSkeleton.box(width: 48, height: 10, cornerRadius: 4)
                        }
                    }
                }
                .padding(.horizontal, spacing.editorialStart)
            }
            ForEach(0..<3, id: \.self) { _ in
                FashSkeleton.box(height: 220, cornerRadius: spacing.radiusSoftMin)
                    .padding(.horizontal, spacing.editorialStart)
            }
        }
        .padding(.top, spacing.spacing3)
    }
}

private struct FeaturedSellerFullCard: View {
    @Environment(\.fashSpacing) private var spacing
    let seller: FeaturedSellerItem
    let previewCoverUrls: [String?]
    var onSellerClick: () -> Void
    var onListingClick: (String) -> Void

    private var cardShape: RoundedRectangle {
        RoundedRectangle(cornerRadius: spacing.radiusSoftMin, style: .continuous)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button(action: onSellerClick) {
                HStack(alignment: .top, spacing: 12) {
                    FashAvatarCircle(url: seller.avatarUrl, size: 64)
                    VStack(alignment: .leading, spacing: 0) {
                        HStack(spacing: 6) {
                            Text(displayName)
                                .font(FashTypography.titleSmall.weight(.semibold))
                                .foregroundStyle(FashColors.textPrimary)
                                .lineLimit(1)
                            if seller.verified {
                                Image(systemName: "checkmark.seal.fill")
                                    .font(.system(size: 18))
                                    .foregroundStyle(FashColors.brandPrimary)
                                    .accessibilityLabel(L10n.featuredSellersVerifiedCd)
                            }
                        }
                        if !seller.username.isEmpty {
                            Text("@\(seller.username.trimmingCharacters(in: .whitespaces))")
                                .font(FashTypography.bodySmall)
                                .foregroundStyle(FashColors.textSecondary)
                                .lineLimit(1)
                        }
                        Text(bioText)
                            .font(FashTypography.bodySmall)
                            .foregroundStyle(
                                seller.bio.trimmingCharacters(in: .whitespaces).isEmpty
                                    ? FashColors.textSecondary.opacity(0.75)
                                    : FashColors.textSecondary
                            )
                            .lineLimit(3)
                            .padding(.top, 6)
                        statsRow
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .buttonStyle(.plain)

            Divider()
                .overlay(FashColors.outlineMuted.opacity(0.35))
                .padding(.vertical, 12)

            Text(L10n.featuredSellersPreviewHeading)
                .font(FashTypography.labelLarge.weight(.semibold))
                .foregroundStyle(FashColors.textSecondary)
                .padding(.bottom, 8)

            let filledPreviewIds = seller.previewListingIds.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }.count
            if (1...2).contains(filledPreviewIds), seller.listingCount > 0 {
                ProfilePreviewPlaceholders.RowCaption(
                    previewCount: filledPreviewIds,
                    totalListingCount: seller.listingCount
                )
            }

            HStack(spacing: 6) {
                ForEach(0..<3, id: \.self) { index in
                    FeaturedSellerPreviewSlot(
                        listingId: seller.previewListingIds.indices.contains(index)
                            ? seller.previewListingIds[index].trimmingCharacters(in: .whitespaces)
                            : "",
                        coverUrl: previewCoverUrls.indices.contains(index) ? previewCoverUrls[index] : nil,
                        onListingClick: onListingClick
                    )
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(14)
        .background(FashColors.surfaceContainerLow)
        .clipShape(cardShape)
    }

    private var displayName: String {
        let name = seller.displayName.trimmingCharacters(in: .whitespaces)
        if !name.isEmpty { return name }
        let user = seller.username.trimmingCharacters(in: .whitespaces)
        return user.isEmpty ? "—" : user
    }

    private var bioText: String {
        let bio = seller.bio.trimmingCharacters(in: .whitespaces)
        return bio.isEmpty ? L10n.featuredSellersNoBio : bio
    }

    private var statsRow: some View {
        HStack(spacing: 8) {
            Text(L10n.featuredSellersStatFollowers(ProfileFormatting.formatCount(seller.followerCount)))
                .font(FashTypography.labelMedium)
                .foregroundStyle(FashColors.textPrimary)
            Text("·")
                .foregroundStyle(FashColors.outlineMuted)
            Text(L10n.productSellerListings(seller.listingCount))
                .font(FashTypography.labelMedium)
                .foregroundStyle(FashColors.textPrimary)
            if let rating = seller.averageRating {
                Text("·")
                    .foregroundStyle(FashColors.outlineMuted)
                Text(L10n.featuredSellersRatingValue(String(format: "%.1f", rating)))
                    .font(FashTypography.labelMedium)
                    .foregroundStyle(FashColors.textPrimary)
            }
        }
    }
}

private struct FeaturedSellerPreviewSlot: View {
    let listingId: String
    let coverUrl: String?
    var onListingClick: (String) -> Void

    var body: some View {
        Group {
            if listingId.isEmpty {
                ProfilePreviewPlaceholders.EmptySlot()
            } else {
                Button {
                    onListingClick(listingId)
                } label: {
                    ZStack {
                        if let coverUrl, !coverUrl.isEmpty {
                            FashAsyncImage(url: coverUrl)
                        } else {
                            Rectangle()
                                .fill(FashColors.surfaceContainerHigh)
                            ProgressView()
                                .tint(FashColors.brandPrimary)
                        }
                    }
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.featuredSellersPreviewListingCd(listingId))
            }
        }
        .aspectRatio(1, contentMode: .fit)
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}
