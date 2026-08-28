import SwiftUI

struct SellerPackageEntitlementCard: View {
    @Environment(\.fashSpacing) private var spacing
    let summary: UserEntitlementSummary?
    let loading: Bool
    var onRefresh: () -> Void
    var onUpgrade: () -> Void
    var onOpenTools: () -> Void

    var body: some View {
        let name = summary.map { $0.packageName.isEmpty ? $0.packageCode : $0.packageName } ?? ""
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                SellerPackageIconBadge(systemImage: "checkmark.seal.fill")
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.sellerPackagesEntitlementTitle)
                        .font(FashTypography.titleSmall.weight(.bold))
                        .foregroundStyle(FashColors.textPrimary)
                    if loading && summary == nil {
                        Text(L10n.exploreFilterLoading)
                            .font(FashTypography.bodySmall)
                            .foregroundStyle(FashColors.textSecondary)
                    } else if name.isEmpty {
                        Text(L10n.sellerPackagesEntitlementEmpty)
                            .font(FashTypography.bodySmall)
                            .foregroundStyle(FashColors.textSecondary)
                    } else {
                        Text(name)
                            .font(FashTypography.bodyMedium.weight(.semibold))
                            .foregroundStyle(FashColors.brandPrimary)
                    }
                }
                Spacer(minLength: 0)
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(FashColors.brandPrimary)
                        .frame(width: 44, height: 44)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(L10n.sellerPackagesEntitlementRefresh)
            }
            if let summary {
                featureRow(
                    "checkmark.seal.fill",
                    L10n.sellerPackagesFeatureAuthenticity,
                    summary.features["authenticity_verify"]
                )
                featureRow(
                    "sparkles",
                    L10n.sellerPackagesFeatureExplore,
                    summary.features["explore_boost"]
                )
                featureRow(
                    "megaphone",
                    L10n.sellerPackagesFeatureFanpage,
                    summary.features["fanpage_spotlight"]
                )
                featureRow(
                    "square.and.arrow.up",
                    L10n.sellerPackagesFeatureSocial,
                    summary.features["social_tiktok_instagram"]
                )
            }
            FashPrimaryButton(title: L10n.sellerPackagesToolsOpen, action: onOpenTools)
            Button(L10n.sellerPackagesEntitlementUpgrade, action: onUpgrade)
                .buttonStyle(FashOutlinedBrandButtonStyle())
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FashColors.surface)
        .overlay(
            RoundedRectangle(cornerRadius: spacing.radiusCard, style: .continuous)
                .stroke(FashColors.outlineMuted.opacity(0.5), lineWidth: 1)
        )
        .clipShape(RoundedRectangle(cornerRadius: spacing.radiusCard, style: .continuous))
    }

    private func featureRow(_ icon: String, _ label: String, _ feature: FeatureUsageSummary?) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(SellerPackageQuota.canUse(feature) ? FashColors.brandPrimary : FashColors.textSecondary)
                .frame(width: 18, height: 18)
            Text(label)
                .font(FashTypography.bodySmall)
                .foregroundStyle(FashColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            SellerPackageQuotaChip(feature: feature)
        }
    }
}

struct SellerPackageIconBadge: View {
    var systemImage: String
    var size: CGFloat = 40

    var body: some View {
        Circle()
            .fill(FashColors.brandPrimary.opacity(0.12))
            .frame(width: size, height: size)
            .overlay {
                Image(systemName: systemImage)
                    .font(.system(size: size * 0.42, weight: .semibold))
                    .foregroundStyle(FashColors.brandPrimary)
            }
    }
}

enum SellerPackageQuota {
    static func canUse(_ feature: FeatureUsageSummary?) -> Bool {
        guard let feature, feature.enabled else { return false }
        if feature.unlimited { return true }
        if let remaining = feature.remaining { return remaining > 0 }
        return true
    }

    static func label(_ feature: FeatureUsageSummary?) -> String {
        guard let feature, feature.enabled else { return L10n.sellerPackagesToolsQuotaLocked }
        if feature.unlimited { return L10n.sellerPackagesToolsQuotaUnlimited }
        if let remaining = feature.remaining {
            if remaining <= 0 { return L10n.sellerPackagesToolsQuotaExhausted }
            return L10n.sellerPackagesToolsQuotaRemaining(Int(remaining))
        }
        return L10n.sellerPackagesToolsQuotaUnlimited
    }

    static func emphasized(_ feature: FeatureUsageSummary?) -> Bool {
        canUse(feature)
    }
}

struct SellerPackageQuotaChip: View {
    let feature: FeatureUsageSummary?

    var body: some View {
        let on = SellerPackageQuota.emphasized(feature)
        Text(SellerPackageQuota.label(feature))
            .font(FashTypography.labelSmall.weight(.semibold))
            .foregroundStyle(on ? FashColors.brandPrimary : FashColors.textSecondary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(on ? FashColors.brandPrimary.opacity(0.14) : FashColors.surfaceVariant)
            .clipShape(Capsule())
    }
}
