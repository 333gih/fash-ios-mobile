import SwiftUI

struct CreateListingModeStep: View {
    @Environment(\.fashSpacing) private var spacing
    let onManual: () -> Void
    let onFromProfile: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: spacing.spacing4) {
            Text(L10n.postFillModeTitle)
                .font(FashTypography.titleMedium)
                .foregroundStyle(FashColors.textPrimary)
            Text(L10n.postFillModeSubtitle)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
            FashPrimaryButton(title: L10n.postFillModeManualTitle) { onManual() }
            Button(action: onFromProfile) {
                Text(L10n.postFillModeFromProfileTitle)
                    .font(FashTypography.labelLarge)
                    .foregroundStyle(FashColors.brandPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
            .buttonStyle(.plain)
        }
        .padding(spacing.spacing4)
    }
}
