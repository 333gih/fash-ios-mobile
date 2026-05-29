import SwiftUI

struct OrdersScreen: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps
    @State private var internalViewModel = OrdersViewModel()
    var viewModel: OrdersViewModel? = nil
    var embeddedInMainNav: Bool = false
    var promoSlides: [FashPromoSlideDef] = []
    var onPromoSlideClick: (FashPromoSlideDef, Int) -> Void = { _, _ in }
    var onDismiss: () -> Void
    var onSelectOrder: (String) -> Void

    private var activeVM: OrdersViewModel {
        if let viewModel { return viewModel }
        return internalViewModel
    }

    private var promoDockInset: CGFloat {
        promoSlides.isEmpty ? 0 : FashStickyPromoDockHeight
    }

    var body: some View {
        Group {
            if embeddedInMainNav {
                ordersBody
            } else {
                FashScreenScaffold(title: L10n.ordersTitle, showBack: true, onBack: onDismiss) {
                    ordersBody
                }
            }
        }
        .task { await activeVM.refresh(deps: deps) }
        .refreshable { await activeVM.pullToRefresh(deps: deps) }
    }

    @ViewBuilder
    private var ordersBody: some View {
        ZStack(alignment: .bottom) {
            VStack(spacing: 0) {
                Picker("", selection: bindableRole) {
                    Text(L10n.ordersTabBuying).tag(OrdersViewModel.OrderRole.buying)
                    Text(L10n.ordersTabSelling).tag(OrdersViewModel.OrderRole.selling)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, spacing.editorialStart)
                .padding(.vertical, 12)

                orderFilterBar

                Group {
                    if activeVM.isLoading, activeVM.buyingOrders.isEmpty, activeVM.sellingOrders.isEmpty {
                        ProgressView()
                            .tint(FashColors.brandPrimary)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if let error = activeVM.errorMessage, activeVM.sourceOrders.isEmpty {
                        FashEmptyStateView(
                            title: L10n.ordersErrorTitle,
                            subtitle: error,
                            systemImage: "exclamationmark.triangle",
                            actionTitle: L10n.feedRetry
                        ) {
                            Task { await activeVM.refresh(deps: deps) }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if activeVM.sourceOrders.isEmpty {
                        FashEmptyStateView(
                            title: activeVM.selectedRole == .buying ? L10n.ordersEmptyBuying : L10n.ordersEmptySelling,
                            subtitle: activeVM.selectedRole == .buying ? L10n.ordersEmptyBuyingSub : L10n.ordersEmptySellingSub,
                            systemImage: activeVM.selectedRole == .buying ? "bag" : "storefront"
                        )
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else if activeVM.filteredOrders.isEmpty {
                        FashEmptyStateView(
                            title: L10n.ordersEmptyFilteredTitle,
                            subtitle: L10n.ordersEmptyFilteredSub,
                            actionTitle: L10n.ordersFilterClear
                        ) {
                            Task { await activeVM.selectStatusFilter(.all, deps: deps) }
                        }
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(activeVM.filteredOrders) { order in
                                    OrderListCard(
                                        order: order,
                                        showReviewButton: activeVM.selectedRole == .buying,
                                        isConfirming: activeVM.confirmingOrderId == order.orderId,
                                        onConfirm: {
                                            Task { await activeVM.confirmReceipt(orderId: order.orderId, deps: deps) }
                                        },
                                        onTap: { onSelectOrder(order.orderId) }
                                    )
                                }
                            }
                            .padding(.horizontal, spacing.editorialStart)
                            .padding(.vertical, 16)
                        }
                    }
                }
                .padding(.bottom, promoDockInset)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }

            if !promoSlides.isEmpty {
                FashPromoSliderAdFooterView(slides: promoSlides, onSlideClick: onPromoSlideClick)
            }
        }
        .background(FashColors.screen)
    }

    private var orderFilterBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(OrderStatusFilter.allCases, id: \.self) { filter in
                    let selected = activeVM.activeStatusFilter == filter
                    let count = activeVM.sourceOrders.filter { filter.matches($0) }.count
                    Button {
                        Task { await activeVM.selectStatusFilter(filter, deps: deps) }
                    } label: {
                        Text(count > 0 && filter != .all ? "\(filter.label) (\(count))" : filter.label)
                            .font(FashTypography.labelMedium.weight(selected ? .semibold : .regular))
                            .foregroundStyle(selected ? FashColors.onBrandPrimary : FashColors.textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selected ? FashColors.brandPrimary : FashColors.surfaceContainer)
                            .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, spacing.editorialStart)
            .padding(.bottom, 8)
        }
    }

    private var bindableRole: Binding<OrdersViewModel.OrderRole> {
        Binding(
            get: { activeVM.selectedRole },
            set: { activeVM.selectedRole = $0 }
        )
    }
}

private struct OrderListCard: View {
    let order: OrderItem
    let showReviewButton: Bool
    let isConfirming: Bool
    let onConfirm: () -> Void
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                let img = FeedImageUrl.resolveListingImageUrlOrNil(order.imageUrl)
                Group {
                    if let img {
                        FashAsyncImage(url: img, contentMode: .fill)
                    } else {
                        FashColors.surfaceVariant
                    }
                }
                .frame(width: 80, height: 80)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .top) {
                        Text(order.title)
                            .font(FashTypography.titleSmall.weight(.bold))
                            .foregroundStyle(FashColors.textPrimary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                        Spacer(minLength: 8)
                        Text(OrderFormatting.statusLabel(order.status))
                            .font(FashTypography.labelSmall.weight(.semibold))
                            .foregroundStyle(FashColors.brandPrimary)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(FashColors.brandPrimary.opacity(0.1))
                            .clipShape(Capsule())
                    }
                    Text("@\(order.sellerUsername.isEmpty ? "—" : order.sellerUsername)")
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(FashColors.textSecondary)
                    Text(FeedPriceFormat.format(order.priceVnd))
                        .font(FashTypography.labelLarge)
                        .foregroundStyle(FashColors.brandPrimary)

                    if order.canConfirm {
                        Button(action: onConfirm) {
                            HStack(spacing: 6) {
                                if isConfirming { ProgressView().scaleEffect(0.75) }
                                Text(L10n.ordersConfirmReceived)
                            }
                            .font(FashTypography.labelMedium)
                            .foregroundStyle(FashColors.brandPrimary)
                        }
                        .buttonStyle(.plain)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    } else if showReviewButton, order.canReview {
                        Text(L10n.ordersReview)
                            .font(FashTypography.labelMedium)
                            .foregroundStyle(FashColors.brandPrimary)
                            .frame(maxWidth: .infinity, alignment: .trailing)
                    }
                }
            }
            .padding(12)
            .background(FashColors.surfaceContainer)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
