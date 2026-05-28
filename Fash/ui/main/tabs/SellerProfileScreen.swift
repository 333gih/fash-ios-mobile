import SwiftUI

struct SellerProfileScreen: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps
    let username: String
    var isGuestMode: Bool = false
    var onDismiss: () -> Void
    var onListingClick: (String) -> Void = { _ in }

    @State private var viewModel = SellerProfileViewModel()
    @State private var promoSlides: [FashPromoSlideDef] = []

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
    ]

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    statsRow
                    followButton
                    tabSwitcher
                    listingsGrid
                        .padding(.bottom, promoSlides.isEmpty ? 24 : FashStickyPromoDockHeight + 16)
                }
            }
            if !promoSlides.isEmpty {
                StickyBottomPromoBar {
                    FashPromoSliderView(slides: promoSlides) { slide, _ in
                        onDismiss()
                        deps.navigationRouter?.handlePromoSlideClick(slide)
                    }
                }
            }
        }
        .background(FashColors.screen)
        .safeAreaInset(edge: .top) {
            HStack {
                Button(action: onDismiss) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 18, weight: .semibold))
                }
                Text(titleHandle)
                    .font(FashTypography.titleMedium.weight(.semibold))
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(FashColors.screen.opacity(0.95))
        }
        .task(id: username) {
            await viewModel.loadForSeller(username, deps: deps, isGuestMode: isGuestMode)
            if case .success(let response) = await deps.advertisingRepository.getSlides(publicBrowse: isGuestMode) {
                promoSlides = response.items.map(FashPromoSlideDef.fromAdvertising)
            }
        }
    }

    private var titleHandle: String {
        let h = username.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "@", with: "")
        return h.isEmpty ? "—" : "@\(h)"
    }

    @ViewBuilder
    private var header: some View {
        ZStack(alignment: .bottomLeading) {
            coverImage
                .frame(height: 160)
                .frame(maxWidth: .infinity)
                .clipped()
            HStack(alignment: .bottom, spacing: 12) {
                FashAvatarCircle(url: viewModel.profile?.avatarUrl, size: 72)
                    .overlay(Circle().strokeBorder(FashColors.screen, lineWidth: 3))
                    .offset(y: 24)
                Spacer()
            }
            .padding(.leading, spacing.editorialStart)
        }
        .padding(.bottom, 28)
        if let name = viewModel.profile?.displayName.nilIfEmpty {
            Text(name)
                .font(FashTypography.titleMedium.weight(.bold))
                .foregroundStyle(FashColors.textPrimary)
                .padding(.horizontal, spacing.editorialStart)
        }
        if let bio = viewModel.profile?.bio.nilIfEmpty {
            Text(bio)
                .font(FashTypography.bodySmall)
                .foregroundStyle(FashColors.textSecondary)
                .padding(.horizontal, spacing.editorialStart)
                .padding(.top, 4)
        }
    }

    @ViewBuilder
    private var coverImage: some View {
        if let cover = viewModel.profile?.coverImageUrl.nilIfEmpty,
           let resolved = FeedImageUrl.resolveProfileImageUrlOrNil(cover) {
            FashAsyncImage(url: resolved, contentMode: .fill)
        } else {
            LinearGradient(
                colors: [FashColors.brandPrimary.opacity(0.55), FashColors.surfaceContainerHigh],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var statsRow: some View {
        HStack(spacing: spacing.spacing4) {
            statItem("\(viewModel.profile?.followerCount ?? 0)", L10n.profileFollowers)
            statItem("\(viewModel.profile?.productCount ?? 0)", L10n.profileProducts)
        }
        .padding(.horizontal, spacing.editorialStart)
        .padding(.top, spacing.spacing3)
    }

    private func statItem(_ value: String, _ label: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(value)
                .font(FashTypography.titleSmall.weight(.bold))
            Text(label)
                .font(FashTypography.bodySmall)
                .foregroundStyle(FashColors.textSecondary)
        }
    }

    @ViewBuilder
    private var followButton: some View {
        if viewModel.profile != nil {
            Button {
                Task { await viewModel.toggleFollow(deps: deps, isGuestMode: isGuestMode) }
            } label: {
                HStack {
                    if viewModel.followInFlight { ProgressView().scaleEffect(0.8) }
                    Text(viewModel.isFollowing ? L10n.followFollowing : L10n.followButton)
                }
                .font(FashTypography.labelLarge)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(viewModel.isFollowing ? FashColors.surfaceContainer : FashColors.brandPrimary)
                .foregroundStyle(viewModel.isFollowing ? FashColors.textPrimary : FashColors.onBrandPrimary)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(viewModel.followInFlight || (!isGuestMode && !viewModel.canFollow(deps: deps)))
            .padding(.horizontal, spacing.editorialStart)
            .padding(.top, spacing.spacing3)
        }
    }

    private var tabSwitcher: some View {
        HStack(spacing: spacing.spacing2) {
            tabButton(L10n.profileTabSelling, 0)
            tabButton(L10n.profileTabSold, 1)
            Spacer()
        }
        .padding(.horizontal, spacing.editorialStart)
        .padding(.top, spacing.spacing4)
    }

    private func tabButton(_ title: String, _ index: Int) -> some View {
        let selected = viewModel.selectedTab == index
        return Button {
            viewModel.selectedTab = index
        } label: {
            Text(title)
                .font(FashTypography.labelLarge)
                .foregroundStyle(selected ? FashColors.brandPrimary : FashColors.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(selected ? FashColors.surfaceContainerHigh : Color.clear)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var listingsGrid: some View {
        if viewModel.isLoading && viewModel.profile == nil {
            ProgressView().frame(maxWidth: .infinity).padding()
        } else if viewModel.loadError {
            FashEmptyStateView(title: L10n.feedLoadError, actionTitle: L10n.feedRetry) {
                Task { await viewModel.loadForSeller(username, deps: deps, isGuestMode: isGuestMode) }
            }
        } else {
            let items = viewModel.listingsForSelectedTab
            if items.isEmpty {
                FashEmptyStateView(title: L10n.feedEmptyTitle, subtitle: L10n.feedEmptySubtitle)
                    .padding()
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(items) { item in
                        ListingGridCard(item: item) {
                            onListingClick(item.id)
                        }
                    }
                }
                .padding(.horizontal, spacing.editorialStart)
                .padding(.top, spacing.spacing3)
            }
        }
    }
}
