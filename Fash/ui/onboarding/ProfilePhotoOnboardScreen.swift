import SwiftUI

struct ProfilePhotoOnboardScreen: View {
    var onContinue: () -> Void = {}

    var body: some View {
        OnboardingStepShell(
            title: L10n.onboardingProfilePhotoTitle,
            bodyText: L10n.onboardingProfilePhotoSubtitle,
            actionTitle: L10n.onboardingContinue,
            onContinue: onContinue
        )
    }
}
