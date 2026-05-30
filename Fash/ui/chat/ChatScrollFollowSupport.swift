import SwiftUI

private struct ChatScrollViewportHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

private struct ChatScrollBottomMaxYKey: PreferenceKey {
    static var defaultValue: CGFloat = .infinity
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = min(value, nextValue())
    }
}

/// Tracks whether the user is pinned to the newest messages (Android `firstVisibleItemIndex == 0`).
struct ChatScrollFollowTracker: ViewModifier {
    let threshold: CGFloat
    let onFollowingBottomChanged: (Bool) -> Void

    @State private var viewportHeight: CGFloat = 0
    @State private var bottomMaxY: CGFloat = .infinity

    func body(content: Content) -> some View {
        content
            .background {
                GeometryReader { geo in
                    Color.clear.preference(
                        key: ChatScrollViewportHeightKey.self,
                        value: geo.size.height
                    )
                }
            }
            .onPreferenceChange(ChatScrollViewportHeightKey.self) { viewportHeight = $0 }
            .onPreferenceChange(ChatScrollBottomMaxYKey.self) { bottomMaxY = $0 }
            .onChange(of: viewportHeight) { _, _ in emitFollowingBottom() }
            .onChange(of: bottomMaxY) { _, _ in emitFollowingBottom() }
    }

    private func emitFollowingBottom() {
        guard viewportHeight > 0 else { return }
        let following = bottomMaxY <= viewportHeight + threshold
        onFollowingBottomChanged(following)
    }
}

extension View {
    func chatScrollFollowTracking(
        threshold: CGFloat = 72,
        onFollowingBottomChanged: @escaping (Bool) -> Void
    ) -> some View {
        modifier(ChatScrollFollowTracker(threshold: threshold, onFollowingBottomChanged: onFollowingBottomChanged))
    }

    func chatScrollBottomAnchor() -> some View {
        background {
            GeometryReader { geo in
                Color.clear.preference(
                    key: ChatScrollBottomMaxYKey.self,
                    value: geo.frame(in: .named("chatScroll")).maxY
                )
            }
        }
        .frame(height: 1)
    }
}
