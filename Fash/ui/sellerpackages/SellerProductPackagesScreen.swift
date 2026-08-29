import SwiftUI

struct SellerProductPackagesScreen: View {
    @Environment(\.fashSpacing) private var spacing
    var highlightFeatureKey: String? = nil
    var onDismiss: () -> Void = {}
    var onBuyPackage: (SellerProductPackage) -> Void = { _ in }

    @State private var viewModel = SellerProductPackagesViewModel()

    private var highlightKey: String {
        highlightFeatureKey?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private var targetPackageIndex: Int? {
        guard !highlightKey.isEmpty else { return nil }
        let idx = viewModel.packages.firstIndex { pkg in
            pkg.features.contains { $0.id == highlightKey && $0.included }
        }
        return idx
    }

    private var targetPackage: SellerProductPackage? {
        guard let idx = targetPackageIndex else { return nil }
        return viewModel.packages[idx]
    }

    private var highlightFeatureName: String? {
        targetPackage?.features.first { $0.id == highlightKey }?.name
    }

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
                    ScrollViewReader { proxy in
                        ScrollView {
                            LazyVStack(alignment: .leading, spacing: 16) {
                                Text(L10n.sellerPackagesScreenSubtitle)
                                    .font(FashTypography.bodyMedium)
                                    .foregroundStyle(FashColors.textSecondary)
                                if !highlightKey.isEmpty, let targetPackage {
                                    HighlightUpgradeBanner(
                                        featureName: highlightFeatureName ?? highlightKey,
                                        packageName: targetPackage.name
                                    )
                                }
                                ForEach(Array(viewModel.packages.enumerated()), id: \.element.code) { index, pkg in
                                    SellerPackageCard(
                                        pkg: pkg,
                                        highlightFeatureKey: pkg.code == targetPackage?.code ? highlightKey : nil,
                                        onBuy: { onBuyPackage(pkg) }
                                    )
                                    .id(index)
                                }
                                Spacer(minLength: 24)
                            }
                            .padding(.horizontal, spacing.editorialStart)
                            .padding(.vertical, 12)
                        }
                        .onChange(of: viewModel.packages.count) { _, _ in
                            scrollToTarget(proxy: proxy)
                        }
                        .onAppear {
                            scrollToTarget(proxy: proxy)
                        }
                    }
                }
            }
            .background(FashColors.screen)
        }
        .task { await viewModel.refresh() }
    }

    private func scrollToTarget(proxy: ScrollViewProxy) {
        guard let idx = targetPackageIndex else { return }
        withAnimation(.easeInOut(duration: 0.35)) {
            proxy.scrollTo(idx, anchor: .top)
        }
    }
}

private struct HighlightUpgradeBanner: View {
    let featureName: String
    let packageName: String

    var body: some View {
        Text(L10n.sellerPackagesUpgradeHighlight(featureName, packageName))
            .font(FashTypography.bodySmall.weight(.semibold))
            .foregroundStyle(FashColors.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(12)
            .background(FashColors.brandPrimary.opacity(0.14))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

private struct SellerPackageCard: View {
    @Environment(\.fashSpacing) private var spacing
    let pkg: SellerProductPackage
    var highlightFeatureKey: String? = nil
    let onBuy: () -> Void

    @State private var pulseOn = false

    private var isHighlighted: Bool {
        guard let highlightFeatureKey, !highlightFeatureKey.isEmpty else { return false }
        return pkg.features.contains { $0.id == highlightFeatureKey && $0.included }
    }

    private var highlighted: Bool {
        pkg.isBestSeller
    }

    var body: some View {
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

            SellerPackageFeaturesList(
                features: pkg.features,
                highlightFeatureKey: highlightFeatureKey
            )
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
                    borderColor,
                    lineWidth: borderWidth
                )
        )
        .clipShape(RoundedRectangle(cornerRadius: spacing.radiusCard, style: .continuous))
        .onAppear {
            guard isHighlighted else { return }
            withAnimation(.easeInOut(duration: 0.9).repeatForever(autoreverses: true)) {
                pulseOn = true
            }
        }
    }

    private var borderWidth: CGFloat {
        isHighlighted || highlighted ? 2 : 1
    }

    private var borderColor: Color {
        if isHighlighted {
            return FashColors.brandPrimary.opacity(pulseOn ? 1 : 0.35)
        }
        if highlighted {
            return FashColors.brandPrimary
        }
        return FashColors.outlineMuted.opacity(0.5)
    }
}
