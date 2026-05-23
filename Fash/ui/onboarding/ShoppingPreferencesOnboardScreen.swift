import SwiftUI

struct ShoppingPreferencesOnboardScreen: View {
    var onContinue: () -> Void = {}

    var body: some View {
        OnboardingStepShell(
            title: L10n.onboardingShoppingTitle,
            bodyText: L10n.onboardingShoppingSubtitle,
            actionTitle: L10n.onboardingContinue,
            onContinue: onContinue,
        )
    }
}
