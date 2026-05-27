import SwiftUI

/// Depop-style shortcuts: discover inventory, list an item, check orders.
struct HomeQuickActionsRow: View {
    @Environment(\.fashSpacing) private var spacing
    var onExplore: () -> Void
    var onSell: () -> Void
    var onOrders: () -> Void
    var compact: Bool = false

    var body: some View {
        if compact {
            compactRow
        } else {
            fullRow
        }
    }

    private var fullRow: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(L10n.homeQuickActionsTitle)
                .font(FashTypography.titleSmall.weight(.semibold))
                .foregroundStyle(FashColors.textPrimary)
            HStack(spacing: 10) {
                quickActionCell(label: L10n.homeQuickExplore, icon: "safari.fill", action: onExplore)
                quickActionCell(label: L10n.homeQuickSell, icon: "plus", action: onSell)
                quickActionCell(label: L10n.homeQuickOrders, icon: "bag.fill", action: onOrders)
            }
        }
        .padding(.leading, spacing.editorialStart)
        .padding(.trailing, spacing.editorialEnd)
        .padding(.top, 4)
        .padding(.bottom, 8)
    }

    private var compactRow: some View {
        HStack(spacing: 8) {
            quickActionChip(label: L10n.homeQuickExplore, icon: "safari.fill", action: onExplore)
            quickActionChip(label: L10n.homeQuickSell, icon: "plus", action: onSell)
            quickActionChip(label: L10n.homeQuickOrders, icon: "bag.fill", action: onOrders)
        }
        .padding(.leading, spacing.editorialStart)
        .padding(.trailing, spacing.editorialEnd)
        .padding(.top, 2)
        .padding(.bottom, 6)
    }

    private func quickActionCell(label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 26))
                    .foregroundStyle(FashColors.brandPrimary)
                Text(label)
                    .font(FashTypography.labelMedium.weight(.semibold))
                    .foregroundStyle(FashColors.textPrimary)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .padding(.horizontal, 8)
            .background(FashColors.surfaceVariant)
            .clipShape(RoundedRectangle(cornerRadius: spacing.radiusSoftMin, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private func quickActionChip(label: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(FashColors.brandPrimary)
                Text(label)
                    .font(FashTypography.labelMedium.weight(.semibold))
                    .foregroundStyle(FashColors.textPrimary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(FashColors.surfaceContainerHigh)
            .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }
}
