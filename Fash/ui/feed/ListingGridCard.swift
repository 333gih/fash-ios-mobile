import SwiftUI

/// Discovery grid cell — Android [ListingGridCard].
struct ListingGridCard: View {
    @Environment(\.fashSpacing) private var spacing
    let item: ListingFeedItem
    var onTap: () -> Void
    var imageAspectRatio: CGFloat = 3 / 4
    var compactFooter: Bool = false
    var showQuickActions: Bool = false
    var statusOverlayLabel: String? = nil
    var onLike: (() -> Void)? = nil
    var onSave: (() -> Void)? = nil

    private enum FooterMetrics {
        static let rowSpacing: CGFloat = 2
        static let paddingH: CGFloat = 8
        static let paddingV: CGFloat = 6
        static let priceRow: CGFloat = 20
        static let titleRow: CGFloat = 16
        static let conditionRow: CGFloat = 20
        static let secondaryRow: CGFloat = 14
        static let sellerRow: CGFloat = 14

        static func fullContentHeight() -> CGFloat {
            let rows = priceRow + titleRow + conditionRow + secondaryRow + sellerRow
            return rows + rowSpacing * 4 + paddingV * 2
        }

        static func compactContentHeight(hasTitle: Bool) -> CGFloat {
            var rows = priceRow + sellerRow
            if hasTitle { rows += titleRow }
            let gaps: CGFloat = hasTitle ? rowSpacing * 2 : rowSpacing
            return rows + gaps + paddingV * 2
        }
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: spacing.radiusSoftMin, style: .continuous)
    }

    private var meta: ListingMetaUi {
        ListingMetaUi(
            conditionLabel: conditionLabel(item.condition),
            secondary: secondaryMeta
        )
    }

    private var displayTitle: String {
        item.title.trimmingCharacters(in: .whitespaces)
    }

    private var footerHeight: CGFloat {
        if compactFooter {
            return FooterMetrics.compactContentHeight(hasTitle: !displayTitle.isEmpty)
        }
        return FooterMetrics.fullContentHeight()
    }

    var body: some View {
        GeometryReader { geo in
            let cardW = geo.size.width
            let cardH = cardW / imageAspectRatio
            ZStack(alignment: .bottomLeading) {
                Button(action: onTap) {
                    ZStack(alignment: .bottomLeading) {
                        imageLayer
                        footerGradient(height: max(footerHeight + 12, 108))
                        footerContent
                    }
                    .frame(width: cardW, height: cardH)
                    .clipShape(shape)
                }
                .buttonStyle(.plain)

                topLeadingOverlay
                    .frame(width: cardW, height: cardH, alignment: .topLeading)
                    .allowsHitTesting(false)

                topTrailingBadges
                    .frame(width: cardW, height: cardH, alignment: .topTrailing)
                    .padding(.top, showQuickActions ? 44 : 0)
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

    private var displayImageUrl: String {
        let cover = item.coverImageUrl.trimmingCharacters(in: .whitespaces)
        if !cover.isEmpty { return cover }
        return item.imageUrls.first?.trimmingCharacters(in: .whitespaces) ?? ""
    }

    @ViewBuilder
    private var imageLayer: some View {
        Group {
            if displayImageUrl.isEmpty {
                Rectangle()
                    .fill(FashColors.surfaceContainerHigh)
                    .overlay {
                        Text(L10n.noImage)
                            .font(FashTypography.bodySmall)
                            .foregroundStyle(FashColors.textSecondary)
                    }
            } else {
                FashAsyncImage(url: displayImageUrl)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func footerGradient(height: CGFloat) -> some View {
        LinearGradient(
            colors: [.clear, Color.black.opacity(0.82)],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(maxWidth: .infinity)
        .frame(height: height)
        .frame(maxHeight: .infinity, alignment: .bottom)
    }

    private var footerContent: some View {
        VStack(alignment: .leading, spacing: FooterMetrics.rowSpacing) {
            priceRow
            titleRow
            if !compactFooter {
                conditionRow
                secondaryMetaRow
            }
            sellerRow
        }
        .padding(.horizontal, FooterMetrics.paddingH)
        .padding(.vertical, FooterMetrics.paddingV)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var priceRow: some View {
        HStack(alignment: .center, spacing: 4) {
            Text(FeedPriceFormat.format(item.priceVnd))
                .font(FashTypography.titleSmall)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .lineLimit(1)
                .minimumScaleFactor(0.85)
            Spacer(minLength: 0)
            if item.likeCount > 0 {
                HStack(spacing: 3) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.95))
                    Text(formatEngagement(item.likeCount))
                        .font(FashTypography.labelSmall)
                        .foregroundStyle(.white.opacity(0.95))
                        .lineLimit(1)
                }
                .layoutPriority(1)
            }
        }
        .frame(height: FooterMetrics.priceRow, alignment: .center)
    }

    @ViewBuilder
    private var titleRow: some View {
        Group {
            if !displayTitle.isEmpty {
                FashMarqueeText(
                    text: displayTitle,
                    font: FashTypography.bodySmall,
                    fontWeight: .semibold,
                    color: .white,
                    lineHeight: FooterMetrics.titleRow
                )
            } else {
                Color.clear
            }
        }
        .frame(
            height: compactFooter ? (displayTitle.isEmpty ? 0 : FooterMetrics.titleRow) : FooterMetrics.titleRow,
            alignment: .leading
        )
    }

    @ViewBuilder
    private var conditionRow: some View {
        Group {
            if !meta.conditionLabel.isEmpty {
                conditionPill(meta.conditionLabel)
            } else {
                Color.clear
            }
        }
        .frame(height: FooterMetrics.conditionRow, alignment: .leading)
    }

    @ViewBuilder
    private var secondaryMetaRow: some View {
        Group {
            if !meta.secondary.isEmpty {
                FashMarqueeText(
                    text: meta.secondary,
                    font: FashTypography.labelSmall,
                    color: .white.opacity(0.92),
                    lineHeight: FooterMetrics.secondaryRow
                )
            } else {
                Color.clear
            }
        }
        .frame(height: FooterMetrics.secondaryRow, alignment: .leading)
    }

    private var sellerRow: some View {
        FashMarqueeText(
            text: sellerLine,
            font: FashTypography.labelSmall,
            color: .white.opacity(0.88),
            lineHeight: FooterMetrics.sellerRow
        )
        .frame(height: FooterMetrics.sellerRow, alignment: .leading)
    }

    private func conditionPill(_ label: String) -> some View {
        Text(label)
            .font(FashTypography.labelSmall.weight(.semibold))
            .foregroundStyle(.white)
            .lineLimit(1)
            .truncationMode(.tail)
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.white.opacity(0.24))
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            .frame(maxWidth: 160, alignment: .leading)
            .fixedSize(horizontal: true, vertical: false)
    }

    @ViewBuilder
    private var topLeadingOverlay: some View {
        VStack(alignment: .leading, spacing: 6) {
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
            if let status = statusOverlayLabel?.trimmingCharacters(in: .whitespacesAndNewlines), !status.isEmpty {
                Text(status)
                    .font(FashTypography.labelSmall.weight(.semibold))
                    .foregroundStyle(.white)
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.45))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
            }
        }
        .padding(6)
    }

    @ViewBuilder
    private var topTrailingBadges: some View {
        VStack(alignment: .trailing, spacing: 6) {
            if item.onsiteInspectionCommitment, !compactFooter {
                badgePill(L10n.listingCommitmentBadge, color: Color(hex: 0x1B5E20, alpha: 0.88))
            }
            if let scarcity = scarcityBadge {
                badgePill(scarcity, color: FashColors.brandPrimary.opacity(0.88))
            }
        }
        .padding(6)
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
            .truncationMode(.tail)
    }

    private var secondaryMeta: String {
        func p(_ raw: String?) -> String? {
            guard let trimmed = raw?.trimmingCharacters(in: .whitespaces), !trimmed.isEmpty else { return nil }
            return trimmed
        }
        let cat = p(item.categoryName)
        let brand = p(item.brand)
        let size = p(item.size)
        let sellerStyle = p(item.sellerStyleTag)
        let vibe = p(item.listingAestheticTag).flatMap { (tag: String) -> String? in
            if let sellerStyle, tag.caseInsensitiveCompare(sellerStyle) == .orderedSame { return nil }
            return tag
        }
        return [cat, brand, size, vibe].compactMap { $0 }.joined(separator: " · ")
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
        if let createdAt = item.createdAt?.trimmingCharacters(in: .whitespaces), !createdAt.isEmpty {
            let formatter = ISO8601DateFormatter()
            formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            var date = formatter.date(from: createdAt)
            if date == nil {
                formatter.formatOptions = [.withInternetDateTime]
                date = formatter.date(from: createdAt)
            }
            if let date {
                let ageMs = Date().timeIntervalSince(date) * 1_000
                if ageMs >= 0, ageMs < 2 * 60 * 60 * 1_000 {
                    return L10n.listingBadgeJustListed
                }
            }
        }
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
        case "new_with_tags", "new-with-tags": return L10n.conditionNew
        default:
            let cleaned = raw.trimmingCharacters(in: .whitespaces)
            return cleaned.contains("_") ? cleaned.replacingOccurrences(of: "_", with: " ").capitalized : cleaned
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
}
