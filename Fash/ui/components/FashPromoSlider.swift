import SwiftUI

struct FashPromoSlideDef: Identifiable, Equatable {
    let id: String
    let title: String
    let subtitle: String
    let gradientColors: [Color]
    let badgeText: String?
    let bannerImageUrl: String?
    let navigationType: String
    let navigationPayload: String

    static func fromAdvertising(_ item: AppAdvertisingSlideItem) -> FashPromoSlideDef {
        FashPromoSlideDef(
            id: item.id,
            title: item.title,
            subtitle: item.subtitle,
            gradientColors: gradientForPreset(item.stylePreset),
            badgeText: item.badgeLabel.nilIfEmpty,
            bannerImageUrl: item.bannerImageUrl.nilIfEmpty,
            navigationType: item.navigationType,
            navigationPayload: item.navigationPayload
        )
    }

    private static func gradientForPreset(_ preset: String) -> [Color] {
        switch preset {
        case "gradient_secondary":
            return [FashColors.brandPrimary.opacity(0.75), FashColors.surfaceContainerHigh]
        default:
            return [FashColors.brandPrimary, FashColors.brandPrimary.opacity(0.65)]
        }
    }
}

struct FashPromoSliderView: View {
    @Environment(\.fashSpacing) private var spacing
    let slides: [FashPromoSlideDef]
    /// When true, uses 72pt cards (Home only). All other tabs use standard 112pt.
    var compact: Bool = false
    var onSlideClick: (FashPromoSlideDef, Int) -> Void = { _, _ in }

    @State private var selectedIndex = 0
    @State private var autoAdvanceTask: Task<Void, Never>?

    private var cardHeight: CGFloat { FashPromoMetrics.cardHeight(compact: compact) }

    var body: some View {
        if slides.isEmpty {
            EmptyView()
        } else {
            VStack(spacing: 0) {
                TabView(selection: $selectedIndex) {
                    ForEach(Array(slides.enumerated()), id: \.element.id) { index, slide in
                        promoCard(slide)
                            .padding(.horizontal, 6)
                            .tag(index)
                            .onTapGesture { onSlideClick(slide, index) }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
                .frame(height: cardHeight)
                .overlay(alignment: .bottom) {
                    if slides.count > 1 {
                        FashPromoPageIndicator(pageCount: slides.count, currentPage: selectedIndex)
                            .padding(.bottom, 8)
                    }
                }
            }
            .padding(.top, 6)
            .padding(.bottom, 4)
            .padding(.horizontal, spacing.editorialStart)
            .onAppear { startAutoAdvance(count: slides.count) }
            .onDisappear { autoAdvanceTask?.cancel() }
            .onChange(of: slides.count) { _, count in
                selectedIndex = min(selectedIndex, max(0, count - 1))
                startAutoAdvance(count: count)
            }
        }
    }

    private func promoCard(_ slide: FashPromoSlideDef) -> some View {
        let shape = RoundedRectangle(cornerRadius: spacing.radiusCard, style: .continuous)
        let badge = slide.badgeText?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
            ?? L10n.ordersPromoBadge
        let bannerURL = slide.bannerImageUrl?.trimmingCharacters(in: .whitespacesAndNewlines).nilIfEmpty
        let hasBanner = bannerURL != nil
        let hPad: CGFloat = compact ? 10 : 14
        let vPad: CGFloat = compact ? 8 : 10
        let titleFont = compact ? FashTypography.labelLarge.weight(.bold) : FashTypography.titleSmall.weight(.bold)
        let subtitleFont = compact ? FashTypography.labelSmall : FashTypography.bodySmall

        return GeometryReader { geo in
            let imageStripWidth = hasBanner ? geo.size.width * FashPromoMetrics.imageStripWidthFraction : 0
            HStack(spacing: 0) {
                textPanel(
                    slide: slide,
                    hasBanner: hasBanner,
                    hPad: hPad,
                    vPad: vPad,
                    titleFont: titleFont,
                    subtitleFont: subtitleFont
                )
                .frame(maxWidth: .infinity, maxHeight: .infinity)

                if hasBanner, let url = bannerURL {
                    promoImageStrip(url: url, width: imageStripWidth)
                }
            }
            .overlay(alignment: .topTrailing) {
                Text(badge)
                    .font(FashTypography.labelSmall.weight(.semibold))
                    .foregroundStyle(badgeForeground(hasBanner: hasBanner, slide: slide))
                    .padding(.horizontal, hPad)
                    .padding(.vertical, compact ? 6 : 8)
            }
        }
        .frame(height: cardHeight)
        .clipShape(shape)
        .overlay(shape.stroke(FashColors.outlineMuted.opacity(0.2), lineWidth: 1))
        .contentShape(shape)
    }

    @ViewBuilder
    private func textPanel(
        slide: FashPromoSlideDef,
        hasBanner: Bool,
        hPad: CGFloat,
        vPad: CGFloat,
        titleFont: Font,
        subtitleFont: Font
    ) -> some View {
        let titleColor = textColor(hasBanner: hasBanner, slide: slide)
        ZStack(alignment: .bottomLeading) {
            if hasBanner {
                LinearGradient(
                    colors: [
                        slide.gradientColors.first?.opacity(0.92) ?? FashColors.brandPrimary.opacity(0.92),
                        slide.gradientColors.last?.opacity(0.88) ?? FashColors.brandPrimary.opacity(0.75),
                    ],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            } else {
                LinearGradient(
                    colors: slide.gradientColors,
                    startPoint: .leading,
                    endPoint: .trailing
                )
            }

            VStack(alignment: .leading, spacing: compact ? 2 : 4) {
                Text(slide.title)
                    .font(titleFont)
                    .foregroundStyle(titleColor)
                    .lineLimit(compact ? 1 : 2)
                    .minimumScaleFactor(0.85)
                if !compact || !slide.subtitle.isEmpty {
                    Text(slide.subtitle)
                        .font(subtitleFont)
                        .foregroundStyle(titleColor.opacity(0.92))
                        .lineLimit(compact ? 1 : 2)
                        .minimumScaleFactor(0.85)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, hPad)
            .padding(.vertical, vPad)
            .padding(.trailing, compact ? 28 : 40)
            .padding(.bottom, compact ? 4 : 8)
        }
    }

    @ViewBuilder
    private func promoImageStrip(url: String, width: CGFloat) -> some View {
        ZStack {
            FashColors.surfaceContainer
            FashAsyncImage(url: FeedImageUrl.resolveListingImageUrl(url), contentMode: .fit)
                .frame(maxWidth: width, maxHeight: cardHeight)
                .padding(.horizontal, 4)
                .padding(.vertical, 6)
        }
        .frame(width: width)
        .clipped()
    }

    private func textColor(hasBanner: Bool, slide: FashPromoSlideDef) -> Color {
        if hasBanner {
            return .white
        }
        return slide.gradientColors.first?.fashReadableOn() ?? .white
    }

    private func badgeForeground(hasBanner: Bool, slide: FashPromoSlideDef) -> Color {
        textColor(hasBanner: hasBanner, slide: slide).opacity(0.88)
    }

    private func startAutoAdvance(count: Int) {
        autoAdvanceTask?.cancel()
        guard count > 1 else { return }
        autoAdvanceTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(6.5))
                guard !Task.isCancelled else { break }
                await MainActor.run {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        selectedIndex = (selectedIndex + 1) % count
                    }
                }
            }
        }
    }
}

enum FashPromoSlider {
    static func slides(from response: AppAdvertisingSlidesResponse) -> [FashPromoSlideDef] {
        response.items.map(FashPromoSlideDef.fromAdvertising)
    }
}

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
