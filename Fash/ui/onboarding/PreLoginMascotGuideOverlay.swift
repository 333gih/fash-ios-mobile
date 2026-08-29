import SwiftUI

enum PreLoginMascotGuideContext {
    case loginScreen
    case guestShell
}

private struct PreLoginGuideSlide: Identifiable {
    let id: Int
    let title: String
    let body: String
    let anchor: FeatureTourAnchor?
}

/// Mascot spotlight coach marks on login / guest shell — one focused target per step.
struct PreLoginMascotGuideOverlay: View {
    let context: PreLoginMascotGuideContext
    var anchorFrames: [FeatureTourAnchor: CGRect] = [:]
    var onFinish: () -> Void

    @State private var selection = 0

    private var slides: [PreLoginGuideSlide] {
        switch context {
        case .loginScreen:
            return [
                PreLoginGuideSlide(id: 0, title: L10n.appTourIntroTitle, body: L10n.appTourIntroBody, anchor: nil),
                PreLoginGuideSlide(id: 1, title: L10n.preLoginLoginEmailTitle, body: L10n.preLoginLoginEmailBody, anchor: .loginEmailForm),
                PreLoginGuideSlide(id: 2, title: L10n.preLoginLoginSocialTitle, body: L10n.preLoginLoginSocialBody, anchor: .loginSocialRow),
                PreLoginGuideSlide(id: 3, title: L10n.preLoginLoginGuestTitle, body: L10n.preLoginLoginGuestBody, anchor: .loginGuestBrowse),
            ]
        case .guestShell:
            return [
                PreLoginGuideSlide(id: 0, title: L10n.appTourIntroTitle, body: L10n.appTourIntroBody, anchor: nil),
                PreLoginGuideSlide(id: 1, title: L10n.appTourNavHomeTitle, body: L10n.appTourNavHomeBody, anchor: .bottomHome),
                PreLoginGuideSlide(id: 2, title: L10n.preLoginGuestSignInTitle, body: L10n.preLoginGuestSignInBody, anchor: .bottomProfile),
            ]
        }
    }

    private var slide: PreLoginGuideSlide { slides[selection] }
    private var isLast: Bool { selection >= slides.count - 1 }

    var body: some View {
        MascotSpotlightOverlay(
            title: slide.title,
            bodyText: slide.body,
            anchor: slide.anchor,
            anchorFrames: anchorFrames,
            stepIndex: selection,
            stepCount: slides.count,
            showBack: selection > 0,
            isLast: isLast,
            onBack: {
                withAnimation(.easeInOut(duration: 0.22)) {
                    selection = max(selection - 1, 0)
                }
            },
            onNext: advance,
            onSkip: finish
        )
    }

    private func advance() {
        if isLast {
            finish()
        } else {
            withAnimation(.easeInOut(duration: 0.22)) {
                selection = min(selection + 1, slides.count - 1)
            }
        }
    }

    private func finish() {
        PreLoginMascotGuideStore.markCompleted()
        onFinish()
    }
}

struct FashMascotGuideImage: View {
    let name: String
    var size: CGFloat = 72
    var flipHorizontal: Bool = false

    var body: some View {
        Image(name)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .scaleEffect(x: flipHorizontal ? -1 : 1, y: 1)
            .shadow(color: FashColors.brandPrimary.opacity(0.18), radius: 8, y: 4)
    }
}
