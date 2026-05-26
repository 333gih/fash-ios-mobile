import SwiftUI

struct SizingReferenceScreen: View {
    var onContinue: () -> Void = {}

    var body: some View {
        OnboardingStepShell(
            title: L10n.onboardingSizingScreenTitle,
            bodyText: L10n.onboardingSizingBodyFirstSubtitle,
            actionTitle: L10n.onboardingContinue,
            onContinue: onContinue
        )
    }
}
