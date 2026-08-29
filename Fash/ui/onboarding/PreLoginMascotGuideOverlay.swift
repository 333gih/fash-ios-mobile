import SwiftUI

enum PreLoginMascotGuideContext {
    case loginScreen
    case guestShell
}

private struct PreLoginMascotSlide: Identifiable {
    let id: Int
    let title: String
    let body: String
    let mascotImage: String
}

/// Mascot-led pager shown once before login or on first guest shell entry.
struct PreLoginMascotGuideOverlay: View {
    let context: PreLoginMascotGuideContext
    var onFinish: () -> Void

    @State private var selection = 0

    private var slides: [PreLoginMascotSlide] {
        switch context {
        case .loginScreen:
            return [
                PreLoginMascotSlide(id: 0, title: L10n.appTourIntroTitle, body: L10n.appTourIntroBody, mascotImage: "FashMascotPointUp"),
                PreLoginMascotSlide(id: 1, title: L10n.preLoginLoginEmailTitle, body: L10n.preLoginLoginEmailBody, mascotImage: "FashMascotPointDown"),
                PreLoginMascotSlide(id: 2, title: L10n.preLoginLoginSocialTitle, body: L10n.preLoginLoginSocialBody, mascotImage: "FashMascotPointLeft"),
                PreLoginMascotSlide(id: 3, title: L10n.preLoginLoginGuestTitle, body: L10n.preLoginLoginGuestBody, mascotImage: "FashMascotPointUp"),
            ]
        case .guestShell:
            return [
                PreLoginMascotSlide(id: 0, title: L10n.appTourIntroTitle, body: L10n.appTourIntroBody, mascotImage: "FashMascotPointUp"),
                PreLoginMascotSlide(id: 1, title: L10n.appTourNavHomeTitle, body: L10n.appTourNavHomeBody, mascotImage: "FashMascotPointLeft"),
                PreLoginMascotSlide(id: 2, title: L10n.preLoginGuestSignInTitle, body: L10n.preLoginGuestSignInBody, mascotImage: "FashMascotPointDown"),
            ]
        }
    }

    private var isLast: Bool { selection >= slides.count - 1 }

    var body: some View {
        ZStack {
            Color.black.opacity(0.58).ignoresSafeArea()
            VStack(spacing: 16) {
                HStack {
                    Spacer()
                    Button(L10n.appTourSkip) {
                        PreLoginMascotGuideStore.markCompleted()
                        onFinish()
                    }
                    .font(FashTypography.labelLarge)
                    .foregroundStyle(FashColors.textSecondary)
                }
                .padding(.horizontal, 20)
                .padding(.top, 12)

                VStack(spacing: 12) {
                    FashMascotGuideImage(name: slides[selection].mascotImage, size: 96)
                    Text(slides[selection].title)
                        .font(FashTypography.titleSmall.weight(.bold))
                        .foregroundStyle(FashColors.textPrimary)
                        .multilineTextAlignment(.center)
                    Text(slides[selection].body)
                        .font(FashTypography.bodyMedium)
                        .foregroundStyle(FashColors.textSecondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(.horizontal, 24)
                .padding(.vertical, 20)
                .frame(maxWidth: .infinity)
                .background(FashColors.screen)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .padding(.horizontal, 20)

                FashPromoPageIndicator(pageCount: slides.count, currentPage: selection)

                FashPrimaryButton(
                    title: isLast ? L10n.appTourDone : L10n.welcomeIntroNext,
                    showsArrow: !isLast,
                ) {
                    if isLast {
                        PreLoginMascotGuideStore.markCompleted()
                        onFinish()
                    } else {
                        withAnimation(.easeInOut(duration: 0.25)) {
                            selection = min(selection + 1, slides.count - 1)
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 24)
            }
        }
        .accessibilityAddTraits(.isModal)
    }
}

struct FashMascotGuideImage: View {
    let name: String
    var size: CGFloat = 72

    var body: some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .shadow(color: FashColors.brandPrimary.opacity(0.18), radius: 8, y: 4)
    }
}
