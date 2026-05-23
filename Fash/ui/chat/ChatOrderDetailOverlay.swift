import SwiftUI

/// SwiftUI port of Android `ChatOrderDetailOverlay` (ui.chat).
struct ChatOrderDetailOverlay: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ChatOrderDetailOverlayBody()
    }
}

private struct ChatOrderDetailOverlayBody: View {
    var body: some View {
        FashScreenScaffold(title: "ChatOrderDetailOverlay") {
            Text(L10n.appName)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
        }
    }
}

#Preview {
    FashTheme { ChatOrderDetailOverlay() }
}
