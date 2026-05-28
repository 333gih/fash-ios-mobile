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
    var cardHeight: CGFloat = 112
    var onSlideClick: (FashPromoSlideDef, Int) -> Void = { _, _ in }

    @State private var selectedIndex = 0
    @State private var autoAdvanceTask: Task<Void, Never>?

    private var compact: Bool { cardHeight < 100 }

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
        let hasBanner = !(slide.bannerImageUrl?.isEmpty ?? true)
        let titleColor: Color = hasBanner ? .white : slide.gradientColors.first?.fashReadableOn() ?? .white
        let hPad: CGFloat = compact ? 10 : 16
        let vPad: CGFloat = compact ? 8 : 12

        return ZStack(alignment: .topTrailing) {
            Group {
                if let url = slide.bannerImageUrl, !url.isEmpty {
                    FashAsyncImage(url: FeedImageUrl.resolveListingImageUrl(url), contentMode: .fill)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .clipped()
                    LinearGradient(
                        colors: [
                            Color.black.opacity(0.55),
                            Color.black.opacity(0.28),
                            Color.black.opacity(0.62),
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                } else {
                    LinearGradient(
                        colors: slide.gradientColors,
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Text(badge)
                .font(FashTypography.labelSmall.weight(.semibold))
                .foregroundStyle(titleColor.opacity(0.85))
                .padding(.horizontal, hPad)
                .padding(.vertical, compact ? 6 : 12)

            VStack(alignment: .leading, spacing: compact ? 2 : 4) {
                Text(slide.title)
                    .font((compact ? FashTypography.labelLarge : FashTypography.titleSmall).weight(.bold))
                    .foregroundStyle(titleColor)
                    .lineLimit(compact ? 1 : 2)
                if !compact || !slide.subtitle.isEmpty {
                    Text(slide.subtitle)
                        .font(compact ? FashTypography.labelSmall : FashTypography.bodySmall)
                        .foregroundStyle(titleColor.opacity(0.92))
                        .lineLimit(compact ? 1 : 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, hPad)
            .padding(.vertical, vPad)
            .padding(.trailing, compact ? 32 : 48)
            .padding(.bottom, compact ? 4 : 10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
        .frame(height: cardHeight)
        .clipShape(shape)
        .clipped()
        .contentShape(shape)
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
