import SwiftUI

struct ChangePasswordScreen: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps
    @Bindable var viewModel: ChangePasswordViewModel
    var onDismiss: () -> Void = {}

    @State private var showCurrent = false
    @State private var showNew = false
    @State private var showConfirm = false

    var body: some View {
        OverlayScreenHost(title: L10n.changePasswordTitle, onDismiss: onDismiss) {
            ScrollView {
                VStack(alignment: .leading, spacing: spacing.spacing4) {
                    Text(L10n.changePasswordSubtitle)
                        .font(FashTypography.bodyMedium)
                        .foregroundStyle(FashColors.textSecondary)
                    passwordField(
                        L10n.passwordCurrentLabel,
                        text: Binding(
                            get: { viewModel.currentPassword },
                            set: { viewModel.onCurrentPasswordChange($0) }
                        ),
                        visible: $showCurrent
                    )
                    passwordField(
                        L10n.passwordNewLabel,
                        text: Binding(
                            get: { viewModel.newPassword },
                            set: { viewModel.onNewPasswordChange($0) }
                        ),
                        visible: $showNew
                    )
                    passwordField(
                        L10n.passwordConfirmLabel,
                        text: Binding(
                            get: { viewModel.confirmPassword },
                            set: { viewModel.onConfirmPasswordChange($0) }
                        ),
                        visible: $showConfirm
                    )
                    if viewModel.newPassword != viewModel.confirmPassword, !viewModel.confirmPassword.isEmpty {
                        Text(L10n.passwordMismatch)
                            .font(FashTypography.bodySmall)
                            .foregroundStyle(FashColors.error)
                    }
                    if let msg = viewModel.eventMessage {
                        Text(msg)
                            .font(FashTypography.bodySmall)
                            .foregroundStyle(FashColors.brandPrimary)
                    }
                    FashPrimaryButton(
                        title: L10n.changePasswordSave,
                        isLoading: viewModel.isSubmitting
                    ) {
                        Task { await viewModel.submit(deps: deps) }
                    }
                    .disabled(!viewModel.canSubmit() || viewModel.isSubmitting)
                    .opacity(viewModel.canSubmit() ? 1 : 0.5)
                }
                .padding(spacing.spacing4)
            }
        }
    }

    private func passwordField(_ label: String, text: Binding<String>, visible: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
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
                .textFieldStyle(.roundedBorder)
                Button {
                    visible.wrappedValue.toggle()
                } label: {
                    Image(systemName: visible.wrappedValue ? "eye.slash" : "eye")
                        .foregroundStyle(FashColors.textSecondary)
                }
            }
        }
    }
}
