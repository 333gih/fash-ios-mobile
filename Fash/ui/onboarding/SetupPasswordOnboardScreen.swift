import SwiftUI

struct SetupPasswordOnboardScreen: View {
    @Environment(AppDependencies.self) private var deps
    @Bindable var viewModel: OnboardingViewModel
    var onStepComplete: () -> Void

    @State private var showNew = false
    @State private var showConfirm = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                OnboardingStepHeader(
                    title: L10n.passwordSetupTitle,
                    displayProgressStep: viewModel.uiProgressStep,
                    progressTotal: viewModel.progressTotalSteps,
                    onBack: { _ = viewModel.goBack(deps: deps) }
                )

                Text(L10n.passwordSetupSubtitle)
                    .font(FashTypography.bodyLarge)
                    .foregroundStyle(FashColors.textSecondary)

                passwordField(
                    L10n.passwordNewLabel,
                    text: Binding(
                        get: { viewModel.setupPassword },
                        set: { viewModel.onSetupPasswordChange($0) }
                    ),
                    visible: $showNew
                )
                passwordField(
                    L10n.passwordConfirmLabel,
                    text: Binding(
                        get: { viewModel.setupPasswordConfirm },
                        set: { viewModel.onSetupPasswordConfirmChange($0) }
                    ),
                    visible: $showConfirm
                )

                FashPrimaryButton(
                    title: L10n.passwordSetupContinue,
                    isLoading: viewModel.isSubmitting,
                    enabled: viewModel.canSubmitSetupPassword() && !viewModel.isSubmitting
                ) {
                    viewModel.submitSetupPassword(deps: deps, onSuccess: onStepComplete)
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
        .background(FashColors.screen)
    }

    private func passwordField(_ label: String, text: Binding<String>, visible: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(FashTypography.labelMedium)
                .foregroundStyle(FashColors.textSecondary)
            HStack {
                Group {
                    if visible.wrappedValue {
                        TextField(label, text: text)
                    } else {
                        SecureField(label, text: text)
                    }
                }
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                Button {
                    visible.wrappedValue.toggle()
                } label: {
                    Image(systemName: visible.wrappedValue ? "eye.slash" : "eye")
                        .foregroundStyle(FashColors.textSecondary)
                }
            }
            .padding(12)
            .background(FashColors.surfaceContainer)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
    }
}
