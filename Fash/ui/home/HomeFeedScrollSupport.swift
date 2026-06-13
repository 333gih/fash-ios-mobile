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
    @MainActor
    static func scrollToTop(proxy: ScrollViewProxy) {
        var transaction = Transaction()
        transaction.disablesAnimations = true
        withTransaction(transaction) {
            proxy.scrollTo(HomeScrollIds.top, anchor: .top)
        }

        Task { @MainActor in
            for delayMs in [60, 140, 260, 420, 640] {
                try? await Task.sleep(for: .milliseconds(delayMs))
                var followUp = Transaction()
                followUp.disablesAnimations = true
                withTransaction(followUp) {
                    proxy.scrollTo(HomeScrollIds.top, anchor: .top)
                }
            }
        }
    }
}

/// One-shot scroll-to-top on Home re-tap.
struct HomeFeedScrollToTopHelper: UIViewRepresentable {
    var token: Int

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> AnchorView {
        let view = AnchorView()
        view.coordinator = context.coordinator
        return view
    }

    func updateUIView(_ uiView: AnchorView, context: Context) {
        uiView.coordinator = context.coordinator
        guard token > 0, token != context.coordinator.lastAppliedToken else { return }
        context.coordinator.lastAppliedToken = token
        uiView.scheduleScrollToTop(attempt: 0)
    }

    final class Coordinator {
        var lastAppliedToken = 0
    }

    final class AnchorView: UIView {
        weak var coordinator: Coordinator?

        func scheduleScrollToTop(attempt: Int) {
            DispatchQueue.main.async { [weak self] in
                self?.applyScrollToTop(attempt: attempt)
            }
        }

        private func applyScrollToTop(attempt: Int) {
            guard let scrollView = enclosingScrollView() else { return }
            scrollView.layoutIfNeeded()
            let top = -scrollView.adjustedContentInset.top
            if scrollView.contentOffset.y > top + 1.5 {
                scrollView.setContentOffset(CGPoint(x: 0, y: top), animated: attempt == 0)
            }
            guard attempt < 8 else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.07) { [weak self] in
                self?.applyScrollToTop(attempt: attempt + 1)
            }
        }
    }
}

/// One-shot max-offset trim when tab body height shrinks — never blocks scrolling up.
struct HomeFeedScrollClampHelper: UIViewRepresentable {
    var clampToken: Int

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> AnchorView {
        let view = AnchorView()
        view.coordinator = context.coordinator
        return view
    }

    func updateUIView(_ uiView: AnchorView, context: Context) {
        uiView.coordinator = context.coordinator
        guard clampToken > 0, clampToken != context.coordinator.lastAppliedToken else { return }
        context.coordinator.lastAppliedToken = clampToken
        uiView.scheduleClamp(attempt: 0)
    }

    final class Coordinator {
        var lastAppliedToken = 0
    }

    final class AnchorView: UIView {
        weak var coordinator: Coordinator?

        func scheduleClamp(attempt: Int) {
            DispatchQueue.main.async { [weak self] in
                self?.applyClamp(attempt: attempt)
            }
        }

        private func applyClamp(attempt: Int) {
            guard let scrollView = enclosingScrollView() else { return }
            scrollView.layoutIfNeeded()
            let maxOffset = max(
                0,
                scrollView.contentSize.height
                    - scrollView.bounds.height
                    + scrollView.adjustedContentInset.bottom
            )
            if scrollView.contentOffset.y > maxOffset + 1.5 {
                scrollView.setContentOffset(CGPoint(x: 0, y: maxOffset), animated: false)
            }
            guard attempt < 3 else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
                self?.applyClamp(attempt: attempt + 1)
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
