import SwiftUI

/// SwiftUI port of Android `ChatShipFulfillmentScreen` (ui.chat).
struct ChatShipFulfillmentScreen: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ChatShipFulfillmentScreenBody()
    }
}

private struct ChatShipFulfillmentScreenBody: View {
    var body: some View {
        FashScreenScaffold(title: "ChatShipFulfillmentScreen") {
            Text(L10n.appName)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
        }
    }
}

#Preview {
    FashTheme { ChatShipFulfillmentScreen() }
}
