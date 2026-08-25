import SwiftUI

struct MaintenanceWarningBanner: View {
    let remainingSeconds: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(L10n.maintenanceWarningTitle)
                .font(.subheadline.weight(.semibold))
            Text(L10n.maintenanceWarningCountdown(remainingSeconds))
                .font(.caption)
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .safeAreaPadding(.top)
        .background(FashColors.brandPrimary)
    }
}
