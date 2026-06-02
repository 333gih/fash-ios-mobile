import SwiftUI

struct ProductDetailScreen: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps

    let listingId: String
    var isGuestMode: Bool = false
    var onDismiss: () -> Void
    var onBuyNow: (String) -> Void = { _ in }
    var onContinueOrder: (String) -> Void = { _ in }
    var onChat: (String) -> Void = { _ in }
    var onShare: (String, String) -> Void = { _, _ in }
    var onListingClick: (String) -> Void = { _ in }
    var onVisitSellerShop: (String) -> Void = { _ in }
    var onRequestLogin: () -> Void = {}
    var onNavigateToExplore: (
        _ categoryId: String?,
        _ brandId: String?,
        _ aestheticTagId: String?,
        _ searchQuery: String,
        _ countryId: String?,
        _ countryIso2: String?
    ) -> Void = { _, _, _, _, _, _ in }

    @State private var viewModel = ProductDetailViewModel()
    @State private var showShippingInfo = false
    @State private var showSaveNudge = false
    @State private var sharePayload: SharePayload?

    private var buyNowEnabled: Bool { BusinessFlowConfig.c2cBuyNowEnabled }

    var body: some View {
        ZStack(alignment: .top) {
            content
            topBar
        }
        .background(FashColors.screen)
        .safeAreaInset(edge: .bottom) { bottomBar }
        .task(id: listingId) { await viewModel.load(listingId: listingId, deps: deps) }
        .alert(L10n.productShippingInfoTitle, isPresented: $showShippingInfo) {
            Button(L10n.dialogOk) {}
        } message: {
            Text(L10n.productShippingInfoBody)
        }
        .alert(L10n.productPurchaseGuideTitle, isPresented: Binding(
            get: { viewModel.showPurchaseGuide },
            set: { viewModel.showPurchaseGuide = $0 }
        )) {
            Button(L10n.productPurchaseGuideGotIt) { viewModel.dismissPurchaseGuide(deps: deps) }
        } message: {
            Text(buyNowEnabled ? L10n.productPurchaseGuideBody : L10n.productPurchaseGuideBodyNoBuyNow)
        }
        .alert(L10n.dialogTitleInfo, isPresented: Binding(
            get: { viewModel.snackbarMessage != nil },
            set: { if !$0 { viewModel.snackbarMessage = nil } }
        )) {
            Button(L10n.dialogOk) { viewModel.snackbarMessage = nil }
        } message: {
            Text(viewModel.snackbarMessage ?? "")
        }
        .sheet(item: $sharePayload) { payload in
            ActivityShareSheet(items: payload.items) { completed in
                FashActivityShare.showSuccessIfNeeded(
                    completed,
                    message: L10n.shareListingSuccess,
                    deps: deps
                )
            }
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.isLoading, viewModel.detail == nil {
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if let err = viewModel.loadError, viewModel.detail == nil {
            FashEmptyStateView(title: err, actionTitle: L10n.feedRetry) {
                Task { await viewModel.load(listingId: listingId, deps: deps) }
            }
        } else if let detail = viewModel.detail {
            ScrollView {
                VStack(alignment: .leading, spacing: spacing.spacing3) {
                    ProductDetailComponents.heroImage(
                        detail: detail,
                        galleryIndex: $viewModel.galleryIndex,
                        onLike: { guestGate { Task { await viewModel.toggleLike(deps: deps) } } },
                        onSave: {
                            guestGate {
                                Task {
                                    let wasSaved = detail.isSaved
                                    let added = await viewModel.toggleSave(deps: deps)
                                    if added, !wasSaved { showSaveNudge = true }
                                }
                            }
                        }
                    )
                    if viewModel.bottomBarMode != .normal {
                        ProductDetailComponents.statusBanner(mode: viewModel.bottomBarMode)
                            .padding(.horizontal, spacing.editorialStart)
                    }
                    ProductDetailComponents.sellerCard(
                        detail: detail,
                        profile: viewModel.sellerProfile,
                        isFollowing: viewModel.isFollowing,
                        onVisitShop: {
                            if let handle = sellerShopHandle(from: detail) {
                                onVisitSellerShop(handle)
                            }
                        },
                        onFollow: { guestGate { Task { await viewModel.follow(deps: deps) } } },
                        onUnfollow: { Task { await viewModel.unfollow(deps: deps) } }
                    )
                    .padding(.horizontal, spacing.editorialStart)
                    ProductDetailComponents.priceInfoCard(detail: detail) { catId, _ in
                        onNavigateToExplore(catId, nil, nil, detail.category ?? "", detail.countryId, detail.countryIso2)
                    }
                    .padding(.horizontal, spacing.editorialStart)
                    if let order = viewModel.buyerActiveOrder, order.amountVnd >= 1000 {
                        DealAgreedPriceBannerView(
                            amountVnd: order.amountVnd,
                            fromBuyNow: order.status.lowercased() == "payment_pending"
                        )
                        .padding(.horizontal, spacing.editorialStart)
                    }
                    ProductDetailComponents.atGlanceCard(detail: detail, onBrandTap: {
                        onNavigateToExplore(nil, detail.brandId, nil, detail.brand ?? "", nil, nil)
                    }, onOriginTap: {
                        onNavigateToExplore(nil, nil, nil, detail.countryName ?? "", detail.countryId, detail.countryIso2)
                    })
                    .padding(.horizontal, spacing.editorialStart)
                    ProductDetailComponents.measurementsCard(detail: detail)
                        .padding(.horizontal, spacing.editorialStart)
                    ProductDetailComponents.shippingCard(detail: detail, showInfo: $showShippingInfo)
                        .padding(.horizontal, spacing.editorialStart)
                    ProductDetailComponents.aboutCard(detail: detail) { tag in
                        onNavigateToExplore(nil, nil, tag.id, tag.label, nil, nil)
                    }
                    .padding(.horizontal, spacing.editorialStart)
                    ProductDetailDiscoveryHub(
                        current: detail,
                        entries: viewModel.discoveryFeed,
                        isLoading: viewModel.isDiscoveryLoading,
                        onListingTap: onListingClick,
                        onLike: { item in guestGate { Task { await viewModel.toggleLikeRailItem(item, deps: deps) } } },
                        onSave: { item in guestGate { Task { await viewModel.toggleSaveRailItem(item, deps: deps) } } }
                    )
                    if showSaveNudge {
                        saveNudge
                            .padding(.horizontal, spacing.editorialStart)
                    }
                    Spacer(minLength: 100)
                }
                .padding(.top, 56)
            }
        }
    }

    private var topBar: some View {
        HStack {
            FashBackButton(action: onDismiss)
            Spacer()
            Text(L10n.productDetailTitle)
                .font(FashTypography.titleSmall.weight(.semibold))
                .foregroundStyle(FashColors.textPrimary)
            Spacer()
            if viewModel.detail != nil {
                Button {
                    guard let d = viewModel.detail else { return }
                    viewModel.reportShare(deps: deps)
                    let web = AppEnvironment.listingShareURL(listingId: d.id)
                    let fashUri = ListingDeepLinks.fashListingURL(listingId: d.id)?.absoluteString ?? ""
                    let title = d.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? L10n.productDetailTitle
                        : d.title
                    let text = L10n.shareListingText(title, web, fashUri)
                    sharePayload = SharePayload(items: [L10n.shareListingSubject, text])
                    onShare(d.id, d.title)
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(FashColors.brandPrimary)
                        .frame(width: 44, height: 44)
                }
            } else {
                Color.clear.frame(width: 44, height: 44)
            }
        }
        .padding(.leading, FashBackButton.leadingScreenInset)
        .padding(.trailing, 8)
        .background(FashColors.screen.opacity(0.92))
    }

    @ViewBuilder
    private var bottomBar: some View {
        if viewModel.detail != nil {
            VStack(spacing: 10) {
                switch viewModel.bottomBarMode {
                case .sold:
                    Text(L10n.productListingSoldBar)
                        .font(FashTypography.labelLarge.weight(.semibold))
                        .foregroundStyle(FashColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                case .reservedOther:
                    Text(L10n.productReservedOther)
                        .font(FashTypography.labelLarge.weight(.semibold))
                        .foregroundStyle(FashColors.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                case .reservedBuyer:
                    if let order = viewModel.buyerActiveOrder {
                        Text(L10n.productReservedBuyerContinue(FeedPriceFormat.format(order.amountVnd)))
                            .font(FashTypography.bodySmall)
                            .foregroundStyle(FashColors.textSecondary)
                            .multilineTextAlignment(.center)
                        FashPrimaryButton(title: L10n.productContinueCheckout) {
                            onContinueOrder(order.orderId)
                        }
                    }
                case .normal:
                    if buyNowEnabled, let listingId = viewModel.detail?.id {
                        FashPrimaryButton(title: L10n.buyNow) { onBuyNow(listingId) }
                    }
                    messageButton(outlined: buyNowEnabled)
                }
            }
            .padding(.horizontal, spacing.editorialStart)
            .padding(.vertical, 12)
            .background(FashColors.surfaceContainerHighest)
        }
    }

    private func messageButton(outlined: Bool) -> some View {
        Button {
            Task {
                if let convId = await viewModel.openChat(deps: deps) { onChat(convId) }
            }
        } label: {
            HStack {
                if viewModel.isOpeningChat { ProgressView().scaleEffect(0.8) }
                Image(systemName: "message")
                Text(L10n.productChat)
            }
            .font(FashTypography.labelLarge.weight(.semibold))
            .foregroundStyle(outlined ? FashColors.brandPrimary : FashColors.onBrandPrimary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(outlined ? Color.clear : FashColors.brandPrimary)
            .overlay {
                if outlined {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(FashColors.brandPrimary, lineWidth: 1)
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .disabled(viewModel.isOpeningChat)
    }

    private var saveNudge: some View {
        HStack {
            Text(L10n.productSaveNudge)
                .font(FashTypography.bodySmall)
            Spacer()
            Button(L10n.productSaveNudgeCta) {
                showSaveNudge = false
                Task { if let convId = await viewModel.openChat(deps: deps) { onChat(convId) } }
            }
            .font(FashTypography.labelMedium.weight(.semibold))
            .foregroundStyle(FashColors.brandPrimary)
            Button(L10n.productSaveNudgeDismiss) { showSaveNudge = false }
                .font(FashTypography.labelMedium)
                .foregroundStyle(FashColors.textSecondary)
        }
        .padding(12)
        .background(FashColors.surfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func sellerShopLabel(from detail: ListingDetail) -> String {
        detail.sellerUsername?.nilIfEmpty
            ?? detail.sellerDisplayName?.nilIfEmpty
            ?? L10n.explorePreviewSellerUsernameFallback
    }

    private func guestGate(_ action: () -> Void) {
        if isGuestMode { onRequestLogin() } else { action() }
    }
}

private struct SharePayload: Identifiable {
    let id = UUID()
    let items: [Any]
}

private func sellerShopHandle(from detail: ListingDetail) -> String? {
    detail.sellerUsername?.nilIfEmpty ?? detail.sellerId?.nilIfEmpty
}

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
