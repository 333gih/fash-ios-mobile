import SwiftUI
import UIKit

enum HomeScrollIds {
    static let pinnedTabs = "home_feed_pinned_tabs"
    static let feedContent = "home_feed_content"
}

struct HomeHeaderHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        let next = nextValue()
        if next > 0 { value = next }
    }
}

extension View {
    func homeFeedHeaderHeightReporting() -> some View {
        background {
            GeometryReader { geo in
                Color.clear.preference(key: HomeHeaderHeightKey.self, value: geo.size.height)
            }
        }
    }

    func onHomeHeaderHeightChange(_ height: Binding<CGFloat>) -> some View {
        onPreferenceChange(HomeHeaderHeightKey.self) { newHeight in
            guard newHeight > 1, abs(newHeight - height.wrappedValue) > 0.5 else { return }
            height.wrappedValue = newHeight
        }
    }
}

enum HomeFeedScrollReset {
    @MainActor
    static func scrollToPinnedFeed(
        scrollPosition: Binding<String?>,
        proxy: ScrollViewProxy,
        resetToken: Binding<Int>
    ) {
        PinnedTabScrollReset.scrollToPinnedContent(
            scrollPosition: scrollPosition,
            proxy: proxy,
            resetToken: resetToken,
            contentId: HomeScrollIds.feedContent
        )
    }
}
