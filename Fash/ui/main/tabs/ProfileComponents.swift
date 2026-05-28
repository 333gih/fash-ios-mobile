import SwiftUI

private let profileHeroCoverHeight: CGFloat = 168
private let profileHeroAvatarOverlap: CGFloat = 40
private let profileHeroAvatarRing: CGFloat = 88
private let profileHeroAvatarInner: CGFloat = 80

// MARK: - Hero & identity

struct ProfileHeroSection: View {
    @Environment(\.fashSpacing) private var spacing
    let coverImageUrl: String?
    let avatarUrl: String?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            cover
                .frame(height: profileHeroCoverHeight)
                .frame(maxWidth: .infinity)
                .clipped()
            LinearGradient(
                colors: [.clear, Color.black.opacity(0.38)],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 80)
            .frame(maxHeight: .infinity, alignment: .bottom)
            avatarRing
                .padding(.leading, spacing.editorialStart)
                .offset(y: profileHeroAvatarOverlap)
        }
        .padding(.bottom, profileHeroAvatarOverlap)
    }

    @ViewBuilder
    private var cover: some View {
        if let url = resolvedCover {
            FashAsyncImage(url: url, contentMode: .fill)
        } else {
            LinearGradient(
                colors: [FashColors.brandPrimary.opacity(0.5), FashColors.surfaceContainerHigh],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    private var resolvedCover: String? {
        FeedImageUrl.resolveProfileImageUrlOrNil(coverImageUrl)
    }

    private var avatarRing: some View {
        ZStack {
            Circle()
                .fill(FashColors.screen)
                .frame(width: profileHeroAvatarRing, height: profileHeroAvatarRing)
                .shadow(color: .black.opacity(0.12), radius: 3, y: 1)
            FashAvatarCircle(url: avatarUrl, size: profileHeroAvatarInner)
                .overlay(Circle().stroke(FashColors.screen, lineWidth: 4))
        }
    }
}

struct ProfileIdentityBlock: View {
    @Environment(\.fashSpacing) private var spacing
    let profile: ProfileInfo?
    var showEditButton: Bool = false
    var aestheticCatalog: [CommonAestheticTagDto] = []
    var onEdit: (() -> Void)? = nil
    var onAestheticTagClick: ((String, String?) -> Void)? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .center, spacing: 8) {
                Text(displayName)
                    .font(FashTypography.headlineSmall.weight(.bold))
                    .foregroundStyle(FashColors.textPrimary)
                    .lineLimit(2)
                if profile?.verified == true {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 22))
                        .foregroundStyle(FashColors.brandPrimary)
                }
            }
            Text("@\(handle)")
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
            if let email = profile?.accountEmail.trimmingCharacters(in: .whitespacesAndNewlines), !email.isEmpty, showEditButton {
                Text(L10n.profileAccountEmail(email))
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
            }
            if let phone = profile?.accountPhone.trimmingCharacters(in: .whitespacesAndNewlines), !phone.isEmpty, showEditButton {
                Text(L10n.profileAccountPhone(phone))
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
            }
            if let bio = profile?.bio.trimmingCharacters(in: .whitespacesAndNewlines), !bio.isEmpty {
                Text(bio)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
                    .lineLimit(4)
            }
            ProfileAestheticChipsRow(
                profile: profile,
                catalog: aestheticCatalog,
                onTagClick: onAestheticTagClick
            )
            if showEditButton, let onEdit {
                Button(action: onEdit) {
                    Text(L10n.profileEdit)
                        .font(FashTypography.labelLarge.weight(.semibold))
                        .foregroundStyle(FashColors.brandPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 42)
                        .overlay {
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .stroke(FashColors.brandPrimary.opacity(0.45), lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
                .padding(.top, 4)
            }
        }
        .padding(.horizontal, spacing.editorialStart)
        .padding(.top, 44)
        .padding(.bottom, spacing.spacing4)
    }

    private var displayName: String {
        let n = profile?.displayName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !n.isEmpty { return n }
        let u = profile?.username ?? ""
        return u.isEmpty ? "—" : u
    }

    private var handle: String {
        let u = profile?.username.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return u.isEmpty ? "—" : u
    }
}

