import SwiftUI

private struct LoginHeroSlide: Identifiable {
    let id: String
    let title: String
    let subtitle: String
    let badgeLabel: String
    let bannerImageUrl: String?
    let fallbackCaption: String?
}

struct LoginHeroCarousel: View {
    let remoteSlides: [AppAdvertisingSlideItem]

    @State private var selection = 0
    private let timer = Timer.publish(every: 5.5, on: .main, in: .common).autoconnect()

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
                fallbackCaption: nil
            )
        }
        if !cms.isEmpty { return cms }
        return [
            LoginHeroSlide(id: "local1", title: "", subtitle: "", badgeLabel: "", bannerImageUrl: nil, fallbackCaption: L10n.loginHeroSlide1Caption),
            LoginHeroSlide(id: "local2", title: "", subtitle: "", badgeLabel: "", bannerImageUrl: nil, fallbackCaption: L10n.loginHeroSlide2Caption),
            LoginHeroSlide(id: "local3", title: "", subtitle: "", badgeLabel: "", bannerImageUrl: nil, fallbackCaption: L10n.loginHeroSlide3Caption),
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
            .frame(maxWidth: .infinity)
            .frame(minHeight: 160, maxHeight: 280)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))

            HStack(spacing: 6) {
                ForEach(slides.indices, id: \.self) { index in
                    Capsule()
                        .fill(index == selection ? FashColors.brandPrimary : FashColors.outlineMuted.opacity(0.55))
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
    }

    @ViewBuilder
    private func slideCard(_ slide: LoginHeroSlide, index: Int) -> some View {
        ZStack(alignment: .bottomLeading) {
            FashColors.surfaceContainer
            if let urlString = slide.bannerImageUrl, let url = URL(string: urlString) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image.resizable().scaledToFill()
                    default:
                        FashColors.surfaceContainerLow
                    }
                }
            } else {
                Image(systemName: "sparkles")
                    .font(.system(size: 56, weight: .light))
                    .foregroundStyle(FashColors.brandPrimary.opacity(0.35))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            LinearGradient(
                colors: [Color.clear, FashColors.brandPrimary.opacity(0.12)],
                startPoint: .top,
                endPoint: .bottom
            )
            VStack(alignment: .leading, spacing: 4) {
                if !slide.badgeLabel.isEmpty {
                    Text(slide.badgeLabel)
                        .font(FashTypography.labelLarge)
                        .foregroundStyle(FashColors.brandPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(FashColors.surface.opacity(0.9))
                        .clipShape(Capsule())
                }
                let title = slide.title.isEmpty ? (slide.fallbackCaption ?? "") : slide.title
                if !title.isEmpty {
                    Text(title)
                        .font(FashTypography.labelLarge.weight(.bold))
                        .foregroundStyle(FashColors.textPrimary.opacity(0.9))
                        .lineLimit(2)
                }
                if !slide.subtitle.isEmpty {
                    Text(slide.subtitle)
                        .font(FashTypography.bodyMedium)
                        .foregroundStyle(FashColors.textSecondary)
                        .lineLimit(2)
                }
            }
            .padding(12)
            .accessibilityLabel(L10n.loginHeroPagerCd(String(index + 1), String(slides.count)))
        }
        .clipped()
    }
}
