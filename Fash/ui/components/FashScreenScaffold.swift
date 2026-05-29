import SwiftUI

struct FashScreenScaffold<Content: View>: View {
    @Environment(\.fashSpacing) private var spacing
    let title: String
    var showBack = false
    var onBack: (() -> Void)?
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: spacing.spacing2) {
                if showBack {
                    FashBackButton(action: { onBack?() })
                }
                Text(title)
                    .font(FashTypography.titleLarge)
                    .fontWeight(.bold)
                    .foregroundStyle(FashColors.textPrimary)
                Spacer(minLength: 0)
            }
            .padding(.leading, showBack ? FashBackButton.leadingScreenInset : spacing.editorialStart)
            .padding(.trailing, spacing.editorialEnd)
            .padding(.vertical, spacing.spacing3)
            .background(FashColors.surface)
            Divider().overlay(FashColors.outlineMuted.opacity(0.72))
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(FashColors.screen)
    }
}
