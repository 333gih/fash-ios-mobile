import SwiftUI

struct FashScreenScaffold<Content: View>: View {
    let title: String
    var showBack = false
    var onBack: (() -> Void)?
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                if showBack {
                    Button(action: { onBack?() }) {
                        Image(systemName: "chevron.left")
                            .foregroundStyle(FashColors.textPrimary)
                    }
                }
                Text(title)
                    .font(FashTypography.titleMedium)
                    .foregroundStyle(FashColors.textPrimary)
                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(FashColors.screen)
    }
}
