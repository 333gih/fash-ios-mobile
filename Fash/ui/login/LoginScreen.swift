import SwiftUI

struct LoginScreen: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps
    @Bindable var viewModel: LoginViewModel
    @Bindable private var localeController = AppLocaleController.shared
    @State private var loginHeroVM = LoginHeroSlidesViewModel()
    @State private var brandProgress: CGFloat = 0
    @State private var heroProgress: CGFloat = 0
    @State private var formProgress: CGFloat = 0
    @State private var bottomProgress: CGFloat = 0

    var onOtpSent: () -> Void
    var onGuestBrowse: () -> Void
    var onSocialLoginVerified: () -> Void
    var onPasswordLoginVerified: () -> Void

    private var isGoogleConfigured: Bool { LoginViewModel.isGoogleConfigured() }
    private var formLockedForSocial: Bool { viewModel.isSocialLoading }
    private var emailValid: Bool { LoginEmailValidation.isValid(viewModel.email) }
    private var passwordValid: Bool { !viewModel.password.isEmpty }

    private var primaryEnabled: Bool {
        if formLockedForSocial { return false }
        if viewModel.usePasswordLogin {
            return emailValid && passwordValid && !viewModel.isPasswordLoading
        }
        return emailValid && !viewModel.isOtpLoading
    }

    private var primaryLoading: Bool {
        viewModel.usePasswordLogin ? viewModel.isPasswordLoading : viewModel.isOtpLoading
    }

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    LoginLanguageToggle()
                }
                .padding(.horizontal, spacing.editorialStart)
                .padding(.top, 12)
                .padding(.bottom, 8)

                ScrollView {
                    VStack(spacing: 0) {
                        VStack(spacing: 6) {
                            FashBrandMarkText(style: FashBrandTypography.markBoldItalicLarge)
                            Text(L10n.loginTagline)
                                .font(FashTypography.bodyMedium)
                                .foregroundStyle(FashColors.textSecondary)
                                .multilineTextAlignment(.center)
                                .lineLimit(2)
                        }
                        .loginEntrance(progress: brandProgress, offsetY: 20)
                        .padding(.bottom, 10)

                        LoginHeroCarousel(remoteSlides: loginHeroVM.remoteSlides)
                            .frame(minHeight: 160, maxHeight: 280)
                            .loginEntrance(progress: heroProgress, offsetY: 24)
                            .padding(.bottom, 8)

                        VStack(spacing: 0) {
                            LoginEmailFieldWithRail(
                                email: $viewModel.email,
                                enabled: !formLockedForSocial,
                                onSubmit: submitPrimaryAction
                            )

                            if viewModel.usePasswordLogin {
                                LoginPasswordFieldWithRail(
                                    password: $viewModel.password,
                                    enabled: !formLockedForSocial,
                                    onSubmit: submitPrimaryAction
                                )
                                .padding(.top, 10)
                            }

                            Button {
                                viewModel.togglePasswordLogin()
                            } label: {
                                Text(viewModel.usePasswordLogin ? L10n.loginUseOtpInstead : L10n.loginWithPassword)
                                    .font(FashTypography.bodySmall)
                                    .foregroundStyle(FashColors.brandPrimary)
                                    .underline()
                            }
                            .buttonStyle(.plain)
                            .disabled(formLockedForSocial)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 4)
                            .padding(.vertical, 4)

                            FashPrimaryButton(
                                title: viewModel.usePasswordLogin ? L10n.loginSubmit : L10n.loginSendOtp,
                                isLoading: primaryLoading,
                                showsArrow: !viewModel.usePasswordLogin,
                                cornerRadius: 24,
                                height: 48,
                                enabled: primaryEnabled,
                                action: submitPrimaryAction
                            )
                            .padding(.top, 10)
                        }
                        .loginEntrance(progress: formProgress, offsetY: 22)

                        VStack(spacing: 0) {
                            LoginOrDivider()
                                .padding(.top, 12)

                            LoginSocialOutlineButton(
                                icon: AnyView(GoogleBrandIcon()),
                                label: L10n.loginGoogle,
                                enabled: !formLockedForSocial,
                                dimmed: !isGoogleConfigured,
                                action: handleGoogleTap
                            )
                            .padding(.top, 10)

                            LoginSocialOutlineButton(
                                icon: AnyView(AppleBrandIcon()),
                                label: L10n.loginApple,
                                enabled: !formLockedForSocial,
                                action: handleAppleTap
                            )
                            .padding(.top, 8)

                            Button(action: onGuestBrowse) {
                                Text(L10n.loginContinueWithoutAccount)
                                    .font(FashTypography.labelLarge)
                                    .foregroundStyle(FashColors.brandPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                            }
                            .buttonStyle(.plain)
                            .disabled(formLockedForSocial || viewModel.isOtpLoading)
                            .padding(.top, 4)

                            LoginLegalFooter()
                                .padding(.top, 8)
                        }
                        .loginEntrance(progress: bottomProgress, offsetY: 18)
                        .padding(.bottom, 24)
                    }
                    .padding(.horizontal, spacing.editorialStart)
                }
            }

            if viewModel.isSocialLoading {
                Color.black.opacity(0.38)
                    .ignoresSafeArea()
                VStack(spacing: 14) {
                    ProgressView()
                        .scaleEffect(1.4)
                        .tint(FashColors.brandPrimary)
                    Text(L10n.loginSocialSigningIn)
                        .font(FashTypography.titleMedium)
                        .foregroundStyle(Color.white.opacity(0.92))
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 28)
            }
        }
        .background(FashColors.screen)
        .task { await loginHeroVM.refresh() }
        .onAppear { runEntranceAnimations() }
        .onChange(of: localeController.revision) { _, _ in
            Task { await loginHeroVM.refresh() }
        }
        .onChange(of: viewModel.errorMessage) { _, message in
            guard let message, !message.isEmpty else { return }
            deps.uiDialog.showError(message)
            viewModel.errorMessage = nil
        }
    }

    private func runEntranceAnimations() {
        withAnimation(.easeOut(duration: 0.45)) { brandProgress = 1 }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            withAnimation(.easeOut(duration: 0.45)) { heroProgress = 1 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.10) {
            withAnimation(.easeOut(duration: 0.45)) { formProgress = 1 }
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            withAnimation(.easeOut(duration: 0.45)) { bottomProgress = 1 }
        }
    }

    private func submitPrimaryAction() {
        guard primaryEnabled else { return }
        Task {
            if viewModel.usePasswordLogin {
                if await viewModel.loginWithPassword(sessionStore: deps.authSessionStore) {
                    onPasswordLoginVerified()
                }
            } else if await viewModel.requestOtp() {
                onOtpSent()
            }
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

    private func handleAppleTap() {
        Task {
            if await viewModel.performAppleSignIn(sessionStore: deps.authSessionStore) {
                onSocialLoginVerified()
            }
        }
    }
}
