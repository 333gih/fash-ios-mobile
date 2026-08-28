import SwiftUI

private enum SellerPackageToolKind: Equatable {
    case verify
    case boost
    case fanpage
    case social
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
    @State private var submitting: SellerPackageToolKind?

    var body: some View {
        FashScreenScaffold(title: L10n.sellerPackagesToolsTitle, showBack: true, onBack: onDismiss) {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(L10n.sellerPackagesToolsSubtitle)
                        .font(FashTypography.bodyMedium)
                        .foregroundStyle(FashColors.textSecondary)
                    packageStatusCard
                    listingPicker
                    toolCard(
                        icon: "checkmark.seal.fill",
                        title: L10n.sellerPackagesFeatureAuthenticity,
                        description: L10n.sellerPackagesToolsDescVerify,
                        feature: summary?.features["authenticity_verify"],
                        cta: L10n.sellerPackagesToolsVerify,
                        kind: .verify,
                        showsCaption: false
                    )
                    toolCard(
                        icon: "sparkles",
                        title: L10n.sellerPackagesFeatureExploreBoost,
                        description: L10n.sellerPackagesToolsDescBoost,
                        feature: summary?.features["explore_boost"],
                        cta: L10n.sellerPackagesToolsBoost,
                        kind: .boost,
                        showsCaption: false
                    )
                    toolCard(
                        icon: "megaphone",
                        title: L10n.sellerPackagesFeatureFanpage,
                        description: L10n.sellerPackagesToolsDescFanpage,
                        feature: summary?.features["fanpage_spotlight"],
                        cta: L10n.sellerPackagesToolsFanpage,
                        kind: .fanpage,
                        showsCaption: true
                    )
                    toolCard(
                        icon: "square.and.arrow.up",
                        title: L10n.sellerPackagesFeatureSocial,
                        description: L10n.sellerPackagesToolsDescSocial,
                        feature: summary?.features["social_tiktok_instagram"],
                        cta: L10n.sellerPackagesToolsSocial,
                        kind: .social,
                        showsCaption: true
                    )
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
    private func toolCard(
        icon: String,
        title: String,
        description: String,
        feature: FeatureUsageSummary?,
        cta: String,
        kind: SellerPackageToolKind,
        showsCaption: Bool
    ) -> some View {
        let canUse = SellerPackageQuota.canUse(feature)
        let locked = feature == nil || !(feature?.enabled ?? false)
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 12) {
                SellerPackageIconBadge(systemImage: icon)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(FashTypography.titleSmall.weight(.bold))
                        .foregroundStyle(FashColors.textPrimary)
                    Text(description)
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
                    .disabled(submitting != nil)
            } else {
                FashPrimaryButton(
                    title: cta,
                    isLoading: submitting == kind,
                    enabled: canUse && (submitting == nil || submitting == kind),
                    action: { submit(kind) }
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

    private func submit(_ kind: SellerPackageToolKind) {
        let id = listingId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard submitting == nil else { return }
        guard !id.isEmpty else {
            deps.showSnackbar(L10n.sellerPackagesToolsNeedListing)
            return
        }
        if kind == .fanpage || kind == .social {
            guard !caption.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
                deps.showSnackbar(L10n.sellerPackagesToolsNeedCaption)
                return
            }
        }
        submitting = kind
        Task {
            let result: Result<Void, Error>
            switch kind {
            case .verify:
                result = await deps.userEntitlementRepository.requestAuthenticity(listingId: id)
            case .boost:
                result = await deps.userEntitlementRepository.applyExploreBoost(listingId: id)
            case .fanpage:
                result = await deps.userEntitlementRepository.requestFanpage(listingId: id, caption: caption)
            case .social:
                result = await deps.userEntitlementRepository.requestSocialPromo(listingId: id, caption: caption)
            }
            await MainActor.run {
                submitting = nil
                switch result {
                case .success:
                    deps.showSnackbar(successMessage(kind))
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

    private func successMessage(_ kind: SellerPackageToolKind) -> String {
        switch kind {
        case .verify: return L10n.sellerPackagesToolsSuccessVerify
        case .boost: return L10n.sellerPackagesToolsSuccessBoost
        case .fanpage: return L10n.sellerPackagesToolsSuccessFanpage
        case .social: return L10n.sellerPackagesToolsSuccessSocial
        }
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
