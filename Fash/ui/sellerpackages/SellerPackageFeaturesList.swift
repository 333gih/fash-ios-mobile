import SwiftUI

enum SellerPackageFeatureLabels {
    static func title(featureId: String, apiName: String?) -> String {
        if let apiName, !apiName.isEmpty { return apiName }
        switch featureId {
        case "authenticity_verify": return L10n.sellerPackagesFeatureAuthenticity
        case "explore_boost": return L10n.sellerPackagesFeatureExploreBoost
        case "fanpage_spotlight": return L10n.sellerPackagesFeatureFanpage
        case "social_tiktok_instagram": return L10n.sellerPackagesFeatureSocial
        default: return featureId
        }
    }
}

struct SellerPackageFeaturesList: View {
    var features: [SellerPackageFeature]
    var sectionTitle: String?

    var body: some View {
        if features.isEmpty { EmptyView() } else {
            VStack(alignment: .leading, spacing: 8) {
                if let sectionTitle, !sectionTitle.isEmpty {
                    Text(sectionTitle)
                        .font(FashTypography.titleSmall.weight(.semibold))
                        .foregroundStyle(FashColors.textPrimary)
                }
                ForEach(Array(features.enumerated()), id: \.offset) { _, feature in
                    featureRow(feature)
                }
            }
        }
    }

    private func featureRow(_ feature: SellerPackageFeature) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: feature.included ? "checkmark" : "xmark")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(feature.included ? FashColors.brandPrimary : FashColors.outlineMuted)
                .frame(width: 18, height: 18)
            VStack(alignment: .leading, spacing: 2) {
                Text(SellerPackageFeatureLabels.title(featureId: feature.id, apiName: feature.name))
                    .font(FashTypography.bodyMedium)
                    .foregroundStyle(feature.included ? FashColors.textPrimary : FashColors.textSecondary)
                if feature.included, let highlight = feature.highlight, !highlight.isEmpty {
                    Text(highlight)
                        .font(FashTypography.labelSmall)
                        .foregroundStyle(FashColors.textSecondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}
