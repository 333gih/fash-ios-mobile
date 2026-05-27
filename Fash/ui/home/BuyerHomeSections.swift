import SwiftUI

struct HomeBrandFooterStrip: View {
    @Environment(\.fashSpacing) private var spacing
    var includeHorizontalEdgePadding: Bool = true

    var body: some View {
        let edgeStart = includeHorizontalEdgePadding ? spacing.editorialStart : 0
        let edgeEnd = includeHorizontalEdgePadding ? spacing.editorialEnd : 0
        VStack(spacing: 6) {
            Divider()
                .overlay(FashColors.outlineMuted.opacity(0.35))
                .padding(.bottom, 20)
            Text(L10n.homeBrandFooterSub)
                .font(FashBrandTypography.marketplaceSubtitle)
                .foregroundStyle(FashColors.textSecondary.opacity(0.85))
                .multilineTextAlignment(.center)
            FashBrandMarkText(
                text: L10n.homeBrandMarketplace,
                style: FashBrandTypography.markBoldItalicSmall,
                color: FashColors.textSecondary.opacity(0.85)
            )
        }
        .frame(maxWidth: .infinity)
        .padding(.leading, edgeStart)
        .padding(.trailing, edgeEnd)
        .padding(.top, 36)
        .padding(.bottom, 40)
    }
}
