import SwiftUI

private struct LoginHeroSlide: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let badgeLabel: String
    let bannerImageUrl: String?
    let fallbackCaption: String?
    let stylePreset: String
}

struct LoginHeroCarousel: View {
    let remoteSlides: [AppAdvertisingSlideItem]

    @State private var selection = 0
    @State private var floatOffset: CGFloat = 0
    private let timer = Timer.publish(every: 5.5, on: .main, in: .common).autoconnect()

    private let heroCornerRadius: CGFloat = 28

    private var slides: [LoginHeroSlide] {
        let cms = remoteSlides.compactMap { item -> LoginHeroSlide? in
            let title = item.title.trimmingCharacters(in: .whitespaces)
            let subtitle = item.subtitle.trimmingCharacters(in: .whitespaces)
            let image = item.bannerImageUrl.trimmingCharacters(in: .whitespaces)
            if title.isEmpty && subtitle.isEmpty && image.isEmpty { return nil }
            return LoginHeroSlide(
                id: item.id.isEmpty ? UUID().uuidString : item.id,
                title: title,
                subtitle: subtitle,
                badgeLabel: item.badgeLabel.trimmingCharacters(in: .whitespaces),
                bannerImageUrl: image.isEmpty ? nil : image,
                fallbackCaption: nil,
                stylePreset: item.stylePreset
            )
        }
        if !cms.isEmpty { return cms }
        return [
            LoginHeroSlide(id: "local1", title: "", subtitle: "", badgeLabel: "", bannerImageUrl: nil, fallbackCaption: L10n.loginHeroSlide1Caption, stylePreset: "gradient_primary"),
            LoginHeroSlide(id: "local2", title: "", subtitle: "", badgeLabel: "", bannerImageUrl: nil, fallbackCaption: L10n.loginHeroSlide2Caption, stylePreset: "gradient_warm"),
            LoginHeroSlide(id: "local3", title: "", subtitle: "", badgeLabel: "", bannerImageUrl: nil, fallbackCaption: L10n.loginHeroSlide3Caption, stylePreset: "gradient_neutral"),
        ]
    }

    var body: some View {
        VStack(spacing: 6) {
            TabView(selection: $selection) {
                ForEach(Array(slides.enumerated()), id: \.element.id) { index, slide in
                    slideCard(slide, index: index)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(FashColors.surfaceContainer)
            .clipShape(RoundedRectangle(cornerRadius: heroCornerRadius, style: .continuous))

            HStack(spacing: 6) {
                ForEach(slides.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == selection ? FashColors.brandPrimary : FashColors.outlineMuted.opacity(0.7))
                        .frame(width: index == selection ? 18 : 6, height: 6)
                        .animation(.easeInOut(duration: 0.22), value: selection)
                }
            }
        }
        .onReceive(timer) { _ in
            guard !slides.isEmpty else { return }
            withAnimation(.easeInOut(duration: 0.35)) {
                selection = (selection + 1) % slides.count
            }
        }
        .onChange(of: remoteSlides) { _, _ in
            selection = 0
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 3.2).repeatForever(autoreverses: true)) {
                floatOffset = -6
            }
        }
    }

    @ViewBuilder
    private func slideCard(_ slide: LoginHeroSlide, index: Int) -> some View {
        ZStack(alignment: .bottomLeading) {
            FashColors.surfaceContainerLow
            if let urlString = slide.bannerImageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        FashColors.surfaceContainerLow
                    }
                }
                .offset(y: floatOffset * 0.6)
            } else {
                LoginHeroTrenchIllustration()
                    .padding(12)
                    .offset(y: floatOffset)
            }
            scrim(for: slide.stylePreset)
            if !slide.badgeLabel.isEmpty {
                Text(slide.badgeLabel)
                    .font(FashTypography.labelSmall.weight(.semibold))
                    .foregroundStyle(FashColors.brandPrimary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(FashColors.screen.opacity(0.9))
                    .clipShape(Capsule())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(10)
            }
            VStack(alignment: .leading, spacing: 2) {
                if !displayTitle(for: slide).isEmpty {
                    Text(displayTitle(for: slide))
                        .font(FashTypography.labelLarge.weight(.bold))
                        .foregroundStyle(FashColors.textPrimary.opacity(0.9))
                        .lineLimit(2)
                }
                if !slide.subtitle.isEmpty {
                    Text(slide.subtitle)
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(FashColors.textPrimary.opacity(0.8))
                        .lineLimit(2)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
            .accessibilityLabel(L10n.loginHeroPagerCd(String(index + 1), String(slides.count)))
        }
        .clipped()
    }

    private func displayTitle(for slide: LoginHeroSlide) -> String {
        slide.title.isEmpty ? (slide.fallbackCaption ?? "") : slide.title
    }

    @ViewBuilder
    private func scrim(for preset: String) -> some View {
        switch preset.trimmingCharacters(in: .whitespaces) {
        case "gradient_warm":
            LinearGradient(
                colors: [
                    Color(red: 0.85, green: 0.65, blue: 0.48).opacity(0.08),
                    Color.clear,
                    FashColors.brandPrimary.opacity(0.10),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case "gradient_neutral":
            LinearGradient(
                colors: [
                    FashColors.surfaceContainerLow.opacity(0.10),
                    Color.clear,
                    FashColors.surfaceContainerHighest.opacity(0.30),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        default:
            LinearGradient(
                colors: [Color.clear, FashColors.brandPrimary.opacity(0.12)],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }
}

/// Minimal trench illustration — Android `login_hero_trench`.
private struct LoginHeroTrenchIllustration: View {
    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height
            ZStack {
                Ellipse()
                    .fill(Color(red: 0.90, green: 0.82, blue: 0.75))
                    .frame(width: w * 0.16, height: h * 0.19)
                    .offset(y: -h * 0.28)
                RoundedRectangle(cornerRadius: w * 0.08)
                    .fill(Color(red: 0.78, green: 0.65, blue: 0.48))
                    .frame(width: w * 0.42, height: h * 0.55)
                    .offset(y: h * 0.04)
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color(red: 0.56, green: 0.43, blue: 0.31))
                    .frame(width: w * 0.55, height: h * 0.04)
                    .offset(y: h * 0.18)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
}
