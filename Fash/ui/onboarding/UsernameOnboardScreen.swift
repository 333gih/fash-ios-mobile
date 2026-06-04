import SwiftUI

struct UsernameOnboardScreen: View {
    @Environment(AppDependencies.self) private var deps
    @Bindable var viewModel: OnboardingViewModel
    var onStepComplete: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            OnboardingStepHeader(
                title: L10n.onboardingUsernameScreenTitle,
                displayProgressStep: viewModel.uiProgressStep,
                progressTotal: viewModel.progressTotalSteps,
                onBack: { _ = viewModel.goBack(deps: deps) }
            )
            .padding(.horizontal, 8)
            .padding(.top, 8)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(FashColors.brandPrimary.opacity(0.12))
                        .frame(width: 72, height: 72)
                        .overlay {
                            Image(systemName: "person")
                                .font(.system(size: 32))
                                .foregroundStyle(FashColors.brandPrimary)
                        }

                    Text(L10n.profileSetupChooseName)
                        .font(FashTypography.headlineSmall.weight(.bold))
                        .foregroundStyle(FashColors.textPrimary)
                    Text(L10n.profileSetupSubtitle)
                        .font(FashTypography.bodyMedium)
                        .foregroundStyle(FashColors.textSecondary)

                    HStack(spacing: 8) {
                        Text("@")
                            .font(FashTypography.bodyLarge.weight(.medium))
                            .foregroundStyle(FashColors.brandPrimary)
                        TextField(L10n.profileSetupUsernameHint, text: Binding(
                            get: { viewModel.username },
                            set: { viewModel.onUsernameChange($0) }
                        ))
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .font(FashTypography.bodyLarge)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(FashColors.surfaceContainer)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                    .overlay {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(
                                viewModel.isUsernameValid() && !viewModel.username.isEmpty
                                    ? FashColors.brandPrimary.opacity(0.55)
                                    : FashColors.outlineMuted.opacity(0.5),
                                lineWidth: viewModel.isUsernameValid() && !viewModel.username.isEmpty ? 2 : 1
                            )
                    }

                    if viewModel.isUsernameValid(), !viewModel.username.isEmpty {
                        Label(L10n.profileSetupUsernameAvailable, systemImage: "checkmark.circle.fill")
                            .font(FashTypography.bodyMedium)
                            .foregroundStyle(FashColors.brandPrimary)
                    }

                    HStack(alignment: .top, spacing: 12) {
                        Image(systemName: "info.circle")
                            .foregroundStyle(FashColors.brandPrimary.opacity(0.9))
                        Text(L10n.profileSetupUsernameRules)
                            .font(FashTypography.bodySmall)
                            .foregroundStyle(FashColors.textSecondary)
                    }
                    .padding(14)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(FashColors.surfaceContainerLow)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
            }

            FashPrimaryButton(
                title: L10n.profileSetupComplete,
                isLoading: viewModel.isSubmitting,
                enabled: viewModel.canSubmitUsername() && !viewModel.isSubmitting
            ) {
                viewModel.submitUsernameOnboard(deps: deps, onSuccess: onStepComplete)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(FashColors.screen)
    }
}