struct ProfileAestheticChipsRow: View {
    let profile: ProfileInfo?
    let catalog: [CommonAestheticTagDto]
    var onTagClick: ((String, String?) -> Void)?

    var body: some View {
        let chips = aestheticChips
        if chips.isEmpty { EmptyView() } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(Array(chips.enumerated()), id: \.offset) { _, chip in
                        Button {
                            onTagClick?(chip.label, chip.id)
                        } label: {
                            Text(chip.label)
                                .font(FashTypography.labelSmall)
                                .foregroundStyle(FashColors.textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(FashColors.brandPrimary.opacity(0.14))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.top, 12)
        }
    }

    private var aestheticChips: [(label: String, id: String?)] {
        guard let profile else { return [] }
        let preferVi = AppLocale.currentTag != AppLocale.tagEN
        if !profile.aestheticTagSnapshots.isEmpty {
            return profile.aestheticTagSnapshots.map { snap in
                (
                    AestheticTagLabels.resolveLabel(catalog: catalog, id: snap.id, rawName: snap.name, preferVi: preferVi),
                    snap.id.isEmpty ? nil : snap.id
                )
            }
        }
        return profile.aestheticTags.map { name in
            (AestheticTagLabels.resolveLabel(catalog: catalog, id: nil, rawName: name, preferVi: preferVi), nil)
        }
    }
}

struct ProfileCompactHeaderBar: View {
    @Environment(\.fashSpacing) private var spacing
    let profile: ProfileInfo?
    var onTap: (() -> Void)? = nil

    var body: some View {
        Button(action: { onTap?() }) {
            HStack(spacing: 12) {
                FashAvatarCircle(url: profile?.avatarUrl, size: 40)
                    .background(FashColors.surfaceContainerHigh)
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 2) {
                    Text(displayName)
                        .font(FashTypography.titleSmall.weight(.semibold))
                        .foregroundStyle(FashColors.textPrimary)
                        .lineLimit(1)
                    Text("@\(handle)")
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(FashColors.textSecondary)
                        .lineLimit(1)
                }
                Spacer()
            }
            .padding(.horizontal, spacing.editorialStart)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        .disabled(onTap == nil)
    }

    private var displayName: String {
        let n = profile?.displayName.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !n.isEmpty { return n }
        return profile?.username ?? "—"
    }

    private var handle: String {
        profile?.username.trimmingCharacters(in: .whitespacesAndNewlines).ifEmpty("—") ?? "—"
    }
}

// MARK: - Metrics

struct ProfileOwnMetricsCard: View {
    @Environment(\.fashSpacing) private var spacing
    let profile: ProfileInfo?
    var onFollowersTap: (() -> Void)? = nil
    var onFollowingTap: (() -> Void)? = nil

