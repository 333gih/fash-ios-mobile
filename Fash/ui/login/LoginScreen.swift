import SwiftUI

struct LoginScreen: View {
    @Environment(AppDependencies.self) private var deps
    @Bindable var viewModel: LoginViewModel
    @Bindable private var localeController = AppLocaleController.shared
    @State private var loginHeroVM = LoginHeroSlidesViewModel()
    var onOtpSent: () -> Void
    var onGuestBrowse: () -> Void
    var onSocialLoginVerified: () -> Void

    private var isGoogleConfigured: Bool { LoginViewModel.isGoogleConfigured() }
    private var isInteractionBlocked: Bool { viewModel.isOtpLoading || viewModel.isSocialLoading }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    LoginLanguageToggle()
                }
                .padding(.horizontal, 24)
                .padding(.top, 12)

                ScrollView {
                    VStack(alignment: .center, spacing: 16) {
                        FashBrandMarkText(style: FashBrandTypography.markBoldItalicLarge)
                            .padding(.top, 8)
                        Text(L10n.loginTagline)
                            .font(FashTypography.bodyMedium)
                            .foregroundStyle(FashColors.textSecondary)
                            .multilineTextAlignment(.center)

                        LoginHeroCarousel(remoteSlides: loginHeroVM.remoteSlides)
                            .padding(.horizontal, 24)

                        VStack(alignment: .leading, spacing: 12) {
                            Text(L10n.loginEmailLabel)
                                .font(FashTypography.titleMedium)
                                .foregroundStyle(FashColors.textPrimary)
                            TextField(L10n.loginEmailPlaceholder, text: $viewModel.email)
                                .textContentType(.emailAddress)
                                .keyboardType(.emailAddress)
                                .autocapitalization(.none)
                                .font(FashTypography.bodyLarge)
                                .padding(16)
                                .background(FashColors.surfaceContainer)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            FashPrimaryButton(title: L10n.loginSendOtp, isLoading: viewModel.isOtpLoading) {
                                Task {
                                    if await viewModel.requestOtp() { onOtpSent() }
                                }
                            }
                            .disabled(isInteractionBlocked)

                            LoginOrDivider()
                                .padding(.top, 4)

                            LoginSocialOutlineButton(
                                icon: AnyView(GoogleBrandIcon()),
                                label: L10n.loginGoogle,
                                enabled: !isInteractionBlocked,
                                dimmed: !isGoogleConfigured,
                                action: handleGoogleTap
                            )

                            Button(L10n.loginContinueWithoutAccount, action: onGuestBrowse)
                                .font(FashTypography.bodyMedium)
                                .foregroundStyle(FashColors.textSecondary)
                                .frame(maxWidth: .infinity)
                                .disabled(isInteractionBlocked)
                        }
                        .padding(.horizontal, 24)
                        .padding(.bottom, 24)
                    }
                }
            }

            if viewModel.isSocialLoading {
                Color.black.opacity(0.38)
                    .ignoresSafeArea()
                ProgressView()
                    .tint(.white)
            }
        }
        .background(FashColors.screen)
        .task { await loginHeroVM.refresh() }
        .onChange(of: localeController.revision) { _, _ in
            Task { await loginHeroVM.refresh() }
        }
        .onChange(of: viewModel.errorMessage) { _, message in
            guard let message, !message.isEmpty else { return }
            deps.uiDialog.showError(message)
            viewModel.errorMessage = nil
        }
    }

    private func handleGoogleTap() {
        guard isGoogleConfigured else {
            viewModel.warnGoogleNotConfigured()
            return
        }
        Task {
            if await viewModel.performGoogleSignIn(sessionStore: deps.authSessionStore) {
                onSocialLoginVerified()
            }
        }
    }
}
