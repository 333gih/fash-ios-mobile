import SwiftUI

struct FashInAppNotificationBanner: View {
    let session: FashInAppNotificationSession
    var onDismiss: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(session.title).font(FashTypography.labelLarge)
                Text(session.body).font(FashTypography.bodyMedium).lineLimit(2)
            }
            Spacer()
            Button(action: onDismiss) { Image(systemName: "xmark") }
        }
        .padding(12)
        .background(FashColors.surfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }
}
