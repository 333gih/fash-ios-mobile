import SwiftUI

/// Quick-look bottom sheet when tapping a listing on Explore/Home (Android `ExploreListingPreviewSheet`).
struct ExploreListingPreviewSheet: View {
    let feedItem: ListingFeedItem
    let detail: ListingPreviewDetail?
    let isDetailLoading: Bool
    let isGuestMode: Bool
    var onViewDetail: () -> Void
    var onLike: () -> Void
    var onSave: () -> Void
    var onMessageSeller: () -> Void
    var onOpenSeller: (() -> Void)?
    var onRequestLogin: (() -> Void)?

    @State private var showScrollHint = true
    @State private var canScrollFurther = false

    private enum Metrics {
        static let edgeLeading: CGFloat = 16
        static let edgeTrailing: CGFloat = 12
        static let thumbWidth: CGFloat = 96
        static let thumbHeight: CGFloat = 72
        static let avatarSize: CGFloat = 28
        static let actionIconSize: CGFloat = 38
        static let scrollHintHeight: CGFloat = 44
    }

    var body: some View {
        VStack(spacing: 0) {
            dragHandle

            ZStack(alignment: .bottom) {
                ScrollView {
                    sheetContent
                        .padding(.bottom, scrollContentBottomInset)
                        .background(
                            GeometryReader { proxy in
                                Color.clear.preference(
                                    key: PreviewScrollOffsetKey.self,
                                    value: proxy.frame(in: .named("previewScroll")).minY
                                )
                            }
                        )
                        .background(
                            GeometryReader { proxy in
                                Color.clear.preference(
                                    key: PreviewScrollHeightKey.self,
                                    value: proxy.size.height
                                )
                            }
                        )
                }

                if showScrollHint && canScrollFurther {
                    scrollMoreHint
                        .allowsHitTesting(false)
                }
            }
            .coordinateSpace(name: "previewScroll")
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .onPreferenceChange(PreviewScrollOffsetKey.self) { offset in
                if offset < -8 { showScrollHint = false }
            }
            .onPreferenceChange(PreviewScrollHeightKey.self) { height in
                canScrollFurther = height > 180
            }

            Divider().opacity(0.35)
            actionBar
        }
        .environment(\.locale, AppLocale.locale)
        .onChange(of: feedItem.id) { _, _ in
            showScrollHint = true
        }
    }

    private var scrollContentBottomInset: CGFloat {
        showScrollHint && canScrollFurther ? Metrics.scrollHintHeight + 4 : 8
    }

    private var dragHandle: some View {
        Capsule()
            .fill(FashColors.outlineMuted.opacity(0.45))
            .frame(width: 36, height: 4)
            .padding(.top, 8)
            .padding(.bottom, 4)
            .frame(maxWidth: .infinity)
    }

