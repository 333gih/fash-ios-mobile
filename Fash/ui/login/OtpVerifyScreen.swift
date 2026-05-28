import SwiftUI

struct OtpVerifyScreen: View {
    @Environment(\.fashSpacing) private var spacing
    @Bindable var viewModel: LoginViewModel
    var onVerified: () -> Void
    var onBack: () -> Void

    private let otpLength = 6
    @State private var showHelpCard = false

    private var maskedEmail: String {
        LoginEmailValidation.maskForDisplay(viewModel.email)
    }

    private var otpComplete: Bool { viewModel.otp.count == otpLength }
    private var canResend: Bool { viewModel.resendCooldownSec <= 0 && !viewModel.isOtpLoading }

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Button(action: onBack) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundStyle(FashColors.textPrimary)
                            .frame(width: 44, height: 44)
                    }
                    .padding(.leading, -8)

                    FashBrandMarkText(
                        style: FashBrandTypography.markBoldItalic,
                        textAlign: .leading
                    )
                        .padding(.top, 8)

                    Text(L10n.otpTitle)
                        .font(FashTypography.headlineSmall.weight(.bold))
                        .foregroundStyle(FashColors.textPrimary)
                        .padding(.top, 20)

                    Text(L10n.otpSubtitle(maskedEmail, otpLength))
                        .font(FashTypography.bodyLarge)
                        .foregroundStyle(FashColors.textSecondary)
                        .padding(.top, 10)

                    OtpSixCellsInput(otp: $viewModel.otp, length: otpLength)
                        .padding(.top, 28)

                    FashPrimaryButton(
                        title: L10n.otpVerify,
                        isLoading: viewModel.isVerifyLoading,
                        cornerRadius: 24,
                        height: 52,
                        enabled: otpComplete && !viewModel.isVerifyLoading && !viewModel.isOtpLoading
                    ) {
                        Task {
                            if await viewModel.verifyOtp(sessionStore: AppDependencies.shared.authSessionStore) {
                                onVerified()
                            }
                        }
                    }
                    .padding(.top, 28)

                    HStack {
                        Spacer()
                        Button {
                            guard canResend else { return }
                            Task {
                                if await viewModel.requestOtp() {
                                    viewModel.otp = ""
                                }
                            }
                        } label: {
                            Group {
                                if viewModel.isOtpLoading {
                                    HStack(spacing: 8) {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                            .tint(FashColors.brandPrimary)
                                        Text(L10n.otpResendSending)
                                    }
                                } else if viewModel.resendCooldownSec > 0 {
                                    Text(L10n.otpResendWait(viewModel.resendCooldownSec))
                                } else {
                                    Text(L10n.otpResend)
                                }
                            }
                            .font(FashTypography.labelLarge)
                            .foregroundStyle(canResend ? FashColors.brandPrimary : FashColors.textSecondary.opacity(0.6))
                        }
                        .disabled(!canResend)
                        Spacer()
                    }
                    .padding(.top, 24)
                }
                .padding(.horizontal, spacing.editorialStart)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }

            if showHelpCard {
                OtpHelpBottomCard()
                    .padding(.horizontal, spacing.editorialStart)
                    .padding(.bottom, 32)
                    .transition(
                        .opacity.combined(with: .offset(y: 24))
                    )
            }
        }
        .background(FashColors.screen)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.14) {
                withAnimation(.easeOut(duration: 0.38)) {
                    showHelpCard = true
                }
            }
        }
        .alert(L10n.dialogTitleError, isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button(L10n.dialogOk) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }
}

private struct OtpHelpBottomCard: View {
    @Environment(\.fashSpacing) private var spacing

    private let tips = [L10n.otpHelpLine1, L10n.otpHelpLine2, L10n.otpHelpLine3]

    var body: some View {
        HStack(alignment: .top, spacing: spacing.spacing3) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(FashColors.brandPrimary.opacity(0.58))
                .frame(width: 3, height: 68)
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(FashColors.brandPrimary)
                    Text(L10n.otpHelpTitle)
                        .font(FashTypography.titleSmall.weight(.semibold))
                        .foregroundStyle(FashColors.textPrimary)
                }
                ForEach(tips, id: \.self) { line in
                    HStack(alignment: .top, spacing: 8) {
                        Text("•")
                            .font(FashTypography.bodySmall)
                            .foregroundStyle(FashColors.brandPrimary.opacity(0.72))
                            .padding(.top, 2)
                        Text(line)
                            .font(FashTypography.bodySmall)
                            .foregroundStyle(FashColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            }
        }
        .padding(spacing.spacing4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FashColors.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: spacing.radiusCard, style: .continuous))
    }
}
