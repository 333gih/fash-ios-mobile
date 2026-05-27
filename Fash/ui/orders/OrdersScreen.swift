import SwiftUI

struct OrdersScreen: View {
    @Environment(AppDependencies.self) private var deps
    @State private var viewModel = OrdersViewModel()
    var onDismiss: () -> Void
    var onSelectOrder: (String) -> Void

    var body: some View {
        FashScreenScaffold(title: L10n.ordersTitle, showBack: true, onBack: onDismiss) {
            VStack(spacing: 0) {
                Picker("", selection: $viewModel.selectedRole) {
                    Text(L10n.ordersTabBuying).tag(OrdersViewModel.OrderRole.buying)
                    Text(L10n.ordersTabSelling).tag(OrdersViewModel.OrderRole.selling)
                }
                .pickerStyle(.segmented)
        .padding(.horizontal, 24)
        .padding(.vertical, 12)

                if viewModel.isLoading && viewModel.activeOrders.isEmpty {
                    ProgressView()
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let error = viewModel.errorMessage, viewModel.activeOrders.isEmpty {
                    FashEmptyStateView(
                        title: L10n.feedLoadError,
                        subtitle: error,
                        actionTitle: L10n.feedRetry
                    ) {
                        Task { await viewModel.refresh(deps: deps) }
                    }
                } else if viewModel.activeOrders.isEmpty {
                    FashEmptyStateView(
                        title: viewModel.selectedRole == .buying ? L10n.ordersEmptyBuying : L10n.ordersEmptySelling,
                        subtitle: viewModel.selectedRole == .buying ? L10n.ordersEmptyBuyingSub : L10n.ordersEmptySellingSub
                    )
                } else {
                    List(viewModel.activeOrders) { order in
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
        .task { await viewModel.refresh(deps: deps) }
        .refreshable { await viewModel.pullToRefresh(deps: deps) }
    }

    private func formatVnd(_ amount: Int64) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        return (formatter.string(from: NSNumber(value: amount)) ?? "\(amount)") + "đ"
    }
}
