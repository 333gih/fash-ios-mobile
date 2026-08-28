import SwiftUI

private struct ToolFeatureEntry: Identifiable {
    let key: String
    let feature: FeatureUsageSummary
    var id: String { key }
}

struct SellerPackageToolsScreen: View {
    @Environment(AppDependencies.self) private var deps
    @Environment(\.fashSpacing) private var spacing
    var onDismiss: () -> Void
    var onUpgrade: () -> Void = {}

    @State private var summary: UserEntitlementSummary?
    @State private var listings: [ListingFeedItem] = []
    @State private var listingId = ""
    @State private var caption = ""
    @State private var loading = true
    @State private var listingsLoading = true
    @State private var submittingFeatureKey: String?

    private let groupOrder = ["verification", "visibility", "social_promo"]

    private var groupedFeatures: [(String, [ToolFeatureEntry])] {
        let feats = summary?.features ?? [:]
        let grouped = Dictionary(grouping: feats.map { ToolFeatureEntry(key: $0.key, feature: $0.value) }) {
            $0.feature.featureGroup.isEmpty ? "other" : $0.feature.featureGroup
        }
        let ordered = groupOrder.filter { grouped[$0] != nil } + grouped.keys.filter { !groupOrder.contains($0) }.sorted()
        return ordered.compactMap { key in
            guard let items = grouped[key] else { return nil }
            return (key, items)
        }
    }

