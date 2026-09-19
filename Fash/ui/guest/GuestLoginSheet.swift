import SwiftUI

struct GuestLoginSheet: View {
    var reason: String?
    var onSignIn: () -> Void
    var onContinueBrowsing: () -> Void

    private var iconName: String {
        guard let r = reason?.lowercased() else { return "person.crop.circle" }
        if r.contains("theo dõi") || r.contains("follow") { return "person.badge.plus" }
        if r.contains("lưu") || r.contains("saved") || r.contains("bookmark") { return "bookmark" }
        if r.contains("thích") || r.contains("yêu thích") || r.contains("like") || r.contains("heart") { return "heart" }
        if r.contains("chat") || r.contains("nhắn") || r.contains("tin nhắn") { return "bubble.left.and.bubble.right" }
        if r.contains("đăng bán") || r.contains("bán") || r.contains("post listing") { return "tag" }
        if r.contains("đơn hàng") || r.contains("order") || r.contains("mua") { return "bag" }
        if r.contains("thông báo") || r.contains("notification") { return "bell" }
        if r.contains("vị trí") || r.contains("gần") || r.contains("location") { return "location" }
        if r.contains("size") || r.contains("kích cỡ") || r.contains("số đo") { return "ruler" }
        if r.contains("gu") || r.contains("gợi ý") || r.contains("riêng") || r.contains("style") { return "sparkles" }
        if r.contains("mời") || r.contains("invite") || r.contains("bạn bè") { return "person.2" }
        return "person.crop.circle"
    }

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            Image(systemName: iconName)
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(FashColors.brandPrimary)
                .padding(.bottom, 20)
            Text(L10n.guestLoginSheetTitle)
                .font(FashTypography.headlineMedium)
                .multilineTextAlignment(.center)
                .padding(.bottom, 12)
            if let reason, !reason.isEmpty {
                Text(reason)
                    .font(FashTypography.bodyMedium)
                    .foregroundStyle(FashColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 8)
            }
            Text(L10n.guestLoginSheetPrivacyNote)
                .font(FashTypography.bodySmall)
                .foregroundStyle(FashColors.textSecondary)
                .multilineTextAlignment(.center)
                .padding(.bottom, 24)
            FashPrimaryButton(title: L10n.guestLoginSheetSignIn, action: onSignIn)
                .padding(.bottom, 4)
            Button(L10n.guestLoginSheetContinueBrowsing, action: onContinueBrowsing)
                .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 24)
        .padding(.top, 32)
        .padding(.bottom, 24)
        .presentationDetents([.medium])
    }
}

/// Presents guest login above the current stack (e.g. PDP `fullScreenCover`) — RootView-level sheets sit underneath.
struct GuestLoginSheetModifier: ViewModifier {
    @Environment(AppDependencies.self) private var deps
    @Bindable var router: AppRouter
    @Binding var isPresented: Bool
    let reason: String?

    func body(content: Content) -> some View {
        content.sheet(isPresented: $isPresented) {
            GuestLoginSheet(
                reason: reason,
                onSignIn: {
                    isPresented = false
                    deps.isGuestBrowseActive = false
                    router.isGuestMode = false
                    router.loginStep = .email
                },
                onContinueBrowsing: { isPresented = false }
            )
        }
    }
}

extension View {
    func guestLoginSheet(
        isPresented: Binding<Bool>,
        reason: String?,
        router: AppRouter
    ) -> some View {
        modifier(GuestLoginSheetModifier(router: router, isPresented: isPresented, reason: reason))
    }
}
