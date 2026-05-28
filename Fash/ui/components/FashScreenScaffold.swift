import SwiftUI

struct FashScreenScaffold<Content: View>: View {
    @Environment(\.fashSpacing) private var spacing
    let title: String
    var showBack = false
    var onBack: (() -> Void)?
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: spacing.spacing3) {
                if showBack {
                    Button(action: { onBack?() }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundStyle(FashColors.brandPrimary)
                            .frame(width: 44, height: 44)
                            .contentShape(Rectangle())
                    }
                }
                Text(title)
                    .font(FashTypography.titleLarge)
                    .fontWeight(.bold)
                    .foregroundStyle(FashColors.textPrimary)
                Spacer()
            }
            .padding(.leading, spacing.editorialStart)
            .padding(.trailing, spacing.editorialEnd)
            .padding(.vertical, spacing.spacing3)
            .background(FashColors.surfaceContainerHighest)
            Divider().overlay(FashColors.outlineMuted.opacity(0.72))
            content()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(FashColors.screen)
    }
}