    @ViewBuilder
    var body: some View {
        if let profile {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    statCell(ProfileFormatting.formatCount(profile.followerCount), L10n.profileFollowers, action: onFollowersTap)
                    statDivider
                    statCell("\(profile.followingCount)", L10n.profileFollowing, action: onFollowingTap)
                    statDivider
                    statCell("\(profile.productCount)", L10n.profileProducts)
                    statDivider
                    statCell("\(profile.soldCount)", L10n.profileSold)
                }
                .padding(.vertical, 6)
                if showTrustFooter(profile) {
                    Divider().padding(.horizontal, 14).opacity(0.35)
                    ProfileOwnTrustFooter(profile: profile)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                }
            }
            .background(FashColors.surfaceContainer)
            .clipShape(RoundedRectangle(cornerRadius: spacing.radiusCard, style: .continuous))
            .padding(.horizontal, spacing.editorialStart)
            .padding(.bottom, spacing.spacing2)
        }
    }

    private func showTrustFooter(_ p: ProfileInfo) -> Bool {
        let hasRating = (p.rating ?? 0) > 0
        return hasRating || p.productCount > 0 || (p.reputationPoints ?? 0) > 0 || p.hasFastDelivery
    }

    private func statCell(_ value: String, _ label: String, action: (() -> Void)? = nil) -> some View {
        Button(action: { action?() }) {
            VStack(spacing: 2) {
                Text(value)
                    .font(FashTypography.titleSmall.weight(.bold))
                    .foregroundStyle(FashColors.textPrimary)
                Text(label)
                    .font(FashTypography.labelSmall)
                    .foregroundStyle(FashColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(FashColors.outlineMuted.opacity(0.4))
            .frame(width: 1, height: 40)
    }
}

struct SellerProfileMetricsCard: View {
    @Environment(\.fashSpacing) private var spacing
    let profile: ProfileInfo?

    @ViewBuilder
    var body: some View {
        if let profile {
            VStack(spacing: 0) {
                HStack(spacing: 0) {
                    statCell(ProfileFormatting.formatCount(profile.followerCount), L10n.profileFollowers)
                    statDivider
                    statCell("\(profile.followingCount)", L10n.profileFollowing)
                    statDivider
                    statCell("\(profile.productCount)", L10n.profileProducts)
                    statDivider
                    statCell("\(profile.soldCount)", L10n.profileSold)
                }
                .padding(.vertical, 6)
                ProfileSellerTrustLine(profile: profile)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 12)
            }
            .background(FashColors.surfaceContainer)
            .clipShape(RoundedRectangle(cornerRadius: spacing.radiusCard, style: .continuous))
            .padding(.horizontal, spacing.editorialStart)
            .padding(.bottom, spacing.spacing2)
        }
    }

    private func statCell(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .font(FashTypography.titleSmall.weight(.bold))
            Text(label)
                .font(FashTypography.labelSmall)
                .foregroundStyle(FashColors.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }

    private var statDivider: some View {
        Rectangle()
            .fill(FashColors.outlineMuted.opacity(0.4))
            .frame(width: 1, height: 40)
    }
}

struct ProfileOwnTrustFooter: View {
    let profile: ProfileInfo

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: (profile.rating ?? 0) > 0 ? "star.fill" : "star")
                .foregroundStyle((profile.rating ?? 0) > 0 ? FashColors.brandPrimary : FashColors.textSecondary.opacity(0.55))
            VStack(alignment: .leading, spacing: 4) {
                if let rating = profile.rating, rating > 0 {
                    Text(String(format: "%.1f", rating))
                        .font(FashTypography.titleSmall.weight(.bold))
                    if let count = profile.reviewCount, count >= 0 {
                        Text(L10n.profileSellerTrustReviewsCount(count))
                            .font(FashTypography.bodySmall)
                            .foregroundStyle(FashColors.textSecondary)
                    } else {
                        Text(L10n.profileSellerTrustSubtitleScoreOnly)
                            .font(FashTypography.bodySmall)
                            .foregroundStyle(FashColors.textSecondary)
                    }
                } else if profile.productCount > 0 {
                    Text(L10n.profileSellerRatingPending)
                        .font(FashTypography.bodyMedium.weight(.medium))
                    Text(L10n.profileSellerRatingPendingHint)
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(FashColors.textSecondary)
                }
                HStack(spacing: 8) {
                    if let pts = profile.reputationPoints, pts > 0 {
                        trustBadge(L10n.profileReputationPoints(pts))
                    }
                    if profile.hasFastDelivery {
                        trustBadge(L10n.profileFastDelivery, color: FashColors.brandPrimary)
                    }
                }
            }
            Spacer(minLength: 0)
        }
    }

    private func trustBadge(_ text: String, color: Color = FashColors.brandPrimary) -> some View {
        Text(text)
            .font(FashTypography.labelSmall.weight(.medium))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}

struct ProfileSellerTrustLine: View {
    let profile: ProfileInfo

