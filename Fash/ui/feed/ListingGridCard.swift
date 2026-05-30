import SwiftUI

/// Discovery grid cell — Android [ListingGridCard].
struct ListingGridCard: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(\.listingMasonryColumnWidth) private var masonryColumnWidth
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
        static let priceMinHeight: CGFloat = 20
        static let titleLineHeight: CGFloat = 16
        static let metaLineHeight: CGFloat = 14
        static let sellerLineHeight: CGFloat = 14
        static let gradientBleedAboveContent: CGFloat = 20
    }

    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: spacing.radiusSoftMin, style: .continuous)
    }

    private var metaUi: ListingMetaUi {
        guard !compactFooter else {
            return ListingMetaUi(conditionLabel: "", secondary: "", combinedA11y: "")
        }
        let cond = conditionLabel(item.condition)
        let secondary = secondaryMeta
        let combined = [cond, secondary]
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }
            .joined(separator: " · ")
        return ListingMetaUi(conditionLabel: cond, secondary: secondary, combinedA11y: combined)
    }

    private var displayTitle: String {
        ListingFeedFormatters.sanitizeListingUiText(item.title).trimmingCharacters(in: .whitespaces)
    }

    private var accessibilityLabel: String {
        let title = displayTitle
        let price = FeedPriceFormat.format(item.priceVnd)
        let user = ListingFeedFormatters.sanitizeListingUiText(item.sellerUsername)
            .trimmingCharacters(in: .whitespaces)
        let userLine = user.isEmpty ? "user" : user
        let status = statusOverlayLabel?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        var parts: [String] = []
        if !title.isEmpty { parts.append(title) }
        parts.append(price)
        if !metaUi.combinedA11y.isEmpty { parts.append(metaUi.combinedA11y) }
        if !status.isEmpty { parts.append(status) }
        parts.append(L10n.listingCardA11ySellerRole)
        parts.append(userLine)
        return parts.joined(separator: ". ")
    }

    var body: some View {
        let tile = ZStack(alignment: .bottomLeading) {
            Button(action: onTap) {
                ZStack(alignment: .bottomLeading) {
                    imageLayer
                    footerColumn
                }
            }
            .buttonStyle(.plain)

            topLeadingOverlay
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .allowsHitTesting(false)

            topTrailingChrome
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
        }

        Group {
            if masonryColumnWidth != nil {
                // Parent masonry sets width + height from cover aspect ratio.
                tile.frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                tile
                    .aspectRatio(imageAspectRatio, contentMode: .fit)
                    .fixedSize(horizontal: false, vertical: true)
                    .frame(maxWidth: .infinity)
            }
        }
        .layoutPriority(1)
        .clipShape(shape)
        .contentShape(shape)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(accessibilityLabel)
    }

    private var displayImageUrl: String {
        let cover = item.coverImageUrl.trimmingCharacters(in: .whitespaces)
        if !cover.isEmpty { return cover }
        return item.imageUrls.first?.trimmingCharacters(in: .whitespaces) ?? ""
    }

    private var layoutColumnWidth: CGFloat {
        if let masonryColumnWidth, masonryColumnWidth > 0 {
            return masonryColumnWidth
        }
        return Self.estimatedFeedColumnWidth(spacing: spacing)
    }

    /// Matches two-column masonry width when the parent does not inject [listingMasonryColumnWidth].
    private static func estimatedFeedColumnWidth(spacing: FashSpacing) -> CGFloat {
        let screen = UIScreen.main.bounds.width
        let gap = spacing.spacing2
        return ListingMasonryGrid.columnWidth(
            containerWidth: screen,
            leadingInset: ListingMasonryGrid.feedGridHorizontalInset,
            trailingInset: ListingMasonryGrid.feedGridHorizontalInset,
            columnGap: gap
        )
    }

    @ViewBuilder
    private var imageLayer: some View {
        let columnW = layoutColumnWidth
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
                let tileAspect = ListingMasonryGrid.tileAspectWidthOverHeight(for: item)
                let px = FeedListingImageSizer.pixelSize(
                    columnWidthPoints: columnW,
                    aspectRatio: tileAspect
                )
                let feedUrl = FeedListingImageSizer.urlForFeedGrid(
                    displayImageUrl,
                    columnWidthPoints: columnW,
                    aspectRatio: tileAspect
                )
                FashAsyncImage(
                    url: feedUrl,
                    contentMode: masonryColumnWidth != nil ? .fit : .fill,
                    targetPixelSize: px
                )
                .background(FashColors.surfaceContainerHigh)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
    }

    /// Bottom gradient footer — Android `Column` + `Brush.verticalGradient`.
    private var footerColumn: some View {
        VStack(alignment: .leading, spacing: FooterMetrics.rowSpacing) {
            priceRow
            titleRow
            if !compactFooter, metaUi.hasAny {
                ListingCardMetaRow(parts: metaUi, lineHeight: FooterMetrics.metaLineHeight)
            }
            sellerRow
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, FooterMetrics.paddingH)
        .padding(.vertical, FooterMetrics.paddingV)
        .background {
            LinearGradient(
                colors: [.clear, Color.black.opacity(0.82)],
                startPoint: .top,
                endPoint: .bottom
            )
            .padding(.top, -FooterMetrics.gradientBleedAboveContent)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var priceRow: some View {
        HStack(alignment: .center, spacing: 4) {
            Text(FeedPriceFormat.format(item.priceVnd))
                .font(FashTypography.titleSmall)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .lineLimit(1)
                .truncationMode(.tail)
                .frame(maxWidth: .infinity, alignment: .leading)

            let likes = ListingFeedFormatters.formatEngagementShort(item.likeCount)
            if !likes.isEmpty {
                HStack(spacing: 3) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 13))
                        .foregroundStyle(.white.opacity(0.95))
                    Text(likes)
                        .font(FashTypography.labelSmall)
                        .fontWeight(.medium)
                        .foregroundStyle(.white.opacity(0.95))
                        .lineLimit(1)
                }
            }
        }
        .frame(minHeight: FooterMetrics.priceMinHeight)
    }

    @ViewBuilder
    private var titleRow: some View {
        if !displayTitle.isEmpty {
            ListingCardMarqueeText(
                text: displayTitle,
                font: FashTypography.bodySmall,
                fontWeight: .semibold,
                lineHeight: FooterMetrics.titleLineHeight
            )
        }
    }

    private var sellerRow: some View {
        ListingCardMarqueeText(
            text: sellerLine,
            font: FashTypography.labelSmall,
            color: .white.opacity(0.88),
            lineHeight: FooterMetrics.sellerLineHeight
        )
    }

    @ViewBuilder
    private var topLeadingOverlay: some View {
        let status = statusOverlayLabel?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if item.imageUrls.count > 1 || !status.isEmpty {
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
                    .accessibilityLabel(L10n.listingCardPhotoStackA11y(item.imageUrls.count))
                }
                if !status.isEmpty {
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
    }

    @ViewBuilder
    private var topTrailingChrome: some View {
        VStack(alignment: .trailing, spacing: 6) {
            topTrailingBadges
            if showQuickActions {
                quickActions
            }
        }
        .padding(4)
        .zIndex(2)
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
        .allowsHitTesting(false)
    }

    @ViewBuilder
    private var quickActions: some View {
        HStack(spacing: 4) {
            if let onLike {
                quickActionButton(
                    systemName: item.isLiked ? "heart.fill" : "heart",
                    label: L10n.like,
                    active: item.isLiked,
                    action: onLike
                )
            }
            if let onSave {
                quickActionButton(
                    systemName: item.isSaved ? "bookmark.fill" : "bookmark",
                    label: L10n.save,
                    active: item.isSaved,
                    action: onSave
                )
            }
        }
    }

    private func quickActionButton(
        systemName: String,
        label: String,
        active: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 20, weight: .semibold))
                .foregroundStyle(active ? FashColors.brandPrimary : .white)
                .frame(width: 36, height: 36)
                .background(Color.black.opacity(0.35))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
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
            let cleaned = ListingFeedFormatters.sanitizeListingUiText(raw)
            return cleaned.isEmpty ? nil : cleaned
        }
        let cat = p(item.categoryName)
        let brand = p(item.brand)
        let size = p(item.size)
        let sellerStyle = p(item.sellerStyleTag)
        let vibe = p(item.listingAestheticTag).flatMap { tag -> String? in
            if let sellerStyle, tag.caseInsensitiveCompare(sellerStyle) == .orderedSame { return nil }
            return tag
        }
        return [cat, brand, size, vibe].compactMap { $0 }.joined(separator: " · ")
    }

    private var sellerLine: String {
        let user = ListingFeedFormatters.sanitizeListingUiText(item.sellerUsername)
            .trimmingCharacters(in: .whitespaces)
        let resolved = user.isEmpty ? "user" : user
        let tag = ListingFeedFormatters.sanitizeListingUiText(item.sellerStyleTag)
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if !tag.isEmpty {
            return "@\(resolved) · \(tag)"
        }
        return "@\(resolved)"
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
        let cleaned = ListingFeedFormatters.sanitizeListingUiText(raw)
        guard !cleaned.isEmpty else { return "" }
        let v = cleaned.lowercased().trimmingCharacters(in: .whitespaces).replacingOccurrences(of: " ", with: "_")
        switch v {
        case "new": return L10n.conditionNew
        case "like_new", "like-new": return L10n.conditionLikeNew
        case "good": return L10n.conditionGood
        case "fair": return L10n.conditionFair
        default: return cleaned
        }
    }
}

