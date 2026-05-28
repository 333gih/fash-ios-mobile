import SwiftUI

enum OrderDetailComponents {
    static func statusBadge(_ status: String) -> some View {
        Text(OrderFormatting.statusLabel(status))
            .font(FashTypography.labelSmall.weight(.semibold))
            .foregroundStyle(FashColors.brandPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(FashColors.brandPrimary.opacity(0.12))
            .clipShape(Capsule())
    }

    static func sectionCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            content()
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FashColors.surfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    }

    static func infoRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(FashTypography.bodySmall)
                .foregroundStyle(FashColors.textSecondary)
            Spacer(minLength: 12)
            Text(value)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textPrimary)
                .multilineTextAlignment(.trailing)
        }
    }
}
