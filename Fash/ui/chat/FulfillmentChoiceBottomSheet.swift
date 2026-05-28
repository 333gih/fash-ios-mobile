import SwiftUI

/// Buyer fulfillment chooser — Android `FulfillmentChoiceBottomSheet`.
struct FulfillmentChoiceBottomSheet: View {
    @Environment(\.dismiss) private var dismiss
    let shipFulfillmentEnabled: Bool
    let orderCancellable: Bool
    let onChooseMeetup: () -> Void
    let onChooseShip: () -> Void
    var onCancelOrder: (() -> Void)?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text(L10n.chatFulfillmentSheetSubtitle)
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(FashColors.textSecondary)
                    optionRow(
                        systemImage: "calendar",
                        title: L10n.chatFulfillmentOptionMeetupTitle,
                        subtitle: L10n.chatFulfillmentOptionMeetupSubtitle
                    ) {
                        dismiss()
                        onChooseMeetup()
                    }
                    Divider()
                    optionRow(
                        systemImage: "shippingbox",
                        title: L10n.chatFulfillmentOptionShipTitle,
                        subtitle: shipFulfillmentEnabled
                            ? L10n.chatFulfillmentOptionShipSubtitle
                            : L10n.chatFulfillmentOptionShipComingSoon,
                        enabled: shipFulfillmentEnabled
                    ) {
                        guard shipFulfillmentEnabled else { return }
                        dismiss()
                        onChooseShip()
                    }
                    if orderCancellable, let onCancelOrder {
                        Divider()
                        optionRow(
                            systemImage: "xmark.circle",
                            title: L10n.chatFulfillmentCancelOrderTitle,
                            subtitle: L10n.chatFulfillmentCancelOrderSubtitle,
                            tint: FashColors.error
                        ) {
                            dismiss()
                            onCancelOrder()
                        }
                    }
                }
                .padding(20)
            }
            .navigationTitle(L10n.chatFulfillmentSheetTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.chatMeetingPickerCancel) { dismiss() }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func optionRow(
        systemImage: String,
        title: String,
        subtitle: String,
        enabled: Bool = true,
        tint: Color = FashColors.brandPrimary,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: systemImage)
                    .font(.system(size: 20))
                    .foregroundStyle(tint)
                    .frame(width: 28)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(FashTypography.titleSmall.weight(.semibold))
                        .foregroundStyle(FashColors.textPrimary)
                    Text(subtitle)
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(FashColors.textSecondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(FashColors.textSecondary)
            }
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .opacity(enabled ? 1 : 0.5)
    }
}
