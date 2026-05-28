import SwiftUI

struct SellerProductPackagesScreen: View {
    @Environment(\.fashSpacing) private var spacing
    var onDismiss: () -> Void = {}
    var onBuyPackage: (SellerProductPackage) -> Void = { _ in }

    @State private var viewModel = SellerProductPackagesViewModel()

    var body: some View {
        FashScreenScaffold(title: L10n.sellerPackagesScreenTitle, showBack: true, onBack: onDismiss) {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(FashColors.brandPrimary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let err = viewModel.loadError {
                    FashEmptyStateView(
                        title: L10n.sellerPackagesLoadError,
                        subtitle: err,
                        systemImage: "exclamationmark.triangle"
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.packages.isEmpty {
                    FashEmptyStateView(
                        title: L10n.sellerPackagesEmpty,
                        subtitle: L10n.sellerPackagesScreenSubtitle,
                        systemImage: "bag"
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: 16) {
                            Text(L10n.sellerPackagesScreenSubtitle)
                                .font(FashTypography.bodyMedium)
                                .foregroundStyle(FashColors.textSecondary)
                            ForEach(viewModel.packages) { pkg in
                                SellerPackageCard(pkg: pkg, onBuy: { onBuyPackage(pkg) })
                            }
                            Spacer(minLength: 24)
                        }
                        .padding(.horizontal, spacing.editorialStart)
                        .padding(.vertical, 12)
                    }
                }
            }
            .background(FashColors.screen)
        }
        .task { await viewModel.refresh() }
    }
}

private struct SellerPackageCard: View {
    @Environment(\.fashSpacing) private var spacing
    let pkg: SellerProductPackage
    let onBuy: () -> Void

    var body: some View {
        let highlighted = pkg.isBestSeller
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(pkg.name)
                        .font(FashTypography.titleMedium.weight(.bold))
                        .foregroundStyle(FashColors.textPrimary)
                    Text(pkg.description)
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(FashColors.textSecondary)
                }
                Spacer(minLength: 8)
                if let badge = pkg.badgeLabel, !badge.isEmpty {
                    HStack(spacing: 4) {
                        if highlighted {
                            Image(systemName: "star.fill")
                                .font(.system(size: 12))
                        }
                        Text(badge)
                            .font(FashTypography.labelSmall.weight(.semibold))
                    }
                    .foregroundStyle(highlighted ? FashColors.onBrandPrimary : FashColors.textPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(highlighted ? FashColors.brandPrimary : FashColors.surfaceContainerHigh)
                    .clipShape(Capsule())
                }
            }
            .padding(16)

            Text(L10n.sellerPackagesPricePerMonth(
                FeedPriceFormat.format(pkg.priceVnd),
                pkg.durationDays
            ))
            .font(FashTypography.titleSmall.weight(.semibold))
            .foregroundStyle(FashColors.brandPrimary)
            .padding(.horizontal, 16)

            Divider().padding(.horizontal, 16).opacity(0.5)

            SellerPackageFeaturesList(features: pkg.features)
                .padding(.horizontal, 16)
                .padding(.top, 8)

            Group {
                if !pkg.isReleased {
                    Button(L10n.sellerPackagesComingSoonCta, action: onBuy)
                        .buttonStyle(FashOutlinedBrandButtonStyle())
                } else {
                    Button(L10n.sellerPackagesBuyNow, action: onBuy)
                        .buttonStyle(FashFilledButtonStyle())
                }
            }
            .padding(16)
        }
        .background(highlighted ? FashColors.brandPrimary.opacity(0.12) : FashColors.surfaceContainer)
        .overlay(
            RoundedRectangle(cornerRadius: spacing.radiusCard, style: .continuous)
                .stroke(
                    highlighted ? FashColors.brandPrimary : FashColors.outlineMuted.opacity(0.5),
                    lineWidth: highlighted ? 2 : 1
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: spacing.radiusCard, style: .continuous))
    }
}
