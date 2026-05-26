import SwiftUI

struct LoginScreen: View {
    @Bindable var viewModel: LoginViewModel
    var onOtpSent: () -> Void
    var onGuestBrowse: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                FashBrandMarkText()
                    .padding(.top, 48)
                Text(L10n.loginEmailLabel)
                    .font(FashTypography.headlineMedium)
                    .foregroundStyle(FashColors.textPrimary)
                TextField(L10n.loginEmailPlaceholder, text: $viewModel.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                    .background(FashColors.surfaceContainer)
                    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                FashPrimaryButton(title: L10n.loginSendOtp, isLoading: viewModel.isOtpLoading) {
                    Task {
                        if await viewModel.requestOtp() { onOtpSent() }
                    }
                }
                Button(L10n.loginContinueWithoutAccount, action: onGuestBrowse)
                    .font(FashTypography.bodyMedium)
                    .foregroundStyle(FashColors.textSecondary)
                LoginLanguageToggle()
            }
            .padding(24)
        }
        .background(FashColors.screen)
    }
}
