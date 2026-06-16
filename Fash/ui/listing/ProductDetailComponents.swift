import SwiftUI

enum ProductDetailComponents {
    static func sectionTitle(_ text: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(FashColors.brandPrimary)
            Text(text)
                .font(FashTypography.labelLarge.weight(.semibold))
                .foregroundStyle(FashColors.brandPrimary)
        }
    }

    static func sectionCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FashColors.surfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    @ViewBuilder
    static func heroImage(
        detail: ListingDetail,
        galleryIndex: Binding<Int>,
        onLike: @escaping () -> Void,
        onSave: @escaping () -> Void
    ) -> some View {
        let urls = detail.imageUrls.compactMap { FeedImageUrl.resolveListingImageUrlOrNil($0) }
        let shape = RoundedRectangle(cornerRadius: 0, style: .continuous)
        ZStack(alignment: .bottom) {
            Group {
                if urls.isEmpty {
                    Rectangle().fill(FashColors.surfaceContainerHigh).frame(height: UIScreen.main.bounds.width)
                } else if urls.count == 1, let u = urls.first {
                    FashAsyncImage(url: u, contentMode: .fill)
                        .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
                        .clipped()
                } else {
                    let safe = min(max(galleryIndex.wrappedValue, 0), urls.count - 1)
                    TabView(selection: galleryIndex) {
                        ForEach(Array(urls.enumerated()), id: \.offset) { index, url in
                            FashAsyncImage(url: url, contentMode: .fill)
                                .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.width)
                                .clipped()
                                .tag(index)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .never))
                    .frame(height: UIScreen.main.bounds.width)
                    .onAppear { galleryIndex.wrappedValue = safe }
                }
            }
            .clipShape(shape)

            HStack(alignment: .bottom, spacing: 10) {
                passiveStatPill(icon: "eye", count: detail.viewCount)
                heroEngagementButton(
                    systemName: detail.isLiked ? "heart.fill" : "heart",
                    count: detail.likeCount,
                    highlighted: detail.isLiked,
                    accessibilityLabel: L10n.like,
                    action: onLike
                )
                .animation(.easeInOut(duration: 0.18), value: detail.isLiked)
                heroEngagementButton(
                    systemName: detail.isSaved ? "bookmark.fill" : "bookmark",
                    count: detail.saveCount,
                    highlighted: detail.isSaved,
                    accessibilityLabel: L10n.save,
                    action: onSave
                )
                .animation(.easeInOut(duration: 0.18), value: detail.isSaved)
                Spacer(minLength: 0)
                if !urls.isEmpty {
                    Text("\(min(max(galleryIndex.wrappedValue, 0), urls.count - 1) + 1)/\(urls.count)")
                        .font(FashTypography.labelSmall.weight(.semibold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.black.opacity(0.55))
                        .clipShape(Capsule())
                        .allowsHitTesting(false)
                }
            }
            .padding(12)
        }
    }

    private static func passiveStatPill(icon: String, count: Int) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
            Text("\(count)")
                .font(FashTypography.labelSmall.weight(.semibold))
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(Color.black.opacity(0.55))
        .clipShape(Capsule())
    }

    private static func heroEngagementButton(
        systemName: String,
        count: Int,
        highlighted: Bool,
        accessibilityLabel: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            VStack(spacing: 3) {
                Image(systemName: systemName)
                    .font(.system(size: 20, weight: .semibold))
                Text("\(count)")
                    .font(FashTypography.labelSmall.weight(.semibold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
            }
            .foregroundStyle(highlighted ? FashColors.brandPrimary : .white)
            .frame(minWidth: 48, minHeight: 48)
            .padding(.horizontal, 6)
            .background(Color.black.opacity(highlighted ? 0.72 : 0.58))
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(
                        highlighted ? FashColors.brandPrimary.opacity(0.95) : Color.white.opacity(0.38),
                        lineWidth: highlighted ? 1.5 : 1
                    )
            }
        }
        .buttonStyle(.plain)
        .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .accessibilityLabel(accessibilityLabel)
    }

    static func sellerCard(
        detail: ListingDetail,
        profile: ProfileInfo?,
        isFollowing: Bool,
        onVisitShop: @escaping () -> Void,
        onFollow: @escaping () -> Void,
        onUnfollow: @escaping () -> Void
    ) -> some View {
        sectionCard {
            sectionTitle(L10n.productSectionSeller, icon: "storefront")
            HStack(alignment: .center, spacing: 12) {
                let avatar = detail.sellerAvatarUrl?.nilIfEmpty
                    ?? profile?.avatarUrl.nilIfEmpty
                FashAvatarCircle(url: avatar.flatMap { FeedImageUrl.resolveListingImageUrlOrNil($0) }, size: 52)
                VStack(alignment: .leading, spacing: 4) {
                    Text(profile?.displayName.nilIfEmpty ?? detail.sellerDisplayName?.nilIfEmpty ?? detail.sellerUsername?.nilIfEmpty ?? "—")
                        .font(FashTypography.titleSmall.weight(.semibold))
                        .foregroundStyle(FashColors.textPrimary)
                        .lineLimit(1)
                    if let count = detail.sellerListingCount ?? profile?.productCount {
                        Text(L10n.productSellerProductsCount(count))
                            .font(FashTypography.bodySmall)
                            .foregroundStyle(FashColors.textSecondary)
                            .lineLimit(1)
                    }
                    if let u = detail.sellerUsername?.nilIfEmpty {
                        Text("@\(u)")
                            .font(FashTypography.bodySmall)
                            .foregroundStyle(FashColors.textSecondary)
                            .lineLimit(1)
                    }
                }
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                .layoutPriority(1)

                HStack(spacing: 8) {
                    if isFollowing {
                        sellerActionPill(
                            title: L10n.productActionFollowingSeller,
                            foreground: FashColors.textSecondary,
                            background: Color.clear,
                            border: FashColors.outlineMuted,
                            action: onUnfollow
                        )
                    } else {
                        sellerActionPill(
                            title: L10n.productActionFollowSeller,
                            foreground: FashColors.onBrandPrimary,
                            background: FashColors.brandPrimary,
                            border: nil,
                            action: onFollow
                        )
                    }
                    sellerActionPill(
                        title: L10n.productVisitShop,
                        foreground: FashColors.brandPrimary,
                        background: Color.clear,
                        border: FashColors.brandPrimary,
                        action: onVisitShop
                    )
                }
                .fixedSize(horizontal: true, vertical: true)
            }
        }
    }

    private static func sellerActionPill(
        title: String,
        foreground: Color,
        background: Color,
        border: Color?,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(title)
                .font(FashTypography.labelSmall.weight(.semibold))
                .lineLimit(1)
                .minimumScaleFactor(0.85)
                .foregroundStyle(foreground)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(background)
                .clipShape(Capsule())
                .overlay {
                    if let border {
                        Capsule().stroke(border, lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.plain)
        .fixedSize(horizontal: true, vertical: true)
    }

    static func priceInfoCard(
        detail: ListingDetail,
        onCategoryTap: @escaping (String?, String?) -> Void
    ) -> some View {
        sectionCard {
            if let parent = detail.parentCategoryName?.nilIfEmpty {
                HStack(spacing: 6) {
                    categoryChip(parent) { onCategoryTap(detail.parentCategoryId, nil) }
                    if let cat = detail.category?.nilIfEmpty {
                        Image(systemName: "chevron.right")
                            .font(.caption2)
                            .foregroundStyle(FashColors.textSecondary)
                        categoryChip(cat) { onCategoryTap(detail.categoryId, nil) }
                    }
                }
            } else if let cat = detail.category?.nilIfEmpty {
                categoryChip(cat) { onCategoryTap(detail.categoryId, nil) }
            }
            Text(FeedPriceFormat.format(detail.priceVnd))
                .font(FashTypography.headlineMedium.weight(.bold))
                .foregroundStyle(FashColors.brandPrimary)
            if let list = detail.listPriceVnd, list > detail.priceVnd {
                Text(FeedPriceFormat.format(list))
                    .font(FashTypography.bodyMedium)
                    .foregroundStyle(FashColors.textSecondary)
                    .strikethrough()
            }
            Text(detail.title)
                .font(FashTypography.titleLarge.weight(.bold))
                .foregroundStyle(FashColors.textPrimary)
            if let created = detail.createdAtIso?.nilIfEmpty {
                Text(L10n.productListedOn(String(created.prefix(16))))
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
            }
        }
    }

    private static func categoryChip(_ label: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label.uppercased())
                .font(FashTypography.labelSmall.weight(.semibold))
                .foregroundStyle(FashColors.brandPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .overlay(Capsule().stroke(FashColors.brandPrimary.opacity(0.6), lineWidth: 1))
        }
        .buttonStyle(.plain)
    }

    static func atGlanceCard(
        detail: ListingDetail,
        onBrandTap: @escaping () -> Void,
        onOriginTap: @escaping () -> Void
    ) -> some View {
        sectionCard {
            sectionTitle(L10n.productSectionAtAGlance, icon: "square.grid.2x2")
            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                glanceCell(title: L10n.productBrand, value: detail.brand ?? "—", valueColor: FashColors.brandPrimary, action: onBrandTap)
                glanceCell(
                    title: L10n.productSpecOrigin,
                    value: originLabel(detail),
                    valueColor: FashColors.brandPrimary,
                    action: onOriginTap
                )
                glanceCell(
                    title: L10n.productSize,
                    value: detail.size ?? "—",
                    valueColor: FashColors.textPrimary,
                    action: nil
                )
                glanceCell(
                    title: L10n.productConditionLabel,
                    value: ProductConditionFormat.label(for: detail.condition) ?? detail.condition,
                    valueColor: conditionColor(detail.condition),
                    action: nil
                )
            }
            if let wear = ListingWearSeason.summary(
                seasonKeys: detail.seasonKeys,
                climateZones: detail.climateZones,
                macroRegions: detail.macroRegions,
                yearRoundWear: detail.yearRoundWear,
                localeVi: AppLocale.currentTag != AppLocale.tagEN
            ) {
                Text(L10n.productWearSeasonLabel)
                    .font(FashTypography.labelSmall)
                    .foregroundStyle(FashColors.textSecondary)
                Text(wear)
                    .font(FashTypography.bodyMedium)
                    .foregroundStyle(FashColors.textPrimary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }

    private static func originLabel(_ detail: ListingDetail) -> String {
        if let iso = detail.countryIso2?.nilIfEmpty {
            let name = detail.countryName?.nilIfEmpty ?? iso
            return "\(name) \(flagEmoji(iso))"
        }
        return detail.countryName?.nilIfEmpty ?? "—"
    }

    private static func flagEmoji(_ iso2: String) -> String {
        let upper = iso2.uppercased()
        guard upper.count == 2 else { return "" }
        return upper.unicodeScalars.compactMap { scalar in
            guard let s = UnicodeScalar(127397 + scalar.value) else { return nil }
            return String(s)
        }.joined()
    }

    private static func conditionColor(_ condition: String) -> Color {
        let c = condition.lowercased()
        if c.contains("new") { return Color.green }
        if c.contains("fair") { return Color.green.opacity(0.85) }
        return FashColors.textPrimary
    }

    private static func glanceCell(title: String, value: String, valueColor: Color, action: (() -> Void)?) -> some View {
        let content = VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(FashTypography.labelSmall)
                .foregroundStyle(FashColors.textSecondary)
            Text(value)
                .font(FashTypography.bodyMedium.weight(.semibold))
                .foregroundStyle(valueColor)
                .lineLimit(2)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FashColors.surfaceContainerHigh)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

        return Group {
            if let action {
                Button(action: action) { content }.buttonStyle(.plain)
            } else {
                content
            }
        }
    }

    static func measurementsCard(detail: ListingDetail) -> some View {
        let rows: [(String, Double?)] = [
            (L10n.productMeasChest, detail.measurementChest),
            (L10n.productMeasLength, detail.measurementLength),
            (L10n.productMeasShoulders, detail.measurementShoulders),
            (L10n.productMeasSleeve, detail.measurementSleeveLength),
            (L10n.productMeasHem, detail.measurementHem),
        ].filter { $0.1 != nil }
        guard !rows.isEmpty else { return AnyView(EmptyView()) }
        return AnyView(
            sectionCard {
                sectionTitle(L10n.productSectionMeasurements, icon: "ruler")
                ForEach(rows, id: \.0) { label, value in
                    HStack {
                        Text(label)
                            .foregroundStyle(FashColors.textSecondary)
                        Spacer()
                        Text(measurementText(value, unit: detail.measurementUnit))
                            .foregroundStyle(FashColors.textPrimary)
                    }
                    .font(FashTypography.bodyMedium)
                }
            }
        )
    }

    private static func measurementText(_ value: Double?, unit: String?) -> String {
        guard let value else { return L10n.productMeasEmpty }
        let u = unit?.nilIfEmpty ?? "cm"
        return String(format: "%.1f %@", value, u)
    }

    static func shippingCard(detail: ListingDetail, showInfo: Binding<Bool>) -> some View {
        sectionCard {
            sectionTitle(L10n.productSectionShipping, icon: "shippingbox")
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: "shippingbox.fill")
                    .foregroundStyle(FashColors.brandPrimary)
                VStack(alignment: .leading, spacing: 4) {
                    if let fee = detail.estimatedShippingVnd, fee > 0 {
                        Text(L10n.productShippingEstimate(FeedPriceFormat.format(fee)))
                            .font(FashTypography.bodyMedium.weight(.semibold))
                            .foregroundStyle(FashColors.textPrimary)
                    } else {
                        Text(L10n.productShippingContactSeller)
                            .font(FashTypography.bodyMedium.weight(.semibold))
                    }
                    if let region = detail.countryName?.nilIfEmpty {
                        Text(L10n.productShipFromUpper(region.uppercased()))
                            .font(FashTypography.bodySmall)
                            .foregroundStyle(FashColors.textSecondary)
                    }
                }
                Spacer()
                Button { showInfo.wrappedValue = true } label: {
                    Image(systemName: "info.circle")
                        .foregroundStyle(FashColors.textSecondary)
                }
            }
        }
    }

    static func aboutCard(
        detail: ListingDetail,
        onTagTap: @escaping (AestheticTagRef) -> Void
    ) -> some View {
        sectionCard {
            sectionTitle(L10n.productSectionAbout, icon: "doc.text")
            if !detail.description.isEmpty {
                Text(detail.description)
                    .font(FashTypography.bodyMedium)
                    .foregroundStyle(FashColors.textSecondary)
            }
            if !detail.aestheticTagRefs.isEmpty {
                Text(L10n.productSectionStyle)
                    .font(FashTypography.labelMedium.weight(.semibold))
                    .foregroundStyle(FashColors.textSecondary)
                    .padding(.top, 4)
                ProductDetailTagFlowLayout(spacing: 8) {
                    ForEach(detail.aestheticTagRefs, id: \.label) { tag in
                        Button {
                            onTagTap(tag)
                        } label: {
                            Text("#\(tag.label)")
                                .font(FashTypography.labelMedium)
                                .foregroundStyle(FashColors.brandPrimary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(FashColors.brandPrimary.opacity(0.12))
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }

    static func statusBanner(mode: ProductBottomBarMode) -> some View {
        Group {
            switch mode {
            case .sold:
                Text(L10n.productListingSoldBar)
            case .reservedOther:
                Text(L10n.productReservedOther)
            case .reservedBuyer:
                Text(L10n.productReservedBuyer)
            case .normal:
                EmptyView()
            }
        }
        .font(FashTypography.labelLarge.weight(.semibold))
        .foregroundStyle(FashColors.textPrimary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(FashColors.surfaceContainerHigh)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

/// Simple horizontal flow for tags.
private struct ProductDetailTagFlowLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, frame) in result.frames.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + frame.minX, y: bounds.minY + frame.minY), proposal: .unspecified)
        }
    }
    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, frames: [CGRect]) {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var frames: [CGRect] = []
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            frames.append(CGRect(x: x, y: y, width: size.width, height: size.height))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        return (CGSize(width: maxWidth, height: y + rowHeight), frames)
    }
}

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
