import SwiftUI

/// SwiftUI port of Android `FulfillmentChoiceBottomSheet` (ui.chat).
struct FulfillmentChoiceBottomSheet: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        FulfillmentChoiceBottomSheetBody()
    }
}

private struct FulfillmentChoiceBottomSheetBody: View {
    var body: some View {
        FashScreenScaffold(title: "FulfillmentChoiceBottomSheet") {
            Text(L10n.appName)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
        }
    }
}

#Preview {
    FashTheme { FulfillmentChoiceBottomSheet() }
}
