import SwiftUI

/// Tappable “See all” with ≥44pt hit target — Android `Modifier.clickable` on header actions.
struct FashSeeAllButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(L10n.exploreSeeAll)
                .font(FashTypography.labelMedium)
                .foregroundStyle(FashColors.brandPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.exploreSeeAllCd)
    }
}
