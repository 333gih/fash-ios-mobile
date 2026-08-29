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
    var onUpgrade: (String?) -> Void = { _ in }

    @State private var summary: UserEntitlementSummary?
    @State private var listingId = ""
    @State private var selectedListingTitle = ""
    @State private var showListingPicker = false
    @State private var showAdvancedListingId = false
    @State private var caption = ""
    @State private var loading = true
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

    private var selectedId: String {
        listingId.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var hasListing: Bool {
        !selectedId.isEmpty
    }

    private var anyNeedsListing: Bool {
        summary?.features.values.contains(where: \.requiresListing) == true
    }

    var body: some View {
        FashScreenScaffold(title: L10n.sellerPackagesToolsTitle, showBack: true, onBack: onDismiss) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(L10n.sellerPackagesToolsSubtitle)
                        .font(FashTypography.bodyMedium)
                        .foregroundStyle(FashColors.textSecondary)
                    packageStatusCard
                    if anyNeedsListing {
                        listingPickerSection
                    }
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
        .sheet(isPresented: $showListingPicker) {
            SellerListingPickerSheet(
                selectedId: selectedId,
                onDismiss: { showListingPicker = false },
                onSelect: { item in
                    listingId = item.id
                    selectedListingTitle = item.title
                }
            )
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
                Button(L10n.sellerPackagesEntitlementUpgrade) { onUpgrade(nil) }
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

    private var listingPickerSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.sellerPackagesToolsPickListing)
                .font(FashTypography.titleSmall.weight(.semibold))
            Button { showListingPicker = true } label: {
                HStack {
                    Text(hasListing ? selectedListingTitle : L10n.sellerPackagesToolsTapPickListing)
                        .font(FashTypography.bodyMedium.weight(hasListing ? .semibold : .regular))
                        .foregroundStyle(hasListing ? FashColors.textPrimary : FashColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Text(L10n.sellerPackagesToolsChangeListing)
                        .font(FashTypography.labelMedium)
                        .foregroundStyle(FashColors.brandPrimary)
                }
                .padding(14)
                .background(FashColors.surface)
                .overlay(
                    RoundedRectangle(cornerRadius: spacing.radiusCard, style: .continuous)
                        .stroke(FashColors.outlineMuted.opacity(0.5), lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: spacing.radiusCard, style: .continuous))
            }
            .buttonStyle(.plain)
            Button { showAdvancedListingId.toggle() } label: {
                Text(L10n.sellerPackagesToolsAdvancedListingId)
                    .font(FashTypography.labelMedium.weight(.medium))
                    .foregroundStyle(FashColors.brandPrimary)
            }
            .buttonStyle(.plain)
            if showAdvancedListingId {
                SellerPackageFilledField(label: L10n.sellerPackagesToolsListingId, text: $listingId)
            }
        }
    }

    @ViewBuilder
    private func toolCard(entry: ToolFeatureEntry) -> some View {
        let feature = entry.feature
        let kind = feature.executionKind.isEmpty ? "request" : feature.executionKind
        let showsCaption = kind != "boost" && entry.key != "seller_real_badge"
        let needsListing = feature.requiresListing
        let canUse = SellerPackageQuota.canUse(feature)
        let locked = !feature.enabled
        let disclaimer = feature.disclaimerText.trimmingCharacters(in: .whitespacesAndNewlines)
        let boostHint = entry.key == "explore_boost"
            ? feature.boostAffinityHint.trimmingCharacters(in: .whitespacesAndNewlines)
            : ""
        let showResearchResult = entry.key == "authenticity_verify"
            && feature.latestRequestStatus == "fulfilled"
            && feature.latestConfidencePct != nil
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
            if !disclaimer.isEmpty {
                Text(disclaimer)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(10)
                    .background(FashColors.surfaceContainerHigh)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            }
            if !boostHint.isEmpty {
                Text(boostHint)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.brandPrimary)
            }
            if feature.latestRequestStatus == "pending" {
                Text(L10n.sellerPackagesToolsStatusPending)
                    .font(FashTypography.labelMedium)
                    .foregroundStyle(FashColors.textSecondary)
            }
            if showResearchResult, let pct = feature.latestConfidencePct {
                Text(L10n.sellerPackagesToolsResultConfidence(
                    pct,
                    feature.latestResultVerdict.isEmpty ? "—" : feature.latestResultVerdict
                ))
                .font(FashTypography.bodySmall.weight(.semibold))
                .foregroundStyle(FashColors.brandPrimary)
            }
            if entry.key == "seller_real_badge", feature.latestRequestStatus == "fulfilled" {
                Text(L10n.sellerPackagesToolsBadgeGranted)
                    .font(FashTypography.bodySmall.weight(.semibold))
                    .foregroundStyle(FashColors.brandPrimary)
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
                Button(L10n.sellerPackagesEntitlementUpgrade) { onUpgrade(entry.key) }
                    .buttonStyle(FashOutlinedBrandButtonStyle())
                    .disabled(submittingFeatureKey != nil)
            } else {
                FashPrimaryButton(
                    title: featureCta(kind: kind),
                    isLoading: submittingFeatureKey == entry.key,
                    enabled: canUse && (submittingFeatureKey == nil || submittingFeatureKey == entry.key),
                    action: { submit(entry: entry, kind: kind, needsListing: needsListing, showsCaption: showsCaption) }
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
        if key.contains("authenticity") || key.contains("verify") || key == "seller_real_badge" {
            return "checkmark.seal.fill"
        }
        return "star.fill"
    }

    private func featureTitle(_ key: String, feature: FeatureUsageSummary) -> String {
        if !feature.name.isEmpty { return feature.name }
        switch key {
        case "authenticity_verify": return L10n.sellerPackagesFeatureAuthenticity
        case "explore_boost": return L10n.sellerPackagesFeatureExploreBoost
        case "fanpage_spotlight": return L10n.sellerPackagesFeatureFanpage
        case "social_tiktok_instagram": return L10n.sellerPackagesFeatureSocial
        case "seller_real_badge": return L10n.sellerPackagesFeatureRealBadge
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
        kind == "boost" ? L10n.sellerPackagesToolsBoost : L10n.sellerPackagesToolsSubmit
    }

    private func bootstrap() async {
        if case .success(let s) = await deps.userEntitlementRepository.fetchEntitlements() {
            summary = s
        }
        loading = false
        let active = await deps.listingRepository.getMyListings(status: "active", limit: 40, offset: 0)
        let items: [ListingFeedItem]
        switch active {
        case .success(let page) where !page.isEmpty:
            items = page
        default:
            if case .success(let all) = await deps.listingRepository.getMyListings(status: nil, limit: 40, offset: 0) {
                items = all
            } else {
                items = []
            }
        }
        if selectedId.isEmpty, let first = items.first {
            listingId = first.id
            selectedListingTitle = first.title
        }
    }

    private func submit(
        entry: ToolFeatureEntry,
        kind: String,
        needsListing: Bool,
        showsCaption: Bool
    ) {
        guard submittingFeatureKey == nil else { return }
        if needsListing && !hasListing {
            deps.showSnackbar(L10n.sellerPackagesToolsNeedListing)
            return
        }
        if showsCaption && caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            deps.showSnackbar(L10n.sellerPackagesToolsNeedCaption)
            return
        }
        submittingFeatureKey = entry.key
        let listingArg = needsListing ? selectedId : ""
        Task {
            let result = await deps.userEntitlementRepository.invokeFeature(
                featureKey: entry.key,
                listingId: listingArg,
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
        if kind == "boost" {
            return L10n.sellerPackagesToolsSuccessBoostAffinity
        }
        return L10n.sellerPackagesToolsSuccessRequest
    }
}

struct SellerPackageFilledField: View {
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
