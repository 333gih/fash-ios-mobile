import SwiftUI

/// Six OTP digit cells — Android `OtpSixCells`.
struct OtpSixCellsInput: View {
    @Binding var otp: String
    var length: Int = 6
    @FocusState private var focused: Bool

    var body: some View {
        ZStack {
            TextField("", text: $otp)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($focused)
                .opacity(0.01)
                .frame(width: 1, height: 1)
                .onChange(of: otp) { _, new in
                    let digits = new.filter(\.isNumber).prefix(length)
                    let normalized = String(digits)
                    if normalized != new { otp = normalized }
                }

            HStack(spacing: 10) {
                ForEach(0..<length, id: \.self) { index in
                    let char = digit(at: index)
                    Text(char)
                        .font(FashTypography.titleLarge.weight(.bold))
                        .foregroundStyle(FashColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(FashColors.surfaceContainer)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(
                                    index == otp.count && focused ? FashColors.brandPrimary : FashColors.outlineMuted.opacity(0.5),
                                    lineWidth: index == otp.count && focused ? 2 : 1
                                )
                        )
                }
            }
            .contentShape(Rectangle())
            .onTapGesture { focused = true }
        }
        .onAppear { focused = true }
    }

    private func digit(at index: Int) -> String {
        guard index < otp.count else { return "" }
        let i = otp.index(otp.startIndex, offsetBy: index)
        return String(otp[i])
    }
}