    var body: some View {
        FashScreenScaffold(title: L10n.sellerPackagesToolsTitle, showBack: true, onBack: onDismiss) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(L10n.sellerPackagesToolsSubtitle)
                        .font(FashTypography.bodyMedium)
                        .foregroundStyle(FashColors.textSecondary)
                    packageStatusCard
                    listingPicker
                    ForEach(groupedFeatures, id: \.0) { group, entries in
                        Text(groupLabel(group))
                            .font(FashTypography.titleSmall.weight(.semibold))
                            .foregroundStyle(FashColors.textPrimary)
                        ForEach(entries) { entry in
                            toolCard(entry: entry)
                        }
                    }
                }
                .padding(.leading, spacing.editorialStart)
                .padding(.trailing, spacing.editorialEnd)
                .padding(.vertical, 12)
                .padding(.bottom, 24)
            }
            .background(FashColors.screen)
            .scrollDismissesKeyboard(.interactively)
        }
        .task { await bootstrap() }
    }

    private var packageStatusCard: some View {
        let name = summary.map { $0.packageName.isEmpty ? $0.packageCode : $0.packageName } ?? ""
        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                SellerPackageIconBadge(systemImage: "checkmark.seal.fill", size: 44)
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.sellerPackagesEntitlementTitle)
                        .font(FashTypography.labelMedium)
                        .foregroundStyle(FashColors.textSecondary)
                    if loading && name.isEmpty {
                        Text(L10n.exploreFilterLoading)
                            .font(FashTypography.titleSmall.weight(.semibold))
                    } else if name.isEmpty {
                        Text(L10n.sellerPackagesToolsEmptyPackage)
                            .font(FashTypography.bodyMedium)
                            .foregroundStyle(FashColors.textSecondary)
                    } else {
                        Text(name)
                            .font(FashTypography.titleSmall.weight(.bold))
                            .foregroundStyle(FashColors.textPrimary)
                        Text(L10n.sellerPackagesEntitlementActive)
                            .font(FashTypography.labelSmall)
                            .foregroundStyle(FashColors.brandPrimary)
                    }
                }
                Spacer(minLength: 0)
            }
            if name.isEmpty && !loading {
                Button(L10n.sellerPackagesEntitlementUpgrade, action: onUpgrade)
                    .buttonStyle(FashOutlinedBrandButtonStyle())
            }
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

    private var listingPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.sellerPackagesToolsPickListing)
                .font(FashTypography.titleSmall.weight(.semibold))
            if listingsLoading {
                ProgressView()
                    .tint(FashColors.brandPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
            } else if listings.isEmpty {
                Text(L10n.sellerPackagesToolsNoListings)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(listings) { item in
                            listingTile(item)
                        }
                    }
                }
            }
            SellerPackageFilledField(label: L10n.sellerPackagesToolsListingId, text: $listingId)
            Text(L10n.sellerPackagesToolsListingHelper)
                .font(FashTypography.bodySmall)
                .foregroundStyle(FashColors.textSecondary)
        }
    }

    private func listingTile(_ item: ListingFeedItem) -> some View {
        let selected = item.id == listingId.trimmingCharacters(in: .whitespacesAndNewlines)
        return Button {
            listingId = item.id
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                Color.clear
                    .frame(width: 100, height: 84)
                    .overlay {
                        FashAsyncImage(url: item.coverImageUrl, contentMode: .fill)
                    }
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                Text(item.title.isEmpty ? item.id : item.title)
                    .font(FashTypography.labelSmall.weight(.medium))
                    .foregroundStyle(FashColors.textPrimary)
                    .lineLimit(2)
                    .frame(width: 100, alignment: .leading)
            }
            .padding(6)
            .background(FashColors.surface)
            .overlay(
                RoundedRectangle(cornerRadius: spacing.radiusSoftMin, style: .continuous)
                    .stroke(
                        selected ? FashColors.brandPrimary : FashColors.outlineMuted.opacity(0.5),
                        lineWidth: selected ? 2 : 1
                    )
            )
            .clipShape(RoundedRectangle(cornerRadius: spacing.radiusSoftMin, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private func toolCard(entry: ToolFeatureEntry) -> some View {
        let feature = entry.feature
        let kind = feature.executionKind.isEmpty ? "request" : feature.executionKind
        let showsCaption = kind != "boost"
        let canUse = SellerPackageQuota.canUse(feature)
        let locked = !feature.enabled
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                SellerPackageIconBadge(systemImage: featureIcon(entry.key, kind: kind))
                VStack(alignment: .leading, spacing: 4) {
                    Text(featureTitle(entry.key, feature: feature))
                        .font(FashTypography.titleSmall.weight(.bold))
                        .foregroundStyle(FashColors.textPrimary)
                    Text(featureDescription(entry.key, feature: feature))
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(FashColors.textSecondary)
                }
                Spacer(minLength: 4)
                SellerPackageQuotaChip(feature: feature)
            }
            if showsCaption && canUse {
                SellerPackageFilledField(label: L10n.sellerPackagesToolsCaption, text: $caption, axis: true)
                Text(L10n.sellerPackagesToolsCaptionHelper)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
            }
            if locked {
                Text(L10n.sellerPackagesToolsLockedHint)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
                Button(L10n.sellerPackagesEntitlementUpgrade, action: onUpgrade)
                    .buttonStyle(FashOutlinedBrandButtonStyle())
                    .disabled(submittingFeatureKey != nil)
            } else {
                FashPrimaryButton(
                    title: featureCta(kind: kind),
                    isLoading: submittingFeatureKey == entry.key,
                    enabled: canUse && (submittingFeatureKey == nil || submittingFeatureKey == entry.key),
                    action: { submit(entry: entry, kind: kind, showsCaption: showsCaption) }
                )
            }
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

    private func groupLabel(_ group: String) -> String {
        switch group {
        case "verification": return "Xác minh"
        case "visibility": return "Hiển thị"
        case "social_promo": return "Quảng bá"
        default: return group.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    private func featureIcon(_ key: String, kind: String) -> String {
        if kind == "boost" || key == "explore_boost" { return "sparkles" }
        if key.contains("social") { return "square.and.arrow.up" }
        if key.contains("fanpage") { return "megaphone" }
        if key.contains("authenticity") || key.contains("verify") { return "checkmark.seal.fill" }
        return "star.fill"
    }

    private func featureTitle(_ key: String, feature: FeatureUsageSummary) -> String {
        if !feature.name.isEmpty { return feature.name }
        switch key {
        case "authenticity_verify": return L10n.sellerPackagesFeatureAuthenticity
        case "explore_boost": return L10n.sellerPackagesFeatureExploreBoost
        case "fanpage_spotlight": return L10n.sellerPackagesFeatureFanpage
        case "social_tiktok_instagram": return L10n.sellerPackagesFeatureSocial
        default: return key.replacingOccurrences(of: "_", with: " ").capitalized
        }
    }

    private func featureDescription(_ key: String, feature: FeatureUsageSummary) -> String {
        if !feature.description.isEmpty { return feature.description }
        switch key {
        case "authenticity_verify": return L10n.sellerPackagesToolsDescVerify
        case "explore_boost": return L10n.sellerPackagesToolsDescBoost
        case "fanpage_spotlight": return L10n.sellerPackagesToolsDescFanpage
        case "social_tiktok_instagram": return L10n.sellerPackagesToolsDescSocial
        default: return ""
        }
    }

    private func featureCta(kind: String) -> String {
        kind == "boost" ? L10n.sellerPackagesToolsBoost : L10n.sellerPackagesToolsVerify
    }

    private func bootstrap() async {
        async let entitlements = deps.userEntitlementRepository.fetchEntitlements()
        async let activeListings = deps.listingRepository.getMyListings(status: "active", limit: 40, offset: 0)
        let ent = await entitlements
        if case .success(let s) = ent { summary = s }
        loading = false
        let first = await activeListings
        switch first {
        case .success(let items) where !items.isEmpty:
            listings = items
        default:
            if case .success(let all) = await deps.listingRepository.getMyListings(status: nil, limit: 40, offset: 0) {
                listings = all
            }
        }
        listingsLoading = false
        if listingId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, let firstId = listings.first?.id {
            listingId = firstId
        }
    }

    private func submit(entry: ToolFeatureEntry, kind: String, showsCaption: Bool) {
        let id = listingId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard submittingFeatureKey == nil else { return }
        guard !id.isEmpty else {
            deps.showSnackbar(L10n.sellerPackagesToolsNeedListing)
            return
        }
        if showsCaption && caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            deps.showSnackbar(L10n.sellerPackagesToolsNeedCaption)
            return
        }
        submittingFeatureKey = entry.key
        Task {
            let result = await deps.userEntitlementRepository.invokeFeature(
                featureKey: entry.key,
                listingId: id,
                caption: caption
            )
            await MainActor.run {
                submittingFeatureKey = nil
                switch result {
                case .success:
                    deps.showSnackbar(successMessage(kind: kind))
                    Task { await refreshEntitlements() }
                case .failure(let error):
                    deps.showSnackbar(error.localizedDescription)
                }
            }
        }
    }

    private func refreshEntitlements() async {
        if case .success(let s) = await deps.userEntitlementRepository.fetchEntitlements() {
            summary = s
        }
    }

    private func successMessage(kind: String) -> String {
        kind == "boost" ? L10n.sellerPackagesToolsSuccessBoost : L10n.sellerPackagesToolsSuccessVerify
    }
}

private struct SellerPackageFilledField: View {
    let label: String
    @Binding var text: String
    var axis: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(FashTypography.labelMedium)
                .foregroundStyle(FashColors.textSecondary)
            Group {
                if axis {
                    TextField(label, text: $text, axis: .vertical)
                        .lineLimit(2...4)
                } else {
                    TextField(label, text: $text)
                }
            }
            .font(FashTypography.bodyLarge)
            .padding(12)
            .background(FashColors.surfaceVariant.opacity(0.45))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
    }
}
