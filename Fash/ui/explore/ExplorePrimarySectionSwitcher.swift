import SwiftUI

/// Listings / Sellers segmented control — Android [ExplorePrimarySectionSwitcher].
struct ExplorePrimarySectionSwitcher: View {
    @Environment(\.fashSpacing) private var spacing
    let selected: ExplorePrimarySection
    let onSelect: (ExplorePrimarySection) -> Void

    var body: some View {
        HStack(spacing: 4) {
            segment(L10n.exploreSectionListings, .listings)
            segment(L10n.exploreSectionSellers, .sellers)
        }
        .padding(4)
        .background(FashColors.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: spacing.radiusPill, style: .continuous))
    }

    private func segment(_ title: String, _ section: ExplorePrimarySection) -> some View {
        let isSelected = selected == section
        return Button {
            onSelect(section)
        } label: {
            Text(title)
                .font(FashTypography.labelLarge.weight(.semibold))
                .foregroundStyle(isSelected ? FashColors.onBrandPrimary : FashColors.textPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 10)
                .padding(.horizontal, 12)
                .background(isSelected ? FashColors.brandPrimary : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: spacing.radiusPill, style: .continuous))
        }
        .buttonStyle(.plain)
    }
}
