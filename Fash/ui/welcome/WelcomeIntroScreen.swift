import SwiftUI

private struct WelcomeIntroSlide: Identifiable {
    let id: Int
    let title: String
    let body: String
    let systemImage: String
    let stylePreset: String
}

/// First-install welcome pager — pre-login intro with VI/EN toggle. Android [WelcomeIntroScreen].
struct WelcomeIntroScreen: View {
    @Environment(\.fashSpacing) private var spacing

    var onSignIn: () -> Void
    var onBrowseGuest: (() -> Void)?

    @State private var selection = 0

    private let slides: [WelcomeIntroSlide] = [
        WelcomeIntroSlide(id: 0, title: L10n.welcomeIntroSlide1Title, body: L10n.welcomeIntroSlide1Body, systemImage: "sparkles", stylePreset: "gradient_primary"),
        WelcomeIntroSlide(id: 1, title: L10n.welcomeIntroSlide2Title, body: L10n.welcomeIntroSlide2Body, systemImage: "magnifyingglass", stylePreset: "gradient_warm"),
        WelcomeIntroSlide(id: 2, title: L10n.welcomeIntroSlide3Title, body: L10n.welcomeIntroSlide3Body, systemImage: "hanger", stylePreset: "gradient_neutral"),
        WelcomeIntroSlide(id: 3, title: L10n.welcomeIntroSlide4Title, body: L10n.welcomeIntroSlide4Body, systemImage: "bubble.left.and.bubble.right.fill", stylePreset: "gradient_primary"),
    ]

    private var isLastSlide: Bool { selection >= slides.count - 1 }

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Button(L10n.welcomeIntroSkip, action: onSignIn)
                    .font(FashTypography.labelLarge)
                    .foregroundStyle(FashColors.textSecondary)
                Spacer()
                LoginLanguageToggle()
            }
            .padding(.horizontal, spacing.editorialStart)
            .padding(.top, 12)
            .padding(.bottom, 8)

            VStack(spacing: 6) {
                FashBrandMarkText(style: FashBrandTypography.markBoldItalicLarge)
                Text(L10n.loginTagline)
                    .font(FashTypography.bodyMedium)
                    .foregroundStyle(FashColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .padding(.horizontal, spacing.editorialStart)
            .padding(.bottom, 12)

            TabView(selection: $selection) {
                ForEach(slides) { slide in
                    slideCard(slide)
                        .tag(slide.id)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .never))
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding(.horizontal, spacing.editorialStart)

            FashPromoPageIndicator(pageCount: slides.count, currentPage: selection)
                .padding(.top, 10)

            VStack(spacing: 10) {
                if isLastSlide {
                    FashPrimaryButton(title: L10n.welcomeIntroSignIn, showsArrow: true, action: onSignIn)
                    if let onBrowseGuest {
                        Button(action: onBrowseGuest) {
                            Text(L10n.welcomeIntroBrowseGuest)
                                .font(FashTypography.labelLarge)
                                .foregroundStyle(FashColors.brandPrimary)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 8)
                        }
                        .buttonStyle(.plain)
                    }
                } else {
                    FashPrimaryButton(title: L10n.welcomeIntroNext, showsArrow: true) {
                        withAnimation(.easeInOut(duration: 0.28)) {
                            selection = min(selection + 1, slides.count - 1)
                        }
                    }
                }
            }
            .padding(.horizontal, spacing.editorialStart)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(FashColors.screen.ignoresSafeArea())
    }

    @ViewBuilder
    private func slideCard(_ slide: WelcomeIntroSlide) -> some View {
        let cornerRadius: CGFloat = 28
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(FashColors.surfaceContainer)
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(FashColors.brandPrimary.opacity(0.12))
                        .frame(width: 88, height: 88)
                    Image(systemName: slide.systemImage)
                        .font(.system(size: 36, weight: .semibold))
                        .foregroundStyle(FashColors.brandPrimary)
                }
                .padding(.top, 28)
                VStack(spacing: 8) {
                    Text(slide.title)
                        .font(FashTypography.titleMedium.weight(.bold))
                        .foregroundStyle(FashColors.textPrimary)
                        .multilineTextAlignment(.center)
                    Text(slide.body)
                        .font(FashTypography.bodyMedium)
                        .foregroundStyle(FashColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 20)
                Spacer(minLength: 0)
            }
            scrim(for: slide.stylePreset)
        }
        .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
    }

    @ViewBuilder
    private func scrim(for preset: String) -> some View {
        switch preset {
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
