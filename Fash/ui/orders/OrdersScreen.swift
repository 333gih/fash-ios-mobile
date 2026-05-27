import SwiftUI

struct OrdersScreen: View {
    @Environment(AppDependencies.self) private var deps
    @State private var internalViewModel = OrdersViewModel()
    var viewModel: OrdersViewModel? = nil
    var embeddedInMainNav: Bool = false
    var onDismiss: () -> Void
    var onSelectOrder: (String) -> Void

    private var activeVM: OrdersViewModel {
        if let viewModel { return viewModel }
        return internalViewModel
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
        VStack(spacing: 0) {
            Picker("", selection: bindableRole) {
                Text(L10n.ordersTabBuying).tag(OrdersViewModel.OrderRole.buying)
                Text(L10n.ordersTabSelling).tag(OrdersViewModel.OrderRole.selling)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 24)
            .padding(.vertical, 12)

            if activeVM.isLoading && activeVM.activeOrders.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = activeVM.errorMessage, activeVM.activeOrders.isEmpty {
                FashEmptyStateView(
                    title: L10n.feedLoadError,
                    subtitle: error,
                    actionTitle: L10n.feedRetry
                ) {
                    Task { await activeVM.refresh(deps: deps) }
                }
            } else if activeVM.activeOrders.isEmpty {
                FashEmptyStateView(
                    title: activeVM.selectedRole == .buying ? L10n.ordersEmptyBuying : L10n.ordersEmptySelling,
                    subtitle: activeVM.selectedRole == .buying ? L10n.ordersEmptyBuyingSub : L10n.ordersEmptySellingSub
                )
            } else {
                List(activeVM.activeOrders) { order in
                    Button {
                        onSelectOrder(order.orderId)
                    } label: {
                        HStack(spacing: 12) {
                            FashAsyncImage(url: order.imageUrl)
                                .frame(width: 56, height: 56)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            VStack(alignment: .leading, spacing: 4) {
                                Text(order.title)
                                    .font(FashTypography.titleSmall)
                                    .foregroundStyle(FashColors.textPrimary)
                                    .lineLimit(2)
                                Text(order.sellerUsername.isEmpty ? order.status : "@\(order.sellerUsername)")
                                    .font(FashTypography.bodySmall)
                                    .foregroundStyle(FashColors.textSecondary)
                                    .lineLimit(1)
                            }
                            Spacer()
                            Text(formatVnd(order.priceVnd))
                                .font(FashTypography.labelLarge)
                                .foregroundStyle(FashColors.brandPrimary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private var bindableRole: Binding<OrdersViewModel.OrderRole> {
        Binding(
            get: { activeVM.selectedRole },
            set: { activeVM.selectedRole = $0 }
        )
    }

    private func formatVnd(_ amount: Int64) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        return (formatter.string(from: NSNumber(value: amount)) ?? "\(amount)") + "đ"
    }
}
