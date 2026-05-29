import SwiftUI

/// Reports home feed tab row position — Android `showStickyTabs` when tab row scrolls off screen.
private struct HomeFeedTabsFrameKey: PreferenceKey {
    static var defaultValue: CGRect = .zero

    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}

extension View {
    func homeFeedTabsScrollReporting() -> some View {
        background {
            GeometryReader { geo in
                Color.clear.preference(
                    key: HomeFeedTabsFrameKey.self,
                    value: geo.frame(in: .named("homeFeedScroll"))
                )
            }
        }
    }
}

enum HomeFeedTabsScrollPolicy {
    /// Tabs row has scrolled above the visible top (show overlay switcher).
    static func shouldShowStickyTabs(tabsFrame: CGRect) -> Bool {
        tabsFrame.height > 1 && tabsFrame.maxY < 8
    }
}

struct HomeFeedTabsScrollObserver: View {
    @Binding var showStickyTabs: Bool

    var body: some View {
        Color.clear
            .frame(height: 0)
            .onPreferenceChange(HomeFeedTabsFrameKey.self) { frame in
                let next = HomeFeedTabsScrollPolicy.shouldShowStickyTabs(tabsFrame: frame)
                guard next != showStickyTabs else { return }
                showStickyTabs = next
            }
    }
}
