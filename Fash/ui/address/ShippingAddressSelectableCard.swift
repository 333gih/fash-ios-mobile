import SwiftUI

struct ShippingAddressSelectableCard: View {
    @Environment(\.fashSpacing) private var spacing
    let address: ShippingAddress
    let isSelected: Bool
    var onSelect: () -> Void
    var onSetDefault: (() -> Void)?

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: spacing.spacing3) {
                Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
                    .foregroundStyle(isSelected ? FashColors.brandPrimary : FashColors.textSecondary)
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(address.recipientName.isEmpty ? address.label : address.recipientName)
                            .font(FashTypography.labelLarge)
                            .foregroundStyle(FashColors.textPrimary)
                        if address.isDefault {
                            Text(L10n.addressBadgeDefault)
                                .font(FashTypography.labelSmall)
                                .foregroundStyle(FashColors.brandPrimary)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(FashColors.surfaceContainerHigh)
                                .clipShape(Capsule())
                        }
                    }
                    if !address.phone.isEmpty {
                        Text(address.phone)
                            .font(FashTypography.bodySmall)
                            .foregroundStyle(FashColors.textSecondary)
                    }
                    Text(address.formattedSingleLine())
                        .font(FashTypography.bodyMedium)
                        .foregroundStyle(FashColors.textSecondary)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
            }
            .padding(spacing.spacing4)
            .background(isSelected ? FashColors.surfaceContainerHigh : FashColors.surfaceContainer)
            .clipShape(RoundedRectangle(cornerRadius: spacing.radiusSoftMin, style: .continuous))
        }
        .buttonStyle(.plain)
        .contextMenu {
            if let onSetDefault, !address.isDefault {
                Button(L10n.addressSetDefault, action: onSetDefault)
            }
        }
    }
}