    private var scrollMoreHint: some View {
        HStack(spacing: 2) {
            Image(systemName: "chevron.down")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(FashColors.brandPrimary)
                .accessibilityLabel(L10n.explorePreviewScrollHintCd)
            Text(L10n.explorePreviewScrollHint)
                .font(.caption.weight(.semibold))
                .foregroundStyle(FashColors.brandPrimary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(FashColors.brandPrimary.opacity(0.1), in: Capsule())
        .padding(.bottom, 4)
        .frame(maxWidth: .infinity)
        .frame(height: Metrics.scrollHintHeight, alignment: .bottom)
        .background(
            LinearGradient(
                colors: [.clear, FashColors.screen.opacity(0.78), FashColors.screen],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }

    private var sheetContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(L10n.explorePreviewSheetTitle)
                .font(.caption.weight(.semibold))
                .foregroundStyle(FashColors.textSecondary)
            Text(L10n.explorePreviewSheetSubtitle)
                .font(.caption)
                .foregroundStyle(FashColors.textSecondary.opacity(0.82))
                .lineLimit(1)
                .padding(.top, 1)
                .padding(.bottom, 6)

            if isSold || isReserved {
                statusBanner
                    .padding(.bottom, 6)
            }

            HStack(alignment: .top, spacing: 10) {
                PreviewImageThumb(urls: resolvedImageURLs, title: displayTitle)
                    .frame(width: Metrics.thumbWidth, height: Metrics.thumbHeight)

                VStack(alignment: .leading, spacing: 4) {
                    priceRow
                    Text(displayTitle)
                        .font(FashTypography.bodyMedium.weight(.bold))
                        .foregroundStyle(FashColors.textPrimary)
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                    metaChips
                        .padding(.top, 2)
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)
            }

            sellerRow
                .padding(.top, 8)

            socialRow
                .padding(.top, 6)

            descriptionBlock
                .padding(.top, 6)

            shippingHint
                .padding(.top, 6)

            Text(L10n.explorePreviewTrustLine)
                .font(.caption)
                .foregroundStyle(FashColors.brandPrimary.opacity(0.88))
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 6)

            detailTeaser
                .padding(.top, 8)
                .padding(.bottom, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.leading, Metrics.edgeLeading)
        .padding(.trailing, Metrics.edgeTrailing)
    }

    private var priceRow: some View {
        HStack(alignment: .bottom, spacing: 6) {
            Text(FeedPriceFormat.format(resolvedPrice))
                .font(.system(size: 15, weight: .bold))
                .foregroundStyle(FashColors.brandPrimary)
                .lineLimit(1)
            if let original = detail?.listPriceVnd, original > resolvedPrice {
                Text(FeedPriceFormat.format(original))
                    .font(.caption)
                    .foregroundStyle(FashColors.textSecondary)
                    .strikethrough()
                    .lineLimit(1)
            }
        }
    }

    @ViewBuilder
    private var metaChips: some View {
        let chips = metaChipLabels
        if !chips.isEmpty {
            PreviewMetaFlowLayout(spacing: 4) {
                ForEach(Array(chips.enumerated()), id: \.offset) { _, chip in
                    Text(chip)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(FashColors.textPrimary)
                        .lineLimit(1)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(FashColors.surfaceContainer, in: Capsule())
                        .overlay(Capsule().stroke(FashColors.outlineMuted.opacity(0.35), lineWidth: 1))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private var sellerRow: some View {
        Button {
            onOpenSeller?()
        } label: {
            HStack(spacing: 6) {
                FashAvatarCircle(url: resolvedSellerAvatarURL, size: Metrics.avatarSize)
                VStack(alignment: .leading, spacing: 1) {
                    Text(sellerHeadline)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(FashColors.textPrimary)
                        .lineLimit(1)
                    Text(sellerSubline)
                        .font(.system(size: 10))
                        .foregroundStyle(FashColors.textSecondary)
                        .lineLimit(1)
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
            }
        }
        .buttonStyle(.plain)
        .disabled(onOpenSeller == nil)
    }

    private var socialRow: some View {
        HStack(spacing: 10) {
            socialStat(
                systemName: resolvedIsLiked ? "heart.fill" : "heart",
                value: FeedEngagementFormat.short(resolvedLikeCount),
                tint: resolvedIsLiked ? FashColors.brandPrimary : FashColors.textSecondary
            )
            socialStat(
                systemName: resolvedIsSaved ? "bookmark.fill" : "bookmark",
                value: FeedEngagementFormat.short(resolvedSaveCount),
                tint: resolvedIsSaved ? FashColors.brandPrimary : FashColors.textSecondary
            )
            if resolvedViewCount > 0 {
                socialStat(
                    systemName: "eye",
                    value: FeedEngagementFormat.short(resolvedViewCount),
                    tint: FashColors.textSecondary
                )
            }
        }
    }

    @ViewBuilder
    private var descriptionBlock: some View {
        if isDetailLoading, detail?.description?.isEmpty != false {
            HStack(spacing: 6) {
                ProgressView()
                    .controlSize(.small)
                    .tint(FashColors.brandPrimary)
                Text(L10n.explorePreviewLoading)
                    .font(.caption)
                    .foregroundStyle(FashColors.textSecondary)
            }
        } else if let description = detail?.description?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !description.isEmpty {
            Text(description)
                .font(.caption)
                .foregroundStyle(FashColors.textPrimary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    @ViewBuilder
    private var shippingHint: some View {
        if let fee = detail?.estimatedShippingVnd, fee > 0 {
            HStack(spacing: 4) {
                Image(systemName: "shippingbox")
                    .font(.system(size: 14))
                    .foregroundStyle(FashColors.brandPrimary)
                Text(shippingLine(fee: fee, region: detail?.shipFromRegion))
                    .font(.caption)
                    .foregroundStyle(FashColors.textSecondary)
                    .lineLimit(1)
            }
        }
    }

    private var detailTeaser: some View {
        Button(action: onViewDetail) {
            HStack(spacing: 6) {
                VStack(alignment: .leading, spacing: 1) {
                    Text(L10n.explorePreviewDetailNudge)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(FashColors.textPrimary)
                        .lineLimit(1)
                    Text(L10n.explorePreviewDetailNudgeSub)
                        .font(.caption)
                        .foregroundStyle(FashColors.textSecondary)
                        .lineLimit(1)
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                HStack(spacing: 1) {
                    Text(L10n.explorePreviewDetailNudgeCta)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(FashColors.brandPrimary)
                        .lineLimit(1)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(FashColors.brandPrimary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(FashColors.surfaceContainer, in: RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .stroke(FashColors.brandPrimary.opacity(0.28), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var actionBar: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                actionIconButton(
                    systemName: resolvedIsLiked ? "heart.fill" : "heart",
                    label: L10n.like,
                    active: resolvedIsLiked,
                    action: {
                        if isGuestMode { onRequestLogin?() } else { onLike() }
                    }
                )
                actionIconButton(
                    systemName: resolvedIsSaved ? "bookmark.fill" : "bookmark",
                    label: L10n.save,
                    active: resolvedIsSaved,
                    action: {
                        if isGuestMode { onRequestLogin?() } else { onSave() }
                    }
                )
                Button(action: onViewDetail) {
                    Text(L10n.explorePreviewViewDetail)
                        .font(.caption.weight(.bold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.85)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: Metrics.actionIconSize)
                }
                .buttonStyle(.borderedProminent)
                .tint(FashColors.brandPrimary)
            }
            Button(action: {
                if isGuestMode { onRequestLogin?() } else { onMessageSeller() }
            }) {
                HStack(spacing: 4) {
                    Image(systemName: "message")
                        .font(.system(size: 14))
                    Text(messageButtonTitle)
                        .font(.caption.weight(.semibold))
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, minHeight: 34)
            }
            .buttonStyle(.bordered)
            .tint(FashColors.brandPrimary)
        }
        .padding(.leading, Metrics.edgeLeading)
        .padding(.trailing, Metrics.edgeTrailing)
        .padding(.top, 6)
        .padding(.bottom, 8)
    }

    private var statusBanner: some View {
        Text(isSold ? L10n.productListingSoldBar : L10n.productReservedOther)
            .font(.caption.weight(.semibold))
            .foregroundStyle(isSold ? FashColors.textSecondary : FashColors.brandPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                (isSold ? FashColors.surfaceContainer : FashColors.brandPrimary.opacity(0.12)),
                in: RoundedRectangle(cornerRadius: 8, style: .continuous)
            )
    }

    private func actionIconButton(systemName: String, label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18))
                .foregroundStyle(active ? FashColors.brandPrimary : FashColors.textPrimary)
                .frame(width: Metrics.actionIconSize, height: Metrics.actionIconSize)
                .overlay(
                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                        .stroke(FashColors.outlineMuted.opacity(0.4), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    private func socialStat(systemName: String, value: String, tint: Color) -> some View {
        Group {
            if !value.isEmpty {
                HStack(spacing: 4) {
                    Image(systemName: systemName)
                        .font(.system(size: 13))
                        .foregroundStyle(tint)
                    Text(value)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(FashColors.textSecondary)
                        .lineLimit(1)
                }
            }
        }
    }

    private var displayTitle: String {
        let fromDetail = detail?.title.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return fromDetail.isEmpty ? feedItem.title : fromDetail
    }

    private var resolvedPrice: Int64 {
        detail?.priceVnd ?? feedItem.price
    }

    private var resolvedIsLiked: Bool {
        detail?.isLiked ?? feedItem.isLiked
    }

    private var resolvedIsSaved: Bool {
        detail?.isSaved ?? feedItem.isSaved
    }

    private var resolvedLikeCount: Int {
        detail?.likeCount ?? feedItem.likeCount
    }

    private var resolvedSaveCount: Int {
        detail?.saveCount ?? feedItem.saveCount
    }

    private var resolvedViewCount: Int {
        detail?.viewCount ?? 0
    }

    private var resolvedSellerAvatarURL: String? {
        guard let raw = detail?.sellerAvatarURL?.trimmingCharacters(in: .whitespacesAndNewlines),
              !raw.isEmpty else { return nil }
        return FeedImageUrl.resolveProfileImageUrlOrNil(raw)
    }

    private var resolvedImageURLs: [String] {
        if let urls = detail?.imageURLs.filter({ !$0.isEmpty }), !urls.isEmpty {
            return urls.compactMap { FeedImageUrl.resolveListingImageUrlOrNil($0) }
        }
        let feedUrls = feedItem.imageUrls.compactMap { FeedImageUrl.resolveListingImageUrlOrNil($0) }
        if !feedUrls.isEmpty { return feedUrls }
        if let url = feedItem.imageURL, !url.isEmpty,
           let resolved = FeedImageUrl.resolveListingImageUrlOrNil(url) {
            return [resolved]
        }
        if !feedItem.coverImageUrl.isEmpty,
           let resolved = FeedImageUrl.resolveListingImageUrlOrNil(feedItem.coverImageUrl) {
            return [resolved]
        }
        return []
    }

    private var resolvedStatus: String {
        let fromDetail = (detail?.status ?? "").lowercased()
        if !fromDetail.isEmpty { return fromDetail }
        return (feedItem.listingStatus ?? "").lowercased()
    }

    private var isSold: Bool { resolvedStatus == "sold" }
    private var isReserved: Bool { resolvedStatus == "reserved" }

    private var buyNowEnabled: Bool {
        BusinessFlowConfig.c2cBuyNowEnabled && !isSold && !isReserved
    }

    private var messageButtonTitle: String {
        buyNowEnabled ? L10n.explorePreviewMessageSeller : L10n.productChat
    }

    private var sellerUsername: String {
        let raw = detail?.sellerUsername ?? feedItem.sellerUsername
        let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? L10n.explorePreviewSellerUsernameFallback : trimmed
    }

    private var sellerHeadline: String {
        if let name = detail?.sellerDisplayName?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
            return name
        }
        return L10n.explorePreviewSellerAtUsername(sellerUsername)
    }

    private var sellerSubline: String {
        var line = L10n.explorePreviewSellerAtUsername(sellerUsername)
        if let count = detail?.sellerListingCount, count >= 0 {
            line += L10n.explorePreviewInlineSeparator + L10n.productSellerProductsCount(count)
        }
        return line
    }

    private var metaChipLabels: [String] {
        var chips: [String] = []
        let conditionRaw = detail?.condition ?? feedItem.condition
        if let condition = previewConditionLabel(conditionRaw.isEmpty ? nil : conditionRaw) {
            chips.append(condition)
        }
        if let size = nonEmpty(detail?.size ?? feedItem.size) { chips.append(size) }
        if let brand = nonEmpty(detail?.brand ?? feedItem.brand) { chips.append(brand) }
        if let category = nonEmpty(detail?.category ?? feedItem.categoryName) { chips.append(category) }
        if let tag = nonEmpty(detail?.aestheticTag ?? feedItem.listingAestheticTag) { chips.append(tag) }
        return chips
    }

    private func nonEmpty(_ raw: String?) -> String? {
        let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return trimmed.isEmpty ? nil : trimmed
    }

    private func previewConditionLabel(_ raw: String?) -> String? {
        guard let raw else { return nil }
        let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return nil }
        switch cleaned.lowercased().replacingOccurrences(of: " ", with: "_") {
        case "new": return L10n.conditionNew
        case "like_new", "like-new": return L10n.conditionLikeNew
        case "good": return L10n.conditionGood
        case "fair": return L10n.conditionFair
        default: return cleaned
        }
    }

    private func shippingLine(fee: Int64, region: String?) -> String {
        var line = L10n.productShippingEstimate(FeedPriceFormat.format(fee))
        if let region, !region.isEmpty {
            line += L10n.explorePreviewInlineSeparator + L10n.productShipFromUpper(region)
        }
        return line
    }
}

private struct PreviewScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct PreviewScrollHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

private struct PreviewImageThumb: View {
    let urls: [String]
    let title: String
    @State private var page = 0

    var body: some View {
        Group {
            if urls.isEmpty {
                ZStack {
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .fill(FashColors.surfaceContainer)
                    Text(L10n.noImage)
                        .font(.caption)
                        .foregroundStyle(FashColors.textSecondary)
                }
            } else if urls.count == 1 {
                FashAsyncImage(url: urls[0], contentMode: .fill)
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .accessibilityLabel(title)
            } else {
                TabView(selection: $page) {
                    ForEach(Array(urls.enumerated()), id: \.offset) { index, url in
                        FashAsyncImage(url: url, contentMode: .fill)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                            .accessibilityLabel(L10n.explorePreviewImagePagerCd(index + 1, urls.count))
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(alignment: .bottomTrailing) {
                    Text("\(page + 1) / \(urls.count)")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                        .padding(4)
                }
            }
        }
    }
}

private enum FeedEngagementFormat {
    static func short(_ count: Int) -> String {
        switch count {
        case ...0: return ""
        case 1_000_000...:
            return String(format: "%.1fM", Double(count) / 1_000_000)
        case 1_000...:
            return String(format: "%.1fk", Double(count) / 1_000)
        default:
            return "\(count)"
        }
    }
}

/// Horizontal flow for meta chips — Android `FlowRow`.
private struct PreviewMetaFlowLayout: Layout {
    var spacing: CGFloat = 4

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? 0
        guard maxWidth > 0 else {
            return CGSize(width: proposal.width ?? 0, height: 0)
        }
        let rows = arrange(maxWidth: maxWidth, subviews: subviews)
        return CGSize(width: maxWidth, height: rows.height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = arrange(maxWidth: bounds.width, subviews: subviews)
        for placement in rows.placements {
            subviews[placement.index].place(
                at: CGPoint(x: bounds.minX + placement.x, y: bounds.minY + placement.y),
                proposal: ProposedViewSize(placement.size)
            )
        }
    }

    private func arrange(maxWidth: CGFloat, subviews: Subviews) -> Arrangement {
        guard maxWidth > 0 else {
            return Arrangement(width: 0, height: 0, placements: [])
        }
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var placements: [Placement] = []

        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(
                ProposedViewSize(width: maxWidth, height: nil)
            )
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            placements.append(Placement(index: index, x: x, y: y, size: size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }

        return Arrangement(width: maxWidth, height: y + rowHeight, placements: placements)
    }

    private struct Placement {
        let index: Int
        let x: CGFloat
        let y: CGFloat
        let size: CGSize
    }

    private struct Arrangement {
        let width: CGFloat
        let height: CGFloat
        let placements: [Placement]
    }
}

#Preview {
    FashTheme {
        ExploreListingPreviewSheet(
            feedItem: ListingFeedItem(
                id: "1",
                title: "Vintage jacket with a longer title that should wrap cleanly",
                price: 250_000,
                imageURL: nil,
                sellerUsername: "seller"
            ),
            detail: nil,
            isDetailLoading: true,
            isGuestMode: false,
            onViewDetail: {},
            onLike: {},
            onSave: {},
            onMessageSeller: {}
        )
        .frame(height: 280)
    }
}
