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

/// Single UIKit owner for home scroll — scroll-to-top, load-more anchor preserve (never fights upward scroll).
struct HomeFeedScrollCoordinator: UIViewRepresentable {
    var scrollToTopToken: Int
    var itemsCount: Int
    var isLoadingMore: Bool

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

        var scrollToTopJustFired = false
        if scrollToTopToken > 0, scrollToTopToken != coordinator.lastScrollToTopToken {
            coordinator.lastScrollToTopToken = scrollToTopToken
            coordinator.cancelPreserveWork()
            coordinator.clearLoadAnchor()
            coordinator.scrollToTopGeneration += 1
            scrollToTopJustFired = true
            uiView.runScrollToTop(generation: coordinator.scrollToTopGeneration)
        }

        if isLoadingMore, !coordinator.wasLoadingMore {
            coordinator.cancelPreserveWork()
            coordinator.captureLoadAnchor()
        } else if !isLoadingMore, coordinator.wasLoadingMore {
            coordinator.cancelPreserveWork()
            coordinator.clearLoadAnchor()
        }

        let countIncreased = itemsCount > coordinator.lastItemsCount
        if countIncreased,
           !scrollToTopJustFired,
           coordinator.lastItemsCount > 0,
           coordinator.loadAnchorOffset != nil,
           isLoadingMore {
            let generation = coordinator.preserveGeneration
            uiView.preserveAfterAppend(
                generation: generation,
                anchorOffset: coordinator.loadAnchorOffset!,
                anchorHeight: coordinator.loadAnchorContentHeight
                    ?? coordinator.lastContentHeight
            )
        }

        coordinator.lastItemsCount = itemsCount
        coordinator.wasLoadingMore = isLoadingMore
    }

    final class Coordinator {
        var lastScrollToTopToken = 0
        var lastItemsCount = 0
        var wasLoadingMore = false
        var preserveGeneration = 0
        var scrollToTopGeneration = 0

        weak var scrollView: UIScrollView?
        var offsetObservation: NSKeyValueObservation?
        var sizeObservation: NSKeyValueObservation?
        var lastContentOffsetY: CGFloat = 0
        var lastContentHeight: CGFloat = 0
        var loadAnchorOffset: CGFloat?
        var loadAnchorContentHeight: CGFloat?

        func cancelPreserveWork() {
            preserveGeneration += 1
        }

        func captureLoadAnchor() {
            loadAnchorOffset = lastContentOffsetY
            loadAnchorContentHeight = lastContentHeight
        }

        func clearLoadAnchor() {
            loadAnchorOffset = nil
            loadAnchorContentHeight = nil
        }

        func installIfNeeded(from anchor: UIView) {
            guard let scrollView = anchor.enclosingScrollView() else { return }
            if self.scrollView === scrollView, offsetObservation != nil { return }
            offsetObservation?.invalidate()
            sizeObservation?.invalidate()
            self.scrollView = scrollView
            offsetObservation = scrollView.observe(\.contentOffset, options: [.new]) { [weak self] sv, _ in
                self?.lastContentOffsetY = sv.contentOffset.y
            }
            sizeObservation = scrollView.observe(\.contentSize, options: [.new]) { [weak self] sv, _ in
                self?.lastContentHeight = sv.contentSize.height
            }
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

        func preserveAfterAppend(generation: Int, anchorOffset: CGFloat, anchorHeight: CGFloat) {
            for attempt in 0..<4 {
                let delay = 0.03 + Double(attempt) * 0.05
                DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
                    guard let self, coordinator?.preserveGeneration == generation else { return }
                    applyPreserveAfterAppend(anchorOffset: anchorOffset, anchorHeight: anchorHeight)
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

        /// Undo SwiftUI snapping to the new bottom after append — never while the user scrolls up.
        private func applyPreserveAfterAppend(anchorOffset: CGFloat, anchorHeight: CGFloat) {
            guard let scrollView = coordinator?.scrollView ?? enclosingScrollView() else { return }
            guard !scrollView.isDragging, !scrollView.isTracking, !scrollView.isDecelerating else { return }
            scrollView.layoutIfNeeded()
            let delta = scrollView.contentSize.height - anchorHeight
            guard delta > 0.5 else { return }
            let maxOffset = max(
                0,
                scrollView.contentSize.height
                    - scrollView.bounds.height
                    + scrollView.adjustedContentInset.bottom
            )
            let currentY = scrollView.contentOffset.y
            if currentY < anchorOffset - 12 { return }
            let jumpedToNewBottom = currentY >= maxOffset - 2
                && anchorOffset < maxOffset - delta + 2
            guard jumpedToNewBottom else { return }
            let targetY = min(anchorOffset, maxOffset)
            if abs(currentY - targetY) > 0.5 {
                scrollView.setContentOffset(CGPoint(x: 0, y: targetY), animated: false)
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