private struct ListingMetaUi {
    let conditionLabel: String
    let secondary: String
    let combinedA11y: String

    var hasAny: Bool {
        !conditionLabel.trimmingCharacters(in: .whitespaces).isEmpty
            || !secondary.trimmingCharacters(in: .whitespaces).isEmpty
    }
}

/// Android `ListingCardMetaRow` — condition pill + secondary marquee.
private struct ListingCardMetaRow: View {
    let parts: ListingMetaUi
    let lineHeight: CGFloat

    private var condition: String { parts.conditionLabel.trimmingCharacters(in: .whitespaces) }
    private var secondary: String { parts.secondary.trimmingCharacters(in: .whitespaces) }

    var body: some View {
        Group {
            if !condition.isEmpty, !secondary.isEmpty {
                HStack(alignment: .center, spacing: 6) {
                    conditionPill(maxWidth: 112)
                    ListingCardMarqueeText(
                        text: secondary,
                        font: FashTypography.labelSmall,
                        color: .white.opacity(0.92),
                        lineHeight: lineHeight
                    )
                    .layoutPriority(1)
                }
            } else if !condition.isEmpty {
                conditionPill(maxWidth: 160)
            } else if !secondary.isEmpty {
                ListingCardMarqueeText(
                    text: secondary,
                    font: FashTypography.labelSmall,
                    color: .white.opacity(0.92),
                    lineHeight: lineHeight
                )
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(minHeight: lineHeight, alignment: .leading)
    }

    private func conditionPill(maxWidth: CGFloat) -> some View {
        ListingCardMarqueeText(
            text: condition,
            font: FashTypography.labelSmall,
            fontWeight: .semibold,
            lineHeight: lineHeight
        )
        .padding(.horizontal, 6)
        .padding(.vertical, 3)
        .frame(maxWidth: maxWidth, alignment: .leading)
        .background(Color.white.opacity(0.24))
        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
    }
}
