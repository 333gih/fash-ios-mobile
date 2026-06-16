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
    /// SwiftUI fallback — primary scroll-to-top is UIKit via [PinnedTabScrollOffsetFixer].
    @MainActor
    static func scrollToTop(proxy: ScrollViewProxy) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            proxy.scrollTo(HomeScrollIds.top, anchor: .top)
        }
    }
}

enum HomeFeedScrollMath {
    static func isAtTop(contentOffsetY: CGFloat, adjustedInsetTop: CGFloat, tolerance: CGFloat = 28) -> Bool {
        contentOffsetY <= -adjustedInsetTop + tolerance
    }

    static func isNearBottom(
        contentOffsetY: CGFloat,
        contentHeight: CGFloat,
        viewportHeight: CGFloat,
        adjustedInsetBottom: CGFloat
    ) -> Bool {
        guard contentHeight > 1, viewportHeight > 1 else { return true }
        let maxOffset = max(
            0,
            contentHeight - viewportHeight + adjustedInsetBottom
        )
        if maxOffset <= 48 { return true }
        let distanceFromBottom = maxOffset - contentOffsetY
        let threshold = max(520, viewportHeight * 1.35)
        return distanceFromBottom <= threshold
    }
}

/// UIKit scroll boundary — gates Following load-more so upward scroll is not fighting pagination.
@Observable
@MainActor
final class HomeFeedScrollBoundary {
    private(set) var isNearBottom = false
    private(set) var isAtTop = true
    private(set) var isScrollingUp = false

    /// Load-more when near the feed bottom and not actively scrolling up toward the header.
    var allowsFollowingLoadMore: Bool {
        guard !isScrollingUp else { return false }
        return isNearBottom
    }

    fileprivate func apply(
        contentOffsetY: CGFloat,
        contentHeight: CGFloat,
        viewportHeight: CGFloat,
        adjustedInsetTop: CGFloat,
        adjustedInsetBottom: CGFloat,
        deltaY: CGFloat
    ) {
        let atTop = HomeFeedScrollMath.isAtTop(
            contentOffsetY: contentOffsetY,
            adjustedInsetTop: adjustedInsetTop
        )
        let nearBottom = HomeFeedScrollMath.isNearBottom(
            contentOffsetY: contentOffsetY,
            contentHeight: contentHeight,
            viewportHeight: viewportHeight,
            adjustedInsetBottom: adjustedInsetBottom
        )
        if atTop != isAtTop { isAtTop = atTop }
        if nearBottom != isNearBottom { isNearBottom = nearBottom }
        if abs(deltaY) > 3.5 {
            if deltaY < 0 {
                if !isScrollingUp { isScrollingUp = true }
            } else if isScrollingUp {
                isScrollingUp = false
            }
        }
        if atTop, isScrollingUp { isScrollingUp = false }
    }

    fileprivate func clearScrollingUpIfIdle() {
        // Only release the scroll-up latch at the top — mid-feed idle still blocks load-more.
        if isScrollingUp, isAtTop { isScrollingUp = false }
    }
}

/// Boundary tracking on the home feed `UIScrollView` (scroll-to-top uses [PinnedTabScrollOffsetFixer]).
struct HomeFeedScrollCoordinator: UIViewRepresentable {
    var scrollBoundary: HomeFeedScrollBoundary

    func makeCoordinator() -> Coordinator { Coordinator(boundary: scrollBoundary) }

    func makeUIView(context: Context) -> AnchorView {
        let view = AnchorView()
        view.coordinator = context.coordinator
        return view
    }

    func updateUIView(_ uiView: AnchorView, context: Context) {
        let coordinator = context.coordinator
        coordinator.boundary = scrollBoundary
        uiView.coordinator = coordinator
        coordinator.installIfNeeded(from: uiView)
    }

    @MainActor
    final class Coordinator {
        var boundary: HomeFeedScrollBoundary
        weak var scrollView: UIScrollView?
        private var offsetObservation: NSKeyValueObservation?
        private var lastContentOffsetY: CGFloat?
        private var scrollIdleTask: Task<Void, Never>?

        init(boundary: HomeFeedScrollBoundary) {
            self.boundary = boundary
        }

        func installIfNeeded(from anchor: UIView) {
            guard let scrollView = anchor.enclosingScrollView() else { return }
            if self.scrollView === scrollView, offsetObservation != nil { return }

            offsetObservation?.invalidate()
            self.scrollView = scrollView
            lastContentOffsetY = scrollView.contentOffset.y
            reportBoundary(on: scrollView, deltaY: 0)

            offsetObservation = scrollView.observe(\.contentOffset, options: [.new]) { [weak self] sv, _ in
                Task { @MainActor in
                    guard let self else { return }
                    let y = sv.contentOffset.y
                    let delta = y - (self.lastContentOffsetY ?? y)
                    self.lastContentOffsetY = y
                    self.reportBoundary(on: sv, deltaY: delta)
                }
            }
        }

        @MainActor
        private func reportBoundary(on scrollView: UIScrollView, deltaY: CGFloat) {
            boundary.apply(
                contentOffsetY: scrollView.contentOffset.y,
                contentHeight: scrollView.contentSize.height,
                viewportHeight: scrollView.bounds.height,
                adjustedInsetTop: scrollView.adjustedContentInset.top,
                adjustedInsetBottom: scrollView.adjustedContentInset.bottom,
                deltaY: deltaY
            )
            scrollIdleTask?.cancel()
            scrollIdleTask = Task { @MainActor in
                try? await Task.sleep(for: .milliseconds(200))
                guard !Task.isCancelled else { return }
                boundary.clearScrollingUpIfIdle()
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
