import SwiftUI

struct SellerPackageEntitlementCard: View {
    let summary: UserEntitlementSummary?
    let loading: Bool
    var onRefresh: () -> Void
    var onUpgrade: () -> Void
    var onOpenTools: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.sellerPackagesEntitlementTitle)
                .font(FashTypography.titleSmall.weight(.bold))
            if loading && summary == nil {
                Text(L10n.loading)
            } else if let summary {
                Text(summary.packageName.isEmpty ? summary.packageCode : summary.packageName)
                    .font(FashTypography.bodyMedium.weight(.semibold))
                    .foregroundStyle(FashColors.brandPrimary)
                featureLine(L10n.sellerPackagesFeatureAuthenticity, summary.features["authenticity_verify"])
                featureLine(L10n.sellerPackagesFeatureExploreBoost, summary.features["explore_boost"])
                featureLine(L10n.sellerPackagesFeatureFanpage, summary.features["fanpage_spotlight"])
            } else {
                Text(L10n.sellerPackagesEntitlementEmpty)
            }
            HStack {
                Button(L10n.feedRetry, action: onRefresh)
                    .buttonStyle(FashOutlinedBrandButtonStyle())
                Button(L10n.sellerPackagesEntitlementUpgrade, action: onUpgrade)
                    .buttonStyle(FashFilledButtonStyle())
            }
            Button(L10n.sellerPackagesToolsTitle, action: onOpenTools)
                .buttonStyle(FashOutlinedBrandButtonStyle())
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FashColors.surfaceContainerHigh)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    @ViewBuilder
    private func featureLine(_ label: String, _ feature: FeatureUsageSummary?) -> some View {
        if let feature, feature.enabled {
            let quota = feature.unlimited ? "∞" : (feature.remaining.map { "\($0) left" } ?? "✓")
            Text("\(label): \(quota)")
                .font(FashTypography.bodySmall)
        } else {
            Text("\(label): —")
                .font(FashTypography.bodySmall)
                .foregroundStyle(FashColors.textSecondary)
        }
    }
}