    var body: some View {
        let hasRating = (profile.rating ?? 0) > 0
        let hasShop = profile.productCount > 0
        if !hasRating && !hasShop && profile.reputationPoints == nil && !profile.hasFastDelivery {
            EmptyView()
        } else {
            HStack(alignment: .center, spacing: 10) {
                Image(systemName: hasRating ? "star.fill" : "star")
                    .foregroundStyle(hasRating ? FashColors.brandPrimary : FashColors.textSecondary.opacity(0.45))
                if hasRating, let r = profile.rating {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(String(format: "%.1f", r))
                            .font(FashTypography.titleMedium.weight(.bold))
                        if let c = profile.reviewCount, c >= 0 {
                            Text(L10n.profileSellerTrustReviewsCount(c))
                                .font(FashTypography.bodySmall)
                                .foregroundStyle(FashColors.textSecondary)
                        }
                    }
                } else if hasShop {
                    Text(L10n.profileSellerRatingPending)
                        .font(FashTypography.bodyMedium)
                        .foregroundStyle(FashColors.textSecondary)
                }
                Spacer()
            }
        }
    }
}

// MARK: - Seller blocks

struct SellerProfileFollowBlock: View {
    @Environment(\.fashSpacing) private var spacing
    let isFollowing: Bool
    let inFlight: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(spacing: 8) {
            if isFollowing {
                HStack(spacing: 12) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(FashColors.brandPrimary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.sellerFollowingStatusTitle)
                            .font(FashTypography.titleSmall.weight(.semibold))
                        Text(L10n.sellerFollowingStatusSubtitle)
                            .font(FashTypography.bodySmall)
                            .foregroundStyle(FashColors.textSecondary)
                    }
                    Spacer()
                    Button(L10n.unfollowAction, action: onToggle)
                        .font(FashTypography.labelLarge)
                        .foregroundStyle(FashColors.brandPrimary)
                        .disabled(inFlight)
                }
                .padding(14)
                .background(FashColors.surfaceContainer)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .overlay {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .stroke(FashColors.brandPrimary.opacity(0.22), lineWidth: 1)
                }
            } else {
                Button(action: onToggle) {
                    ZStack {
                        if inFlight {
                            ProgressView().tint(.white)
                        } else {
                            Text(L10n.followButton)
                                .font(FashTypography.titleSmall.weight(.bold))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(
                        LinearGradient(
                            colors: [FashColors.brandPrimary, FashColors.brandPrimary.opacity(0.88)],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                }
                .disabled(inFlight)
                Text(L10n.profileSellerFollowCtaHint)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, spacing.editorialStart)
        .padding(.vertical, spacing.spacing1)
    }
}

struct SellerProfileBodyMeasurements: View {
    @Environment(\.fashSpacing) private var spacing
    let profile: ProfileInfo?

    @ViewBuilder
    var body: some View {
        if let profile, let line = bodyLine(profile) {
            Text(line)
                .font(FashTypography.bodySmall)
                .foregroundStyle(FashColors.textSecondary)
                .padding(.horizontal, spacing.editorialStart)
                .padding(.bottom, spacing.spacing2)
        }
    }

    private func bodyLine(_ p: ProfileInfo) -> String? {
        var parts: [String] = []
        if let h = p.heightCm { parts.append("\(h) cm") }
        if let w = p.weightKg { parts.append(String(format: "%.0f kg", w)) }
        return parts.isEmpty ? nil : parts.joined(separator: " · ")
    }
}

struct SellerProfileTopBadges: View {
    @Environment(\.fashSpacing) private var spacing
    let profile: ProfileInfo?

    @ViewBuilder
    var body: some View {
        let badges = profile?.topBadges.filter { !$0.label.isEmpty } ?? []
        if !badges.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(badges, id: \.badgeId) { badge in
                        HStack(spacing: 4) {
                            if !badge.emoji.isEmpty { Text(badge.emoji) }
                            Text(badge.count > 1 ? "\(badge.label) ×\(badge.count)" : badge.label)
                                .font(FashTypography.labelSmall.weight(.medium))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(FashColors.surfaceContainer)
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, spacing.editorialStart)
            }
            .padding(.bottom, spacing.spacing2)
        }
    }
}

// MARK: - Sizing & quick actions

struct ProfileSizingReferenceCard: View {
    @Environment(\.fashSpacing) private var spacing
    let profile: ProfileInfo?
    var onEdit: () -> Void

    @ViewBuilder
    var body: some View {
        if let profile {
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top) {
                    Image(systemName: "ruler")
                        .foregroundStyle(FashColors.brandPrimary)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.profileSizingRefTitle)
                            .font(FashTypography.titleSmall.weight(.semibold))
                        Text(L10n.profileSizingRefSubtitle)
                            .font(FashTypography.bodySmall)
                            .foregroundStyle(FashColors.textSecondary)
                    }
                    Spacer()
                    Button(L10n.profileSizingRefEdit, action: onEdit)
                        .font(FashTypography.labelLarge)
                        .foregroundStyle(FashColors.brandPrimary)
                }
                sizingContent(profile)
            }
            .padding(14)
            .background(FashColors.surfaceContainer)
            .clipShape(RoundedRectangle(cornerRadius: spacing.radiusCard, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: spacing.radiusCard, style: .continuous)
                    .stroke(FashColors.outlineMuted.opacity(0.28), lineWidth: 1)
            }
            .padding(.horizontal, spacing.editorialStart)
            .padding(.bottom, spacing.spacing2)
        }
    }

    @ViewBuilder
    private func sizingContent(_ p: ProfileInfo) -> some View {
        let unit = p.referenceMeasurementUnit ?? L10n.profileSizingRefUnitDefault
        let measurements = measurementLabels(p, unit: unit)
        let refSize = p.referenceSize?.trimmingCharacters(in: .whitespacesAndNewlines)
        let hasData = (refSize?.isEmpty == false) || !measurements.isEmpty
        if !hasData && p.sizingReferenceCompleted {
            Text(L10n.profileSizingRefCompletedOnly)
                .font(FashTypography.bodyMedium)
        } else if !hasData {
            Text(L10n.profileSizingRefEmptyHint)
                .font(FashTypography.bodySmall)
                .foregroundStyle(FashColors.textSecondary)
            Button(L10n.profileSizingRefEdit, action: onEdit)
                .font(FashTypography.labelLarge)
                .foregroundStyle(FashColors.brandPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .overlay {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(FashColors.brandPrimary.opacity(0.4), lineWidth: 1)
                }
        } else {
            if let size = refSize, !size.isEmpty {
                Text(L10n.profileSizingRefSize(size))
                    .font(FashTypography.titleMedium.weight(.bold))
                    .foregroundStyle(FashColors.brandPrimary)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(FashColors.brandPrimary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            }
            FlowLayout(spacing: 8) {
                ForEach(measurements, id: \.self) { label in
                    Text(label)
                        .font(FashTypography.bodySmall.weight(.medium))
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(FashColors.surfaceContainerHighest)
                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                }
            }
        }
    }

    private func measurementLabels(_ p: ProfileInfo, unit: String) -> [String] {
        var out: [String] = []
        if let v = p.referenceMeasurementChest, v > 0 { out.append(L10n.profileSizingRefChest(v, unit)) }
        if let v = p.referenceMeasurementHem, v > 0 { out.append(L10n.profileSizingRefHem(v, unit)) }
        if let v = p.referenceMeasurementLength, v > 0 { out.append(L10n.profileSizingRefLength(v, unit)) }
        if let v = p.referenceMeasurementShoulders, v > 0 { out.append(L10n.profileSizingRefShoulders(v, unit)) }
        if let v = p.referenceMeasurementSleeveLength, v > 0 { out.append(L10n.profileSizingRefSleeve(v, unit)) }
        return out
    }
}

struct ProfileQuickActionsCard: View {
    @Environment(\.fashSpacing) private var spacing
    let username: String
    let displayName: String
    var onShipping: () -> Void
    var onInvite: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.profileQuickActionsTitle)
                .font(FashTypography.labelMedium.weight(.semibold))
                .foregroundStyle(FashColors.textSecondary)
                .padding(.leading, 4)
            VStack(spacing: 0) {
                if !username.isEmpty {
                    quickRow(icon: "square.and.arrow.up", title: L10n.profileShareShopTitle, subtitle: L10n.profileShareShopSubtitle) {
                        ProfileShare.launch(username: username, displayName: displayName)
                    }
                    Divider().padding(.horizontal, 14).opacity(0.35)
                }
                quickRow(icon: "mappin.and.ellipse", title: L10n.profileShippingAddresses, subtitle: L10n.addressListSubtitleManage, action: onShipping)
                Divider().padding(.horizontal, 14).opacity(0.35)
                quickRow(icon: "person.badge.plus", title: L10n.profileInviteFriendsTitle, subtitle: L10n.profileInviteFriendsSubtitle, action: onInvite)
            }
            .background(FashColors.surfaceContainer)
            .clipShape(RoundedRectangle(cornerRadius: spacing.radiusCard, style: .continuous))
        }
        .padding(.horizontal, spacing.editorialStart)
        .padding(.bottom, spacing.spacing2)
    }

    private func quickRow(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(FashColors.brandPrimary)
                    .frame(width: 40, height: 40)
                    .background(FashColors.brandPrimary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(FashTypography.titleSmall.weight(.semibold))
                    Text(subtitle).font(FashTypography.bodySmall).foregroundStyle(FashColors.textSecondary).lineLimit(2)
                }
                Spacer()
                Image(systemName: "chevron.right").foregroundStyle(FashColors.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }
}

