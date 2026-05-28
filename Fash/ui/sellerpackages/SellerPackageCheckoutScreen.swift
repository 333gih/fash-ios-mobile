import SwiftUI

struct SellerPackageCheckoutScreen: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps
    var packageId: String = ""
    var onDismiss: () -> Void = {}

    @State private var pkg: SellerProductPackage?
    @State private var loading = true

    var body: some View {
        FashScreenScaffold(title: L10n.sellerPackagesCheckoutTitle, showBack: true, onBack: onDismiss) {
            Group {
                if loading {
                    ProgressView().tint(FashColors.brandPrimary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let pkg {
                    checkoutContent(pkg)
                } else {
                    FashEmptyStateView(
                        title: L10n.sellerPackagesLoadError,
                        systemImage: "exclamationmark.triangle"
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .background(FashColors.screen)
        }
        .safeAreaInset(edge: .bottom) {
            if let pkg {
                checkoutBottomBar(pkg)
            }
        }
        .task(id: packageId) { await loadPackage() }
    }

    @ViewBuilder
    private func checkoutContent(_ pkg: SellerProductPackage) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if !pkg.isReleased {
                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(FashColors.brandPrimary)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.sellerPackagesComingSoonTitle)
                                .font(FashTypography.titleSmall.weight(.bold))
                            Text(L10n.sellerPackagesComingSoonBody)
                                .font(FashTypography.bodySmall)
                                .foregroundStyle(FashColors.textSecondary)
                        }
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(FashColors.surfaceContainerHigh)
                    .clipShape(RoundedRectangle(cornerRadius: spacing.radiusCard, style: .continuous))
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text(pkg.name)
                        .font(FashTypography.titleMedium.weight(.bold))
                    Text(pkg.description)
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(FashColors.textSecondary)
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
                .background(FashColors.surfaceContainer)
                .clipShape(RoundedRectangle(cornerRadius: spacing.radiusCard, style: .continuous))

                Text(L10n.sellerPackagesCheckoutLegal)
                    .font(FashTypography.labelSmall)
                    .foregroundStyle(FashColors.textSecondary)
                Spacer(minLength: 80)
            }
            .padding(.horizontal, spacing.editorialStart)
            .padding(.vertical, 12)
        }
    }

    private func checkoutBottomBar(_ pkg: SellerProductPackage) -> some View {
        VStack(spacing: 8) {
            if pkg.isReleased {
                Button(L10n.sellerPackagesPayAmount(FeedPriceFormat.format(pkg.priceVnd))) {}
                    .buttonStyle(FashFilledButtonStyle(enabledOpacity: 0.5))
                    .disabled(true)
            } else {
                Button(L10n.sellerPackagesComingSoonCta) {}
                    .buttonStyle(FashFilledButtonStyle(enabledOpacity: 0.5))
                    .disabled(true)
            }
            Button(L10n.sellerPackagesBackToList, action: onDismiss)
                .buttonStyle(FashOutlinedBrandButtonStyle())
        }
        .padding(.horizontal, spacing.editorialStart)
        .padding(.vertical, 12)
        .background(FashColors.surfaceContainerHighest)
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

    private func loadPackage() async {
        loading = true
        pkg = nil
        let code = packageId.trimmingCharacters(in: .whitespaces)
        guard !code.isEmpty else {
            loading = false
            return
        }
        if case .success(let found) = await deps.sellerProductPackageRepository.getPackage(code: code) {
            pkg = found
        }
        loading = false
    }
}
