import SwiftUI

struct SellerProfileScreen: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps
    let username: String
    var isGuestMode: Bool = false
    var onDismiss: () -> Void
    var onListingClick: (String) -> Void = { _ in }
    var onRequestSignIn: (() -> Void)? = nil
    var onNavigateToExploreFromProfile: (
        _ categoryId: String?,
        _ brandId: String?,
        _ aestheticTagId: String?,
        _ searchQuery: String,
        _ countryId: String?,
        _ countryIso2: String?
    ) -> Void = { _, _, _, _, _, _ in }

    @State private var viewModel = SellerProfileViewModel()
    @State private var promoSlides: [FashPromoSlideDef] = []
    @State private var showPromoFooter = false

    private var promoBottomInset: CGFloat {
        showPromoFooter && !promoSlides.isEmpty ? FashStickyPromoDockHeight : 0
    }

    private var showBlockingLoadError: Bool {
        viewModel.loadError && viewModel.profile == nil && !viewModel.isLoading && !viewModel.isRefreshing
    }

    var body: some View {
        VStack(spacing: 0) {
            sellerTopBar
            ZStack(alignment: .bottom) {
                Group {
                    if showBlockingLoadError {
                        FashEmptyStateView(title: L10n.profileLoadError, actionTitle: L10n.feedRetry) {
                            Task { await viewModel.loadForSeller(username, deps: deps, isGuestMode: isGuestMode) }
                        }
                    } else {
                        ProfileCollapsingScrollLayout(
                            selectedTab: $viewModel.selectedTab,
                            tabSet: .sellerStorefront,
                            items: viewModel.listingsForSelectedTab,
                            showQuickActions: true,
                            showStatusOverlay: true,
                            additionalBottomInset: promoBottomInset,
                            showGridLoading: viewModel.profile == nil && (viewModel.isLoading || viewModel.isRefreshing),
                            isRefreshing: viewModel.isRefreshing,
                            onTabsPinnedAtTopChange: { pinned in
                                showPromoFooter = pinned
                            },
                            onListingClick: { item in onListingClick(item.id) },
                            onLike: { item in
                                if isGuestMode { onRequestSignIn?() }
                                else { Task { await viewModel.toggleLike(item, deps: deps) } }
                            },
                            onSave: { item in
                                if isGuestMode { onRequestSignIn?() }
                                else { Task { await viewModel.toggleSave(item, deps: deps) } }
                            },
                            expandedHeader: { expandedHeader },
                            compactHeader: { ProfileCompactHeaderBar(profile: viewModel.profile) }
                        )
                        .refreshable {
                            await viewModel.loadForSeller(username, deps: deps, isGuestMode: isGuestMode, force: true)
                        }
                    }
                }

                if !promoSlides.isEmpty {
                    StickyBottomPromoBar {
                        FashPromoSliderView(slides: promoSlides) { slide, _ in
                            onDismiss()
                            deps.navigationRouter?.handlePromoSlideClick(slide)
                        }
                    }
                    .opacity(showPromoFooter ? 1 : 0)
                    .allowsHitTesting(showPromoFooter)
                    .accessibilityHidden(!showPromoFooter)
                }
            }
        }
        .background(FashColors.screen)
        .onChange(of: username) { _, _ in
            showPromoFooter = false
            viewModel.selectedTab = SellerProfileTab.selling.rawValue
        }
        .task(id: username) {
            await viewModel.loadForSeller(username, deps: deps, isGuestMode: isGuestMode)
            if case .success(let response) = await deps.advertisingRepository.getSlides(publicBrowse: isGuestMode) {
                promoSlides = response.items.map(FashPromoSlideDef.fromAdvertising)
            }
        }
    }

    private var sellerTopBar: some View {
        HStack(spacing: 8) {
            FashBackButton(action: onDismiss)
            Text(titleHandle)
                .font(FashTypography.titleMedium.weight(.semibold))
                .lineLimit(1)
            Spacer()
            if !titleHandle.isEmpty, titleHandle != "—" {
                Button {
                    let handle = username.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "@", with: "")
                    ProfileShare.launch(
                        username: handle,
                        displayName: viewModel.profile?.displayName
                    ) { completed in
                        FashActivityShare.showSuccessIfNeeded(
                            completed,
                            message: L10n.shareProfileSuccess,
                            deps: deps
                        )
                    }
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(FashColors.brandPrimary)
                }
            }
        }
        .padding(.leading, FashBackButton.leadingScreenInset)
        .padding(.trailing, 12)
        .padding(.vertical, 8)
        .background(FashColors.screen)
    }

    @ViewBuilder
    private var expandedHeader: some View {
        ProfileHeroSection(
            coverImageUrl: viewModel.profile?.coverImageUrl,
            avatarUrl: viewModel.profile?.avatarUrl
        )
        ProfileIdentityBlock(
            profile: viewModel.profile,
            showEditButton: false,
            aestheticCatalog: viewModel.aestheticCatalog,
            onAestheticTagClick: { _, tagId in
                onNavigateToExploreFromProfile(nil, nil, tagId, "", nil, nil)
            }
        )
        if viewModel.canShowFollowUi(deps: deps, isGuestMode: isGuestMode) {
            SellerProfileFollowBlock(
                isFollowing: viewModel.isFollowing && !isGuestMode,
                inFlight: viewModel.followInFlight,
                onToggle: {
                    if isGuestMode { onRequestSignIn?() }
                    else { Task { await viewModel.toggleFollow(deps: deps, isGuestMode: isGuestMode) } }
                }
            )
        }
        SellerProfileMetricsCard(profile: viewModel.profile)
        SellerProfileBodyMeasurements(profile: viewModel.profile)
        SellerProfileTopBadges(profile: viewModel.profile)
        SellerListingFocusSection(
            focus: viewModel.sellerFocus,
            forbidden: viewModel.sellerFocusForbidden,
            loading: viewModel.sellerFocusLoading,
            aestheticCatalog: viewModel.aestheticCatalog,
            onCategory: { id, _ in onNavigateToExploreFromProfile(id, nil, nil, "", nil, nil) },
            onBrand: { id, _ in onNavigateToExploreFromProfile(nil, id, nil, "", nil, nil) },
            onAesthetic: { id, _ in onNavigateToExploreFromProfile(nil, nil, id, "", nil, nil) }
        )
    }

    private var titleHandle: String {
        let h = username.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "@", with: "")
        return h.isEmpty ? "—" : "@\(h)"
    }
}