struct SellerListingFocusSection: View {
    @Environment(\.fashSpacing) private var spacing
    let focus: SellerListingFocus?
    let forbidden: Bool
    let loading: Bool
    let aestheticCatalog: [CommonAestheticTagDto]
    var onCategory: (String, String) -> Void = { _, _ in }
    var onBrand: (String, String) -> Void = { _, _ in }
    var onAesthetic: (String, String) -> Void = { _, _ in }

    var body: some View {
        let show = forbidden || loading || (focus?.isEmpty == false)
        if !show { EmptyView() } else {
            VStack(alignment: .leading, spacing: 12) {
                Divider().opacity(0.35)
                Text(L10n.sellerFocusSectionTitle)
                    .font(FashTypography.titleSmall.weight(.semibold))
                Text(L10n.sellerFocusSectionSubtitle)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
                if forbidden {
                    Text(L10n.sellerFocusForbidden)
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(FashColors.textSecondary)
                } else if loading, focus?.isEmpty != false {
                    ProgressView().tint(FashColors.brandPrimary)
                } else if let focus {
                    focusRow(L10n.sellerFocusCategories, items: focus.categories.map { ($0.id, $0.displayLabel()) }, onTap: onCategory)
                    focusRow(L10n.sellerFocusBrands, items: focus.brands.map { ($0.id, $0.name) }, onTap: onBrand)
                    aestheticRow(focus.aestheticTags)
                }
            }
            .padding(.horizontal, spacing.editorialStart)
            .padding(.bottom, spacing.spacing2)
        }
    }

