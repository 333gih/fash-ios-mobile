import SwiftUI

struct OrderDetailScreen: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps
    let orderId: String
    var onDismiss: () -> Void
    var onNavigateToPayment: (String, Int64, String) -> Void = { _, _, _ in }
    var onNavigateToChat: (String) -> Void = { _ in }
    var onOpenListing: (String, String) -> Void = { _, _ in }
    var onOpenUserProfile: (String) -> Void = { _ in }

    @State private var viewModel = OrderDetailViewModel()

    var body: some View {
        FashScreenScaffold(title: L10n.orderDetailTitle, showBack: true, onBack: onDismiss) {
            Group {
                if viewModel.isLoading, viewModel.detail == nil {
                    ProgressView().tint(FashColors.brandPrimary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let err = viewModel.loadError, viewModel.detail == nil {
                    FashEmptyStateView(title: err, actionTitle: L10n.feedRetry) {
                        Task { await viewModel.load(orderId: orderId, deps: deps) }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let detail = viewModel.detail {
                    detailScroll(detail)
                }
            }
            .background(FashColors.screen)
        }
        .overlay(alignment: .top) {
            if viewModel.isRefreshing {
                ProgressView().padding(.top, 8)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let detail = viewModel.detail {
                bottomActions(detail)
            }
        }
        .task(id: orderId) { await viewModel.load(orderId: orderId, deps: deps) }
        .alert(L10n.dialogTitleInfo, isPresented: Binding(
            get: { viewModel.toastMessage != nil },
            set: { if !$0 { viewModel.toastMessage = nil } }
        )) {
            Button(L10n.dialogOk) { viewModel.toastMessage = nil }
        } message: {
            Text(viewModel.toastMessage ?? "")
        }
    }

    @ViewBuilder
    private func detailScroll(_ detail: OrderDetailPayload) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacing.spacing3) {
                HStack {
                    OrderDetailComponents.statusBadge(detail.status)
                    Spacer()
                    if !detail.createdAt.isEmpty {
                        Text(OrderFormatting.formatShortDate(detail.createdAt))
                            .font(FashTypography.labelSmall)
                            .foregroundStyle(FashColors.textSecondary)
                    }
                }

                productCard(detail)

                counterpartyCard(detail)

                OrderDetailComponents.sectionCard {
                    Text(L10n.orderDetailPaymentBreakdownTitle)
                        .font(FashTypography.titleSmall.weight(.semibold))
                    OrderDetailComponents.infoRow(
                        L10n.orderDetailBuyerProductPrice,
                        FeedPriceFormat.format(detail.amountVnd > 0 ? detail.amountVnd : detail.listingPriceVnd)
                    )
                    if detail.shippingFeeVnd > 0 {
                        OrderDetailComponents.infoRow(
                            L10n.orderDetailBuyerShippingFee,
                            FeedPriceFormat.format(detail.shippingFeeVnd)
                        )
                    }
                    OrderDetailComponents.infoRow(
                        L10n.orderDetailBuyerTotal,
                        FeedPriceFormat.format(detail.effectiveBuyerTotal)
                    )
                }

                if !detail.shippingAddressFormatted.isEmpty || !detail.recipientName.isEmpty {
                    OrderDetailComponents.sectionCard {
                        Text(L10n.orderDetailShippingTitle)
                            .font(FashTypography.titleSmall.weight(.semibold))
                        if !detail.recipientName.isEmpty {
                            OrderDetailComponents.infoRow(L10n.checkoutFullName, detail.recipientName)
                        }
                        if !detail.recipientPhone.isEmpty {
                            OrderDetailComponents.infoRow(L10n.checkoutPhone, detail.recipientPhone)
                        }
                        if !detail.shippingAddressFormatted.isEmpty {
                            Text(detail.shippingAddressFormatted)
                                .font(FashTypography.bodyMedium)
                                .foregroundStyle(FashColors.textPrimary)
                        }
                        if !detail.trackingNumber.isEmpty {
                            OrderDetailComponents.infoRow(L10n.orderDetailTracking, detail.trackingNumber)
                        }
                        if !detail.trackingStatusSummary.isEmpty {
                            OrderDetailComponents.infoRow(L10n.orderDetailTracking, detail.trackingStatusSummary)
                        }
                    }
                }

                if let review = detail.buyerReview {
                    OrderDetailComponents.sectionCard {
                        Text(L10n.orderDetailBuyerReviewHeadingViewer)
                            .font(FashTypography.titleSmall.weight(.semibold))
                        Text("★ \(review.rating)")
                            .font(FashTypography.titleMedium)
                            .foregroundStyle(FashColors.brandPrimary)
                        if !review.comment.isEmpty {
                            Text(review.comment)
                                .font(FashTypography.bodyMedium)
                                .foregroundStyle(FashColors.textSecondary)
                        }
                    }
                }
            }
            .padding(.horizontal, spacing.editorialStart)
            .padding(.vertical, spacing.spacing3)
            .padding(.bottom, 88)
        }
    }

    private func productCard(_ detail: OrderDetailPayload) -> some View {
        Button {
            onOpenListing(detail.listingId, detail.sellerUserId)
        } label: {
            HStack(spacing: 12) {
                let img = FeedImageUrl.resolveListingImageUrlOrNil(detail.listingImageUrl)
                Group {
                    if let img {
                        FashAsyncImage(url: img, contentMode: .fill)
                    } else {
                        FashColors.surfaceVariant
                    }
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text(detail.listingTitle)
                        .font(FashTypography.titleSmall.weight(.bold))
                        .foregroundStyle(FashColors.textPrimary)
                        .lineLimit(2)
                    if !detail.listingVariantLabel.isEmpty {
                        Text(detail.listingVariantLabel)
                            .font(FashTypography.bodySmall)
                            .foregroundStyle(FashColors.textSecondary)
                    }
                    Text(FeedPriceFormat.format(detail.listingPriceVnd > 0 ? detail.listingPriceVnd : detail.amountVnd))
                        .font(FashTypography.labelLarge)
                        .foregroundStyle(FashColors.brandPrimary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(FashColors.textSecondary)
            }
            .padding(12)
            .background(FashColors.surfaceContainer)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func counterpartyCard(_ detail: OrderDetailPayload) -> some View {
        let isBuyer = viewModel.isCurrentUserBuyer(deps: deps)
        let username = isBuyer ? detail.sellerUsername : detail.buyerUsername
        let display = isBuyer
            ? (detail.sellerDisplayName.isEmpty ? detail.sellerUsername : detail.sellerDisplayName)
            : (detail.buyerDisplayName.isEmpty ? detail.buyerUsername : detail.buyerDisplayName)
        let avatar = isBuyer ? detail.sellerAvatarUrl : detail.buyerAvatarUrl
        let label = isBuyer ? L10n.orderDetailCounterpartySeller : L10n.orderDetailCounterpartyBuyer
        return OrderDetailComponents.sectionCard {
            Text(label)
                .font(FashTypography.labelMedium)
                .foregroundStyle(FashColors.textSecondary)
            Button {
                if !username.isEmpty { onOpenUserProfile(username) }
            } label: {
                HStack(spacing: 12) {
                    FashAvatarCircle(url: avatar, size: 44)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(display.isEmpty ? "—" : display)
                            .font(FashTypography.titleSmall.weight(.semibold))
                            .foregroundStyle(FashColors.textPrimary)
                        if !username.isEmpty {
                            Text("@\(username)")
                                .font(FashTypography.bodySmall)
                                .foregroundStyle(FashColors.textSecondary)
                        }
                    }
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            if !detail.conversationId.isEmpty {
                Button(L10n.orderDetailContinueInChat) {
                    onNavigateToChat(detail.conversationId)
                }
                .font(FashTypography.labelLarge)
                .foregroundStyle(FashColors.brandPrimary)
            }
        }
    }

    @ViewBuilder
    private func bottomActions(_ detail: OrderDetailPayload) -> some View {
        VStack(spacing: 8) {
            if viewModel.shouldShowPayButton(deps: deps), !detail.listingId.isEmpty {
                FashPrimaryButton(title: L10n.orderDetailPay) {
                    onNavigateToPayment(detail.listingId, detail.effectiveBuyerTotal, detail.orderId)
                }
            }
            if detail.canConfirmReceipt, viewModel.isCurrentUserBuyer(deps: deps) {
                Button {
                    Task { await viewModel.confirmReceipt(deps: deps) }
                } label: {
                    HStack {
                        if viewModel.busyAction == .confirmingReceipt {
                            ProgressView().scaleEffect(0.85)
                        }
                        Text(L10n.ordersConfirmReceived)
                    }
                    .font(FashTypography.labelLarge.weight(.semibold))
                    .foregroundStyle(FashColors.brandPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .stroke(FashColors.brandPrimary, lineWidth: 1)
                    )
                }
                .disabled(viewModel.busyAction == .confirmingReceipt)
            }
        }
        .padding(.horizontal, spacing.editorialStart)
        .padding(.vertical, 12)
        .background(FashColors.surfaceContainerHighest)
    }
}
