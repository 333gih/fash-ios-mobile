import SwiftUI

struct UsernameOnboardScreen: View {
    var onContinue: () -> Void = {}

    var body: some View {
        OnboardingStepShell(
            title: L10n.onboardingUsernameScreenTitle,
            bodyText: L10n.onboardingSubtitle,
            actionTitle: L10n.onboardingContinue,
            onContinue: onContinue
        )
    }
}
