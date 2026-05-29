import SwiftUI

enum FashPinnedTabScroll {
    /// Scrolls to feed/grid content with pinned tab chrome at the top — Android `scrollProfileToPinnedGrid`.
    static func scrollToPinnedContent<ID: Hashable>(
        proxy: ScrollViewProxy,
        id: ID,
        anchor: UnitPoint = .top,
        animated: Bool = true,
        initialDelayMs: Int = 80
    ) {
        Task { @MainActor in
            if initialDelayMs > 0 {
                try? await Task.sleep(for: .milliseconds(initialDelayMs))
            }
            if animated {
                withAnimation(.easeInOut(duration: 0.28)) {
                    proxy.scrollTo(id, anchor: anchor)
                }
            } else {
                proxy.scrollTo(id, anchor: anchor)
            }
        }
    }
}
