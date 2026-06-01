import SwiftUI

struct FashScreenScaffold<Content: View, Trailing: View>: View {
    @Environment(\.fashSpacing) private var spacing
    let title: String
    var showBack = false
    var onBack: (() -> Void)?
    @ViewBuilder var trailing: () -> Trailing
    @ViewBuilder let content: () -> Content

    init(
        title: String,
        showBack: Bool = false,
        onBack: (() -> Void)? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) where Trailing == EmptyView {
        self.title = title
        self.showBack = showBack
        self.onBack = onBack
        self.trailing = { EmptyView() }
        self.content = content
    }

    init(
        title: String,
        showBack: Bool = false,
        onBack: (() -> Void)? = nil,
        @ViewBuilder trailing: @escaping () -> Trailing,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.title = title
        self.showBack = showBack
        self.onBack = onBack
        self.trailing = trailing
        self.content = content
    }

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
                trailing()
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
