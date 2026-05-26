import SwiftUI

struct LoginScreen: View {
    @Bindable var viewModel: LoginViewModel
    @Bindable private var localeController = AppLocaleController.shared
    @State private var loginHeroVM = LoginHeroSlidesViewModel()
    var onOtpSent: () -> Void
    var onGuestBrowse: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                LoginLanguageToggle()
            }
            .padding(.horizontal, 24)
            .padding(.top, 12)

            ScrollView {
                VStack(alignment: .center, spacing: 16) {
                    FashBrandMarkText()
                        .padding(.top, 8)
                    Text(L10n.loginTagline)
                        .font(FashTypography.bodyMedium)
                        .foregroundStyle(FashColors.textSecondary)
                        .multilineTextAlignment(.center)

                    LoginHeroCarousel(remoteSlides: loginHeroVM.remoteSlides)
                        .padding(.horizontal, 24)

                    VStack(alignment: .leading, spacing: 12) {
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
                            .frame(maxWidth: .infinity)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .background(FashColors.screen)
        .task { await loginHeroVM.refresh() }
        .onChange(of: localeController.revision) { _, _ in
            Task { await loginHeroVM.refresh() }
        }
    }
}
