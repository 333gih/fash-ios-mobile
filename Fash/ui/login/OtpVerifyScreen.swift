import SwiftUI

struct OtpVerifyScreen: View {
    @Environment(\.fashSpacing) private var spacing
    @Bindable var viewModel: LoginViewModel
    var onVerified: () -> Void
    var onBack: () -> Void

    private let otpLength = 6

    private var maskedEmail: String {
        let email = viewModel.email.trimmingCharacters(in: .whitespaces)
        guard let at = email.firstIndex(of: "@"), at != email.startIndex else { return email }
        let local = String(email[..<at])
        let domain = String(email[at...])
        if local.count <= 2 { return "\(local.prefix(1))***\(domain)" }
        return "\(local.prefix(1))***\(local.suffix(1))\(domain)"
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

                    FashBrandMarkText(style: FashBrandTypography.markBoldItalic)
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
                        isLoading: viewModel.isOtpLoading
                    ) {
                        Task {
                            if await viewModel.verifyOtp(sessionStore: AppDependencies.shared.authSessionStore) {
                                onVerified()
                            }
                        }
                    }
                    .disabled(!otpComplete || viewModel.isOtpLoading)
                    .padding(.top, 28)

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
                                ProgressView().scaleEffect(0.9)
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
                    .frame(maxWidth: .infinity)
                    .padding(.top, 24)
                }
                .padding(.horizontal, spacing.editorialStart)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }

            otpHelpCard
                .padding(.horizontal, spacing.editorialStart)
                .padding(.bottom, 32)
        }
        .background(FashColors.screen)
        .alert(L10n.dialogTitleError, isPresented: Binding(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button(L10n.dialogOk) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
    }

    private var otpHelpCard: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "info.circle")
                .foregroundStyle(FashColors.brandPrimary)
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.otpHelpTitle)
                    .font(FashTypography.labelLarge.weight(.semibold))
                    .foregroundStyle(FashColors.textPrimary)
                Text("\(L10n.otpHelpLine1)\n\(L10n.otpHelpLine2)\n\(L10n.otpHelpLine3)")
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
            }
            Spacer(minLength: 0)
        }
        .padding(16)
        .background(FashColors.surfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }
}
