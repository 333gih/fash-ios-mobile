import SwiftUI

/// Rounded section surface for post steps — Android [PostStep1SectionCard] style.
struct PostStepSectionCard<Content: View>: View {
    @Environment(\.fashSpacing) private var spacing
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: spacing.spacing3) {
            content()
        }
        .padding(spacing.spacing4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(PostListingColors.fieldSurface)
        .clipShape(RoundedRectangle(cornerRadius: spacing.radiusCard, style: .continuous))
        .overlay {
            RoundedRectangle(cornerRadius: spacing.radiusCard, style: .continuous)
                .stroke(FashColors.outlineMuted.opacity(0.35), lineWidth: 1)
        }
    }
}

struct PostProfilePrefilledBanner: View {
    @Environment(\.fashSpacing) private var spacing

    var body: some View {
        Text(L10n.postFillModePrefilledHint)
            .font(FashTypography.bodySmall)
            .foregroundStyle(FashColors.textPrimary)
            .padding(.horizontal, spacing.spacing3)
            .padding(.vertical, spacing.spacing2)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(FashColors.brandPrimary.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}
