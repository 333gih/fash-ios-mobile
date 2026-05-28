import SwiftUI

/// Six OTP digit cells — Android `OtpSixCells`.
struct OtpSixCellsInput: View {
    @Binding var otp: String
    var length: Int = 6
    @FocusState private var focused: Bool

    private var activeIndex: Int {
        if otp.count >= length { return length - 1 }
        return otp.count
    }

    var body: some View {
        ZStack(alignment: .top) {
            HStack(spacing: 8) {
                ForEach(0..<length, id: \.self) { index in
                    let char = digit(at: index)
                    let isActive = index == activeIndex
                    Text(char)
                        .font(FashTypography.headlineSmall.weight(.semibold))
                        .kerning(1)
                        .foregroundStyle(FashColors.textPrimary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(FashColors.surfaceContainerLow)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(
                                    isActive ? FashColors.brandPrimary.opacity(0.85) : FashColors.outlineMuted.opacity(0.52),
                                    lineWidth: isActive ? 2 : 1
                                )
                        )
                }
            }

            TextField("", text: $otp)
                .keyboardType(.numberPad)
                .textContentType(.oneTimeCode)
                .focused($focused)
                .opacity(0.01)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .onChange(of: otp) { _, new in
                    let digits = new.filter(\.isNumber).prefix(length)
                    let normalized = String(digits)
                    if normalized != new { otp = normalized }
                }
        }
        .contentShape(Rectangle())
        .onTapGesture { focused = true }
        .onAppear { focused = true }
    }

    private func digit(at index: Int) -> String {
        guard index < otp.count else { return "" }
        let i = otp.index(otp.startIndex, offsetBy: index)
        return String(otp[i])
    }
}
