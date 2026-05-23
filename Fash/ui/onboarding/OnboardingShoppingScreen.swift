import SwiftUI

/// SwiftUI port of Android `OnboardingShoppingScreen` (ui.onboarding).
struct OnboardingShoppingScreen: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        OnboardingShoppingScreenBody()
    }
}

private struct OnboardingShoppingScreenBody: View {
    var body: some View {
        FashScreenScaffold(title: "OnboardingShoppingScreen") {
            Text(L10n.appName)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
        }
    }
}

#Preview {
    FashTheme { OnboardingShoppingScreen() }
}
