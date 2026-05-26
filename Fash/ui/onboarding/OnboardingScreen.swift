import SwiftUI

struct OnboardingScreen: View {
    var onContinue: () -> Void = {}

    var body: some View {
        OnboardingStepShell(
            title: L10n.onboardingTitle,
            bodyText: L10n.onboardingSubtitle,
            actionTitle: L10n.onboardingContinue,
            onContinue: onContinue
        )
    }
}