    private func focusRow(_ label: String, items: [(String, String)], onTap: @escaping (String, String) -> Void) -> some View {
        Group {
            if !items.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text(label).font(FashTypography.labelMedium.weight(.medium)).foregroundStyle(FashColors.textSecondary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                                Button(item.1) { onTap(item.0, item.1) }
                                    .font(FashTypography.labelSmall)
                                    .padding(.horizontal, 12)
                                    .padding(.vertical, 8)
                                    .background(FashColors.surfaceContainer)
                                    .clipShape(Capsule())
                                    .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }

    private func aestheticRow(_ tags: [SellerFocusTag]) -> some View {
        let preferVi = AppLocale.currentTag != AppLocale.tagEN
        return focusRow(
            L10n.sellerFocusAesthetics,
            items: tags.map { t in
                (t.id, AestheticTagLabels.resolveLabel(catalog: aestheticCatalog, id: t.id, rawName: t.name, preferVi: preferVi))
            },
            onTap: onAesthetic
        )
    }
}

/// Simple flow layout for measurement chips.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, origin) in result.origins.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y), proposal: .unspecified)
        }
    }

    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, origins: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var origins: [CGPoint] = []
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        return (CGSize(width: maxWidth, height: y + rowHeight), origins)
    }
}

private extension String {
    func ifEmpty(_ fallback: String) -> String {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? fallback : self
    }
}
