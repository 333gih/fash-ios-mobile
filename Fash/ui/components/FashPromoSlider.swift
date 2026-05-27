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
    let slides: [FashPromoSlideDef]
    var cardHeight: CGFloat = 112
    var onSlideClick: (FashPromoSlideDef, Int) -> Void = { _, _ in }

    @State private var selectedIndex = 0
    @State private var autoAdvanceTask: Task<Void, Never>?

    var body: some View {
        if slides.isEmpty { EmptyView() } else {
            VStack(spacing: 8) {
                TabView(selection: $selectedIndex) {
                    ForEach(Array(slides.enumerated()), id: \.element.id) { index, slide in
                        promoCard(slide)
                            .padding(.horizontal, 24)
                            .tag(index)
                            .onTapGesture { onSlideClick(slide, index) }
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: slides.count > 1 ? .automatic : .never))
                .frame(height: cardHeight)
            }
            .padding(.vertical, 6)
            .onAppear { startAutoAdvance(count: slides.count) }
            .onDisappear { autoAdvanceTask?.cancel() }
        }
    }

    private func promoCard(_ slide: FashPromoSlideDef) -> some View {
        ZStack(alignment: .bottomLeading) {
            if let url = slide.bannerImageUrl {
                FashAsyncImage(url: url)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .clipped()
            } else {
                LinearGradient(colors: slide.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
            }
            LinearGradient(colors: [.clear, .black.opacity(0.55)], startPoint: .center, endPoint: .bottom)
            VStack(alignment: .leading, spacing: 4) {
                if let badge = slide.badgeText {
                    Text(badge)
                        .font(FashTypography.labelSmall)
                        .fontWeight(.semibold)
                        .foregroundStyle(.white.opacity(0.9))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(.white.opacity(0.18)))
                }
                Text(slide.title)
                    .font(FashTypography.titleSmall)
                    .fontWeight(.bold)
                    .foregroundStyle(.white)
                    .lineLimit(2)
                if !slide.subtitle.isEmpty {
                    Text(slide.subtitle)
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(.white.opacity(0.88))
                        .lineLimit(2)
                }
            }
            .padding(14)
        }
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    private func startAutoAdvance(count: Int) {
        autoAdvanceTask?.cancel()
        guard count > 1 else { return }
        autoAdvanceTask = Task {
            while !Task.isCancelled {
                try? await Task.sleep(for: .seconds(6.5))
                guard !Task.isCancelled else { break }
                await MainActor.run {
                    withAnimation {
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
