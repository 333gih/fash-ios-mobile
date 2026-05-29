import SwiftUI

struct FashInAppNotificationBanner: View {
    let session: FashInAppNotificationSession
    var onTap: () -> Void
    var onDismiss: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(session.title)
                        .font(FashTypography.labelLarge)
                        .foregroundStyle(FashColors.textPrimary)
                    Text(session.body)
                        .font(FashTypography.bodyMedium)
                        .foregroundStyle(FashColors.textSecondary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                }
                Spacer(minLength: 0)
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(FashColors.textSecondary)
                }
                .buttonStyle(.plain)
            }
            .padding(12)
            .background(FashColors.surfaceContainer)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .shadow(color: .black.opacity(0.08), radius: 8, y: 4)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .task {
            try? await Task.sleep(for: .milliseconds(4_500))
            onDismiss()
        }
    }
}

/// Top transient notification — visible on the active screen (incl. fullScreenCover).
struct FashInAppNotificationOverlayModifier: ViewModifier {
    @Environment(AppDependencies.self) private var deps

    func body(content: Content) -> some View {
        content
            .overlay(alignment: .top) {
                if let session = deps.inAppNotification,
                   !session.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    || !session.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    FashInAppNotificationBanner(
                        session: session,
                        onTap: {
                            guard let router = deps.navigationRouter else {
                                deps.dismissInAppNotification()
                                return
                            }
                            RealtimeNotificationRouter.handleInAppBannerTap(
                                session: session,
                                deps: deps,
                                router: router
                            )
                        },
                        onDismiss: { deps.dismissInAppNotification() }
                    )
                    .safeAreaPadding(.top, 0)
                    .zIndex(1)
                    .transition(.move(edge: .top).combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.22), value: deps.inAppNotification)
    }
}

extension View {
    func fashInAppNotificationOverlay() -> some View {
        modifier(FashInAppNotificationOverlayModifier())
    }
}
