import SwiftUI

/// Discovery grid cell — Android [ListingGridCard].
struct ListingGridCard: View {
    @Environment(\.fashSpacing) private var spacing
    let item: ListingFeedItem
    var onTap: () -> Void
    var imageAspectRatio: CGFloat = 3 / 4
    var compactFooter: Bool = false
    var showQuickActions: Bool = false
    var onLike: (() -> Void)? = nil
    var onSave: (() -> Void)? = nil

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: spacing.radiusSoftMin, style: .continuous)
    }

    var body: some View {
        GeometryReader { geo in
            let cardW = geo.size.width
            let cardH = cardW / imageAspectRatio
            ZStack(alignment: .bottomLeading) {
                Button(action: onTap) {
                    ZStack(alignment: .bottomLeading) {
                        imageLayer
                        footerGradient
                        footerContent
                    }
                    .frame(width: cardW, height: cardH)
                    .clipShape(shape)
                }
                .buttonStyle(.plain)

                badgesOverlay
                    .frame(width: cardW, height: cardH, alignment: .top)
                    .allowsHitTesting(false)

                if showQuickActions {
                    quickActions
                        .frame(width: cardW, height: cardH, alignment: .topTrailing)
                }
            }
            .frame(width: cardW, height: cardH)
        }
        .aspectRatio(imageAspectRatio, contentMode: .fit)
    }

    @ViewBuilder
    private var imageLayer: some View {
        if item.coverImageUrl.isEmpty {
            Rectangle()
                .fill(FashColors.surfaceContainerHigh)
                .overlay {
                    Text(L10n.noImage)
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(FashColors.textSecondary)
                }
        } else {
            FashAsyncImage(url: FeedImageUrl.resolveListingImageUrl(item.coverImageUrl))
        }
    }

    private var footerGradient: some View {
        LinearGradient(
            colors: [.clear, Color.black.opacity(0.82)],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(maxWidth: .infinity)
        .frame(height: 120)
        .frame(maxHeight: .infinity, alignment: .bottom)
    }

    private var footerContent: some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .center) {
                Text(FeedPriceFormat.format(item.priceVnd))
                    .font(FashTypography.titleSmall)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .lineLimit(1)
                Spacer(minLength: 4)
                if item.likeCount > 0 {
                    HStack(spacing: 3) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 13))
                            .foregroundStyle(.white.opacity(0.95))
                        Text(formatEngagement(item.likeCount))
                            .font(FashTypography.labelSmall)
                            .foregroundStyle(.white.opacity(0.95))
                    }
                }
            }
            let title = item.title.trimmingCharacters(in: .whitespaces)
            if !title.isEmpty {
                Text(title)
                    .font(FashTypography.bodySmall)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .lineLimit(1)
            }
            if !compactFooter, metaLine.hasContent {
                metaRow
            }
            Text(sellerLine)
                .font(FashTypography.labelSmall)
                .foregroundStyle(.white.opacity(0.88))
                .lineLimit(1)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var metaLine: ListingMetaUi {
        ListingMetaUi(
            conditionLabel: conditionLabel(item.condition),
            secondary: secondaryMeta
        )
    }

    @ViewBuilder
    private var metaRow: some View {
        let parts = metaLine
        if !parts.conditionLabel.isEmpty, !parts.secondary.isEmpty {
            HStack(spacing: 6) {
                Text(parts.conditionLabel)
                    .font(FashTypography.labelSmall)
                    .fontWeight(.semibold)
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(Color.white.opacity(0.24))
                    .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                    .lineLimit(1)
                Text(parts.secondary)
                    .font(FashTypography.labelSmall)
                    .foregroundStyle(.white.opacity(0.92))
                    .lineLimit(1)
            }
        } else if !parts.conditionLabel.isEmpty {
            Text(parts.conditionLabel)
                .font(FashTypography.labelSmall)
                .fontWeight(.semibold)
                .foregroundStyle(.white)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(Color.white.opacity(0.24))
                .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
                .lineLimit(1)
        } else if !parts.secondary.isEmpty {
            Text(parts.secondary)
                .font(FashTypography.labelSmall)
                .foregroundStyle(.white.opacity(0.92))
                .lineLimit(1)
        }
    }

    @ViewBuilder
    private var badgesOverlay: some View {
        VStack(alignment: .trailing, spacing: 6) {
            if item.onsiteInspectionCommitment, !compactFooter {
                badgePill(L10n.listingCommitmentBadge, color: Color(hex: 0x1B5E20, alpha: 0.88))
            }
            if let scarcity = scarcityBadge {
                badgePill(scarcity, color: FashColors.brandPrimary.opacity(0.88))
            }
            Spacer()
        }
        .padding(6)
        .overlay(alignment: .topLeading) {
            HStack(spacing: 6) {
                if item.imageUrls.count > 1 {
                    HStack(spacing: 4) {
                        Image(systemName: "photo.on.rectangle")
                            .font(.system(size: 14))
                        Text("\(item.imageUrls.count)")
                            .font(FashTypography.labelSmall)
                    }
                    .foregroundStyle(.white)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.45))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
            }
            .padding(6)
        }
    }

    @ViewBuilder
    private var quickActions: some View {
        HStack(spacing: 4) {
            if let onLike {
                quickActionButton(
                    systemName: item.isLiked ? "heart.fill" : "heart",
                    active: item.isLiked,
                    action: onLike
                )
            }
            if let onSave {
                quickActionButton(
                    systemName: item.isSaved ? "bookmark.fill" : "bookmark",
                    active: item.isSaved,
                    action: onSave
                )
            }
        }
        .padding(6)
    }

    private func quickActionButton(systemName: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(active ? FashColors.brandPrimary : .white)
                .frame(width: 34, height: 34)
                .background(Color.black.opacity(0.38))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }

    private func badgePill(_ text: String, color: Color) -> some View {
        Text(text)
            .font(FashTypography.labelSmall)
            .fontWeight(.semibold)
            .foregroundStyle(.white)
            .padding(.horizontal, 6)
            .padding(.vertical, 4)
            .background(color)
            .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            .lineLimit(1)
    }

    private var secondaryMeta: String {
        [item.categoryName, item.brand, item.size, item.listingAestheticTag]
            .compactMap { $0?.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
    }

    private var sellerLine: String {
        let user = (item.sellerUsername ?? "user").trimmingCharacters(in: .whitespaces)
        if let tag = item.sellerStyleTag?.trimmingCharacters(in: .whitespaces), !tag.isEmpty {
            return "@\(user) · \(tag)"
        }
        return "@\(user)"
    }

    private var scarcityBadge: String? {
        guard !compactFooter else { return nil }
        if item.saveCount >= 3 {
            return L10n.listingBadgeSavedCount(item.saveCount)
        }
        return nil
    }

    private func conditionLabel(_ raw: String) -> String {
        let v = raw.lowercased().trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " ", with: "_")
        switch v {
        case "new": return L10n.conditionNew
        case "like_new", "like-new": return L10n.conditionLikeNew
        case "good": return L10n.conditionGood
        case "fair": return L10n.conditionFair
        default: return raw.trimmingCharacters(in: .whitespaces)
        }
    }

    private func formatEngagement(_ count: Int) -> String {
        if count >= 1_000_000 { return String(format: "%.1fM", Double(count) / 1_000_000) }
        if count >= 1_000 { return String(format: "%.1fK", Double(count) / 1_000) }
        return "\(count)"
    }
}

private struct ListingMetaUi {
    let conditionLabel: String
    let secondary: String
    var hasContent: Bool { !conditionLabel.isEmpty || !secondary.isEmpty }
}

enum FeedPriceFormat {
    static func format(_ price: Int64) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        let n = formatter.string(from: NSNumber(value: price)) ?? "\(price)"
        return "₫\(n)"
    }
}
