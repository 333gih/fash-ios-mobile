import SwiftUI
import UIKit

enum HomeScrollIds {
    static let top = "home_feed_scroll_top"
    static let pinnedTabs = "home_feed_pinned_tabs"
    static let feedContent = "home_feed_content"
}

/// Feed scroll offset anchor — parity with Explore [ExploreFeedScrollOffsetAnchor].
struct HomeFeedScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

struct HomeFeedScrollOffsetAnchor: View {
    var body: some View {
        Color.clear
            .frame(height: 0)
            .id(HomeScrollIds.top)
            .homeFeedScrollOffsetReporting()
    }
}

extension View {
    func homeFeedScrollOffsetReporting(space: String = "homeFeedScroll") -> some View {
        background {
            GeometryReader { geo in
                Color.clear.preference(
                    key: HomeFeedScrollOffsetKey.self,
                    value: geo.frame(in: .named(space)).minY
                )
            }
            .allowsHitTesting(false)
        }
    }
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
        resetToken: Binding<Int>,
        clampRevision: Binding<Int>
    ) {
        clampRevision.wrappedValue += 1
        PinnedTabScrollReset.scrollToPinnedContent(
            scrollPosition: scrollPosition,
            proxy: proxy,
            resetToken: resetToken,
            contentId: HomeScrollIds.pinnedTabs
        )
    }

    @MainActor
    static func scrollToTop(
        scrollPosition: Binding<String?>,
        proxy: ScrollViewProxy,
        trueTopToken: Binding<Int>,
        clampRevision: Binding<Int>
    ) {
        clampRevision.wrappedValue += 1
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            scrollPosition.wrappedValue = HomeScrollIds.top
            proxy.scrollTo(HomeScrollIds.top, anchor: .top)
        }
        // Do not bump `resetToken` — PinnedTabScrollOffsetFixer `.pinnedReset` snaps to tab-pinned offset (~headerHeight), not y=0.
        trueTopToken.wrappedValue += 1

        Task { @MainActor in
            for delayMs in [60, 140, 260] {
                try? await Task.sleep(for: .milliseconds(delayMs))
                var followUp = Transaction()
                followUp.disablesAnimations = true
                withTransaction(followUp) {
                    scrollPosition.wrappedValue = HomeScrollIds.top
                    proxy.scrollTo(HomeScrollIds.top, anchor: .top)
                }
            }
        }
    }
}
