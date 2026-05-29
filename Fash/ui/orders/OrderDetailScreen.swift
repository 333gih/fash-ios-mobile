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
    @State private var showHelp = false
    @State private var showShip = false
    @State private var showReview = false
    @State private var showOpenDispute = false
    @State private var showDisputeEvidence = false
    @State private var showCancel = false
    @State private var showNoShow = false

    @State private var trackingNumber = ""
    @State private var carrierName = ""
    @State private var selectedCarrierId = ""
    @State private var reviewRating = 5
    @State private var reviewComment = ""
    @State private var openDisputeDescription = ""
    @State private var openDisputePhotos: [String] = []
    @State private var evidenceDescription = ""
    @State private var evidencePhotos: [String] = []
    @State private var noShowReason = "other_absent"
    @State private var noShowNote = ""

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
        .overlay(alignment: .topTrailing) {
            Button { showHelp = true } label: {
                Image(systemName: "questionmark.circle")
                    .font(.system(size: 20))
                    .foregroundStyle(FashColors.textPrimary)
                    .padding(12)
            }
        }
        .overlay(alignment: .top) {
            if viewModel.isRefreshing {
                ProgressView().padding(.top, 8)
            }
        }
        .safeAreaInset(edge: .bottom) {
            if let detail = viewModel.detail {
                stickyBottomBar(detail)
            }
        }
        .task(id: orderId) { await viewModel.load(orderId: orderId, deps: deps) }
        .onChange(of: viewModel.toastMessage) { _, message in
            guard let message, !message.isEmpty else { return }
            deps.showSnackbar(message)
            viewModel.toastMessage = nil
        }
        .alert(L10n.orderDetailHelpCd, isPresented: $showHelp) {
            Button(L10n.orderDetailHelpClose) {}
        } message: {
            Text(L10n.orderDetailHelpBody)
        }
        .sheet(isPresented: $showShip) { shipSheet }
        .sheet(isPresented: $showReview) { reviewSheet }
        .sheet(isPresented: $showOpenDispute) {
            OrderDetailDisputeSheet(
                isEvidence: false,
                description: $openDisputeDescription,
                photoUrls: $openDisputePhotos,
                busy: viewModel.busyAction,
                onDismiss: { showOpenDispute = false },
                onSubmit: {
                    await viewModel.openDispute(
                        description: openDisputeDescription,
                        photoUrls: openDisputePhotos,
                        deps: deps
                    )
                }
            )
        }
        .sheet(isPresented: $showDisputeEvidence) {
            OrderDetailDisputeSheet(
                isEvidence: true,
                description: $evidenceDescription,
                photoUrls: $evidencePhotos,
                busy: viewModel.busyAction,
                onDismiss: { showDisputeEvidence = false },
                onSubmit: {
                    await viewModel.submitDisputeEvidence(
                        description: evidenceDescription,
                        photoUrls: evidencePhotos,
                        deps: deps
                    )
                }
            )
        }
        .onChange(of: showOpenDispute) { _, open in
            if open {
                openDisputeDescription = ""
                openDisputePhotos = []
            }
        }
        .onChange(of: showDisputeEvidence) { _, open in
            if open {
                evidenceDescription = ""
                evidencePhotos = []
            }
        }
        .onChange(of: viewModel.detail?.status) { _, _ in
            if showOpenDispute,
               OrderFormatting.normalizeStatus(viewModel.detail?.status ?? "") == "disputed" {
                showOpenDispute = false
            }
        }
        .sheet(isPresented: $showCancel) {
            OrderCancelFlowSheet(orderId: orderId, onDismiss: { showCancel = false }) {
                Task { await viewModel.load(orderId: orderId, deps: deps) }
            }
        }
        .confirmationDialog(L10n.orderDetailNoShowDialogTitle, isPresented: $showNoShow, titleVisibility: .visible) {
            Button(L10n.orderDetailNoShowOtherAbsent) { noShowReason = "other_absent"; reportNoShow() }
            Button(L10n.orderDetailNoShowOtherLate) { noShowReason = "other_late"; reportNoShow() }
            Button(L10n.orderDetailNoShowMutualCancel) { noShowReason = "mutual_cancel"; reportNoShow() }
            Button(L10n.orderCancelConfirmDismiss, role: .cancel) {}
        }
    }

    private func detailScroll(_ detail: OrderDetailPayload) -> some View {
        let role = viewModel.viewerRole(deps: deps)
        return ScrollView {
            VStack(alignment: .leading, spacing: spacing.spacing3) {
                OrderDetailComponents.heroCard(detail: detail, role: role)
                OrderDetailComponents.timelineSection(detail: detail)
                OrderDetailComponents.meetupDeadlineStrip(detail: detail)
                OrderDetailComponents.meetingSection(detail: detail)
                OrderDetailComponents.meetingGraceSection(
                    detail: detail,
                    role: role,
                    busy: viewModel.busyAction,
                    onCheckIn: { Task { await viewModel.checkInAtMeeting(deps: deps) } },
                    onNoShow: { showNoShow = true },
                    onAckCash: { Task { await viewModel.acknowledgeOfflineCash(deps: deps) } }
                )
                if role == .buyer {
                    OrderDetailComponents.buyerShippingCard(detail: detail)
                }
                counterpartyCard(detail, role: role)
                productCard(detail)
                paymentCard(detail, role: role)
                OrderDetailComponents.trackingCard(detail: detail)
                OrderDetailComponents.buyerReviewSection(detail: detail, role: role)
            }
            .padding(.horizontal, spacing.editorialStart)
            .padding(.vertical, spacing.spacing3)
            .padding(.bottom, 120)
        }
    }

    private func paymentCard(_ detail: OrderDetailPayload, role: OrderViewerRole) -> some View {
        OrderDetailComponents.sectionCard {
            Text(role == .seller ? L10n.orderDetailSellerRevenueTitle : L10n.orderDetailPaymentBreakdownTitle)
                .font(FashTypography.titleSmall.weight(.semibold))
            OrderDetailComponents.infoRow(
                L10n.orderDetailBuyerProductPrice,
                FeedPriceFormat.format(detail.amountVnd > 0 ? detail.amountVnd : detail.listingPriceVnd)
            )
            if detail.shippingFeeVnd > 0 {
                OrderDetailComponents.infoRow(L10n.orderDetailBuyerShippingFee, FeedPriceFormat.format(detail.shippingFeeVnd))
            }
            if role == .seller, detail.platformFeeVnd > 0 {
                OrderDetailComponents.infoRow(L10n.orderDetailPlatformFee, FeedPriceFormat.format(detail.platformFeeVnd))
            }
            if role == .seller, detail.sellerPayoutVnd > 0 {
                OrderDetailComponents.infoRow(L10n.orderDetailSellerPayout, FeedPriceFormat.format(detail.sellerPayoutVnd))
            }
            OrderDetailComponents.infoRow(L10n.orderDetailBuyerTotal, FeedPriceFormat.format(detail.effectiveBuyerTotal))
        }
    }

    private func productCard(_ detail: OrderDetailPayload) -> some View {
        Button {
            onOpenListing(detail.listingId, detail.sellerUserId)
        } label: {
            HStack(spacing: 12) {
                let img = FeedImageUrl.resolveListingImageUrlOrNil(detail.listingImageUrl)
                Group {
                    if let img { FashAsyncImage(url: img, contentMode: .fill) }
                    else { FashColors.surfaceVariant }
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.orderDetailProduct)
                        .font(FashTypography.labelSmall)
                        .foregroundStyle(FashColors.textSecondary)
                    Text(detail.listingTitle)
                        .font(FashTypography.titleSmall.weight(.bold))
                        .foregroundStyle(FashColors.textPrimary)
                        .lineLimit(2)
                    if !detail.listingVariantLabel.isEmpty {
                        Text(detail.listingVariantLabel)
                            .font(FashTypography.bodySmall)
                            .foregroundStyle(FashColors.textSecondary)
                    }
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(FashColors.textSecondary)
            }
        }
        .buttonStyle(.plain)
        .padding(12)
        .background(FashColors.surfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func counterpartyCard(_ detail: OrderDetailPayload, role: OrderViewerRole) -> some View {
        let isBuyer = role == .buyer
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
                Button(L10n.orderDetailContinueInChat) { onNavigateToChat(detail.conversationId) }
                    .font(FashTypography.labelLarge)
                    .foregroundStyle(FashColors.brandPrimary)
            }
        }
    }

    @ViewBuilder
    private func stickyBottomBar(_ detail: OrderDetailPayload) -> some View {
        let role = viewModel.viewerRole(deps: deps)
        let st = OrderFormatting.normalizeStatus(detail.status)
        let idle = viewModel.busyAction == .none
        let showOpenDisputeCta = role != .viewer && (st == "in_transit" || st == "delivered_confirmed")
        let showDisputeEvidenceCta = role != .viewer && st == "disputed"
        let showReviewCta = detail.canReview && role == .buyer && detail.buyerReview == nil
        let showCancelCta = role == .buyer && OrderBuyerCancelPolicy.buyerCanCancel(status: st)
        let showChatCta = !detail.conversationId.isEmpty
            && (role == .buyer || role == .seller)
            && st != "cancelled"
        let hasPrimary = (role == .buyer && st == "payment_pending" && !detail.listingId.isEmpty)
            || (role == .buyer && (st == "fulfillment_pending" || st == "cash_meetup_open") && !detail.conversationId.isEmpty)
            || (role == .seller && OrderDetailLogic.sellerShowsConfirmHandoffCta(detail))
            || (role == .seller && st == "payment_held" && detail.canShip)
            || (detail.canConfirmReceipt && role == .buyer)
            || showCancelCta
        let hasSecondary = showReviewCta || showOpenDisputeCta || showDisputeEvidenceCta || showChatCta
        if !hasPrimary && !hasSecondary { EmptyView() }
        else {
            VStack(spacing: 8) {
                Divider().opacity(0.35)
                if role == .buyer, st == "payment_pending", !detail.listingId.isEmpty {
                    FashPrimaryButton(title: L10n.orderDetailPay) {
                        onNavigateToPayment(detail.listingId, detail.effectiveBuyerTotal, detail.orderId)
                    }
                }
                if role == .buyer, st == "fulfillment_pending" || st == "cash_meetup_open", !detail.conversationId.isEmpty {
                    Button(L10n.orderDetailContinueInChat) { onNavigateToChat(detail.conversationId) }
                        .font(FashTypography.labelLarge.weight(.semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(FashColors.brandPrimary)
                        .foregroundStyle(FashColors.onBrandPrimary)
                        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                if role == .seller, OrderDetailLogic.sellerShowsConfirmHandoffCta(detail) {
                    FashPrimaryButton(title: L10n.orderDetailConfirmHandoff, enabled: idle) {
                        Task { await viewModel.confirmHandoff(deps: deps) }
                    }
                } else if role == .seller, st == "payment_held", detail.canShip {
                    FashPrimaryButton(title: L10n.orderDetailActionShip, enabled: idle) {
                        Task { await viewModel.loadShipmentCarriers(deps: deps) }
                        showShip = true
                    }
                }
                if showCancelCta {
                    Button(L10n.orderCancelConfirmAction) { showCancel = true }
                        .font(FashTypography.labelLarge.weight(.medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(FashColors.error.opacity(0.4), lineWidth: 1)
                        )
                        .foregroundStyle(FashColors.error)
                        .disabled(!idle)
                }
                if detail.canConfirmReceipt, role == .buyer {
                    FashPrimaryButton(title: L10n.ordersConfirmReceived, enabled: idle) {
                        Task { await viewModel.confirmReceipt(deps: deps) }
                    }
                }
                if hasPrimary && hasSecondary {
                    Divider().opacity(0.22).padding(.vertical, 4)
                }
                if showReviewCta {
                    FashPrimaryButton(title: L10n.ordersReview, enabled: idle) { showReview = true }
                }
                if showOpenDisputeCta {
                    OrderDetailComponents.stickyOutlineButton(
                        title: L10n.orderDetailDisputeOpen,
                        isBusy: viewModel.busyAction == .openDispute,
                        enabled: idle
                    ) { showOpenDispute = true }
                }
                if showDisputeEvidenceCta {
                    OrderDetailComponents.stickyOutlineButton(
                        title: L10n.orderDetailDisputeEvidence,
                        isBusy: viewModel.busyAction == .submitEvidence,
                        enabled: idle
                    ) { showDisputeEvidence = true }
                }
                if showChatCta {
                    OrderDetailComponents.stickyOutlineButton(
                        title: role == .seller ? L10n.orderDetailChatBuyer : L10n.orderDetailChatSeller,
                        isBusy: false,
                        enabled: idle
                    ) { onNavigateToChat(detail.conversationId) }
                }
            }
            .padding(.horizontal, spacing.editorialStart)
            .padding(.top, 12)
            .padding(.bottom, 8)
            .background(FashColors.surfaceContainerLow)
        }
    }

    private var shipSheet: some View {
        NavigationStack {
            Form {
                if !viewModel.shipmentCarriers.isEmpty {
                    Section(L10n.orderDetailShipBookCarrier) {
                        Picker(L10n.orderDetailShipCarrierLabel, selection: $selectedCarrierId) {
                            Text("—").tag("")
                            ForEach(viewModel.shipmentCarriers) { c in
                                Text(c.name).tag(c.id)
                            }
                        }
                        if !selectedCarrierId.isEmpty {
                            Button(L10n.orderDetailShipConfirm) {
                                Task {
                                    await viewModel.bookShipment(carrierId: selectedCarrierId, deps: deps)
                                    showShip = false
                                }
                            }
                        }
                    }
                }
                Section(L10n.orderDetailShipManualSection) {
                    TextField(L10n.orderDetailShipTrackingLabel, text: $trackingNumber)
                    TextField(L10n.orderDetailShipCarrierLabel, text: $carrierName)
                    Button(L10n.orderDetailShipConfirm) {
                        Task {
                            await viewModel.shipOrder(tracking: trackingNumber, carrier: carrierName, deps: deps)
                            showShip = false
                        }
                    }
                }
            }
            .navigationTitle(L10n.orderDetailShipDialogTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.orderCancelConfirmDismiss) { showShip = false }
                }
            }
        }
    }

    private var reviewSheet: some View {
        NavigationStack {
            Form {
                Stepper("★ \(reviewRating)", value: $reviewRating, in: 1...5)
                TextField(L10n.orderDetailReviewCommentLabel, text: $reviewComment, axis: .vertical)
                    .lineLimit(3...8)
            }
            .navigationTitle(L10n.orderDetailReviewTitle)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.orderCancelConfirmDismiss) { showReview = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(L10n.orderDetailReviewSubmit) {
                        Task {
                            await viewModel.submitReview(
                                rating: reviewRating,
                                comment: reviewComment.nilIfEmpty,
                                deps: deps
                            )
                            showReview = false
                        }
                    }
                }
            }
        }
    }

    private func reportNoShow() {
        Task {
            await viewModel.reportMeetingNoShow(reason: noShowReason, note: noShowNote, deps: deps)
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
