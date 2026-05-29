import SwiftUI

/// Package detail + checkout — Android [SellerPackageCheckoutScreen].
struct SellerPackageCheckoutScreen: View {
    @Environment(\.fashSpacing) private var spacing
    let pkg: SellerProductPackage
    var onDismiss: () -> Void = {}

    private var comingSoon: Bool { !pkg.isReleased }

    var body: some View {
        FashScreenScaffold(title: L10n.sellerPackagesCheckoutTitle, showBack: true, onBack: onDismiss) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if comingSoon {
                        comingSoonBanner
                    }
                    packageSummaryCard
                    Text(L10n.sellerPackagesCheckoutLegal)
                        .font(FashTypography.labelSmall)
                        .foregroundStyle(FashColors.textSecondary)
                    Spacer(minLength: 80)
                }
                .padding(.horizontal, spacing.editorialStart)
                .padding(.vertical, 12)
            }
            .background(FashColors.screen)
        }
        .safeAreaInset(edge: .bottom) {
            bottomBar
        }
    }

    private var comingSoonBanner: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle")
                .font(.system(size: 22))
                .foregroundStyle(FashColors.brandPrimary)
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.sellerPackagesComingSoonTitle)
                    .font(FashTypography.titleSmall.weight(.bold))
                    .foregroundStyle(FashColors.textPrimary)
                Text(L10n.sellerPackagesComingSoonBody)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FashColors.brandPrimary.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: spacing.radiusCard, style: .continuous))
    }

    private var packageSummaryCard: some View {
        VStack(alignment: .leading, spacing: 12) {
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
                    packageBadge(badge)
                }
            }

            Text(L10n.sellerPackagesPricePerMonth(
                FeedPriceFormat.format(pkg.priceVnd),
                pkg.durationDays
            ))
            .font(FashTypography.titleSmall.weight(.semibold))
            .foregroundStyle(FashColors.brandPrimary)

            if !pkg.features.isEmpty {
                Divider().opacity(0.5)
                SellerPackageFeaturesList(
                    features: pkg.features,
                    sectionTitle: L10n.sellerPackagesCheckoutFeatures
                )
            }

            Divider().opacity(0.5)
            checkoutRow(L10n.sellerPackagesCheckoutDuration, L10n.sellerPackagesDurationDays(pkg.durationDays))
            checkoutRow(L10n.sellerPackagesCheckoutSubtotal, FeedPriceFormat.format(pkg.priceVnd))
            Divider().opacity(0.5)
            checkoutRow(L10n.sellerPackagesCheckoutTotal, FeedPriceFormat.format(pkg.priceVnd), emphasized: true)
        }
        .padding(16)
        .background(FashColors.surfaceContainerHigh)
        .clipShape(RoundedRectangle(cornerRadius: spacing.radiusCard, style: .continuous))
    }

    private func packageBadge(_ badge: String) -> some View {
        HStack(spacing: 4) {
            if pkg.isBestSeller {
                Image(systemName: "star.fill")
                    .font(.system(size: 12))
            }
            Text(badge)
                .font(FashTypography.labelSmall.weight(.semibold))
        }
        .foregroundStyle(pkg.isBestSeller ? FashColors.onBrandPrimary : FashColors.textPrimary)
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(pkg.isBestSeller ? FashColors.brandPrimary : FashColors.surfaceContainer)
        .clipShape(Capsule())
    }

    private var bottomBar: some View {
        VStack(spacing: 8) {
            if comingSoon {
                Button(L10n.sellerPackagesComingSoonCta) {}
                    .buttonStyle(FashFilledButtonStyle(enabledOpacity: 0.5))
                    .disabled(true)
            } else {
                Button(L10n.sellerPackagesPayAmount(FeedPriceFormat.format(pkg.priceVnd))) {}
                    .buttonStyle(FashFilledButtonStyle(enabledOpacity: 0.5))
                    .disabled(true)
            }
            Button(L10n.sellerPackagesBackToList, action: onDismiss)
                .buttonStyle(FashOutlinedBrandButtonStyle())
        }
        .padding(.horizontal, spacing.editorialStart)
        .padding(.vertical, 12)
        .background(FashColors.surface)
        .shadow(color: .black.opacity(0.06), radius: 8, y: -2)
    }

    private func checkoutRow(_ label: String, _ value: String, emphasized: Bool = false) -> some View {
        HStack {
            Text(label)
                .font(emphasized ? FashTypography.titleSmall.weight(.semibold) : FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
            Spacer()
            Text(value)
                .font(emphasized ? FashTypography.titleMedium.weight(.bold) : FashTypography.bodyMedium)
                .foregroundStyle(emphasized ? FashColors.brandPrimary : FashColors.textPrimary)
        }
        .padding(.vertical, 4)
    }
}
