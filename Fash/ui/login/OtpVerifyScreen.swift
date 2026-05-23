import SwiftUI

struct OtpVerifyScreen: View {
    @Environment(AppDependencies.self) private var deps
    @Bindable var viewModel: LoginViewModel
    var onVerified: () -> Void
    var onBack: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Button(action: onBack) {
                Image(systemName: "chevron.left")
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Text(L10n.loginOtpSent)
                .font(FashTypography.headlineMedium)
            TextField("OTP", text: $viewModel.otp)
                .keyboardType(.numberPad)
                .padding()
                .background(FashColors.surfaceContainer)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            FashPrimaryButton(title: L10n.dialogOk, isLoading: viewModel.isOtpLoading) {
                Task {
                    if await viewModel.verifyOtp(sessionStore: deps.authSessionStore) {
                        onVerified()
                    }
                }
            }
            Spacer()
        }
        .padding(24)
        .background(FashColors.screen)
    }
}
