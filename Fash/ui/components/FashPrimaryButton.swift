import SwiftUI

struct FashPrimaryButton: View {
    let title: String
    var isLoading = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView().tint(.white)
                }
                Text(title)
                    .font(FashTypography.labelLarge)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(FashColors.brandPrimary)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .disabled(isLoading)
    }
}
