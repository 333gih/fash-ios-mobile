import SwiftUI
import UIKit

enum HomeScrollIds {
    static let top = "home_feed_scroll_top"
    static let pinnedTabs = "home_feed_pinned_tabs"
    static let feedContent = "home_feed_content"
}

struct HomeFeedScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// In-scroll tab row minY — when < 0 the row scrolled off; show Android-style sticky overlay.
struct HomeTabRowMinYKey: PreferenceKey {
    static var defaultValue: CGFloat = .infinity

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = min(value, nextValue())
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

    func homeTabRowScrollReporting(space: String = "homeFeedScroll") -> some View {
        background {
            GeometryReader { geo in
                Color.clear.preference(
                    key: HomeTabRowMinYKey.self,
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
    /// SwiftUI fallback — primary scroll-to-top is UIKit via [HomeFeedScrollCoordinator].
    @MainActor
    static func scrollToTop(proxy: ScrollViewProxy) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            proxy.scrollTo(HomeScrollIds.top, anchor: .top)
        }
    }
}

/// UIKit scroll-to-top only — no preserve/trim hooks that fight upward scrolling.
struct HomeFeedScrollCoordinator: UIViewRepresentable {
    var scrollToTopToken: Int

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> AnchorView {
        let view = AnchorView()
        view.coordinator = context.coordinator
        return view
    }

    func updateUIView(_ uiView: AnchorView, context: Context) {
        let coordinator = context.coordinator
        uiView.coordinator = coordinator
        coordinator.installIfNeeded(from: uiView)

        guard scrollToTopToken > 0, scrollToTopToken != coordinator.lastScrollToTopToken else { return }
        coordinator.lastScrollToTopToken = scrollToTopToken
        coordinator.scrollToTopGeneration += 1
        uiView.runScrollToTop(generation: coordinator.scrollToTopGeneration)
    }

    final class Coordinator {
        var lastScrollToTopToken = 0
        var scrollToTopGeneration = 0
        weak var scrollView: UIScrollView?

        func installIfNeeded(from anchor: UIView) {
            guard scrollView == nil, let scrollView = anchor.enclosingScrollView() else { return }
            self.scrollView = scrollView
        }
    }

    final class AnchorView: UIView {
        weak var coordinator: Coordinator?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard window != nil else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self, let coordinator else { return }
                coordinator.installIfNeeded(from: self)
            }
        }

        func runScrollToTop(generation: Int) {
            for attempt in 0..<14 {
                let delay = Double(attempt) * 0.055
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    guard let self, coordinator?.scrollToTopGeneration == generation else { return }
                    applyScrollToTop()
                }
            }
        }

        private func applyScrollToTop() {
            guard let scrollView = coordinator?.scrollView ?? enclosingScrollView() else { return }
            scrollView.layoutIfNeeded()
            resetPullRefreshInset(on: scrollView)
            let top = -scrollView.adjustedContentInset.top
            if abs(scrollView.contentOffset.y - top) > 0.5 {
                scrollView.setContentOffset(CGPoint(x: 0, y: top), animated: false)
            }
        }

        private func resetPullRefreshInset(on scrollView: UIScrollView) {
            guard scrollView.contentInset.top > 0.5 else { return }
            scrollView.contentInset.top = 0
            var inset = scrollView.verticalScrollIndicatorInsets
            inset.top = 0
            scrollView.verticalScrollIndicatorInsets = inset
        }
    }
}

private extension UIView {
    func enclosingScrollView() -> UIScrollView? {
        var candidate: UIView? = superview
        while let view = candidate {
            if let scrollView = view as? UIScrollView { return scrollView }
            candidate = view.superview
        }
        return nil
    }
}
