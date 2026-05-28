import SwiftUI

/// Port of Android `ProfilePreviewPlaceholders` (ui.components).
enum ProfilePreviewPlaceholders {
    struct EmptySlot: View {
        var cornerRadius: CGFloat = 8

        var body: some View {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .strokeBorder(FashColors.outlineMuted.opacity(0.42), lineWidth: 1)
                .background(
                    RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                        .fill(FashColors.surfaceContainerHigh.opacity(0.55))
                )
                .overlay {
                    VStack(spacing: 6) {
                        Image(systemName: "storefront")
                            .font(.system(size: 22))
                            .foregroundStyle(FashColors.outlineMuted.opacity(0.55))
                        Text(L10n.profilePreviewSlotEmptyLabel)
                            .font(FashTypography.labelSmall)
                            .foregroundStyle(FashColors.textSecondary.opacity(0.88))
                            .multilineTextAlignment(.center)
                            .lineLimit(2)
                            .padding(.horizontal, 6)
                    }
                }
                .accessibilityLabel(L10n.profilePreviewSlotEmptyCd)
        }
    }

    struct RowCaption: View {
        let previewCount: Int
        let totalListingCount: Int

        var body: some View {
            if previewCount <= 0 || previewCount >= 3 { EmptyView() }
            else {
                let total = max(totalListingCount, previewCount)
                if total <= 0 { EmptyView() }
                else {
                    Text(captionText(previewCount: previewCount, total: total))
                        .font(FashTypography.labelSmall)
                        .foregroundStyle(FashColors.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.bottom, 6)
                }
            }
        }

        private func captionText(previewCount: Int, total: Int) -> String {
            if previewCount >= total {
                return L10n.profilePreviewCaptionAll(previewCount)
            }
            return L10n.profilePreviewCaptionPartial(previewCount, total)
        }
    }
}
