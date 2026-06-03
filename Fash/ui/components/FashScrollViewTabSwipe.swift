import SwiftUI
import UIKit

/// Horizontal swipe between tabs inside a SwiftUI `ScrollView` — TikTok-style axis lock + tap guard.
/// Attaches a native pan recognizer to the enclosing `UIScrollView` so vertical scroll still works.
struct FashScrollViewTabSwipe: UIViewRepresentable {
    var isEnabled: Bool = true
    var canGoPrevious: Bool
    var canGoNext: Bool
    var onPrevious: () -> Void
    var onNext: () -> Void
    var onHorizontalSwipeActive: (Bool) -> Void = { _ in }
    var onTabSwipeCommitted: () -> Void = {}

    static let swipeThreshold: CGFloat = 72
    static let flingDistanceThreshold: CGFloat = 36
    static let flingVelocityThreshold: CGFloat = 900
    static let postCommitTapGuard: TimeInterval = 0.32

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onPrevious: onPrevious,
            onNext: onNext,
            onHorizontalSwipeActive: onHorizontalSwipeActive,
            onTabSwipeCommitted: onTabSwipeCommitted
        )
    }

    func makeUIView(context: Context) -> AnchorView {
        let view = AnchorView()
        view.isUserInteractionEnabled = false
        view.coordinator = context.coordinator
        return view
    }

    func updateUIView(_ uiView: AnchorView, context: Context) {
        context.coordinator.onPrevious = onPrevious
        context.coordinator.onNext = onNext
        context.coordinator.canGoPrevious = canGoPrevious
        context.coordinator.canGoNext = canGoNext
        context.coordinator.isEnabled = isEnabled
        context.coordinator.onHorizontalSwipeActive = onHorizontalSwipeActive
        context.coordinator.onTabSwipeCommitted = onTabSwipeCommitted
        uiView.coordinator = context.coordinator
        uiView.scheduleInstall()
    }

    final class AnchorView: UIView {
        weak var coordinator: Coordinator?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            scheduleInstall()
        }

        func scheduleInstall() {
            guard window != nil else { return }
            DispatchQueue.main.async { [weak self] in
                guard let self, let coordinator else { return }
                coordinator.installIfNeeded(from: self)
            }
        }
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        var isEnabled: Bool = true
        var canGoPrevious: Bool = false
        var canGoNext: Bool = false
        var onPrevious: () -> Void
        var onNext: () -> Void
        var onHorizontalSwipeActive: (Bool) -> Void
        var onTabSwipeCommitted: () -> Void

        private weak var scrollView: UIScrollView?
        private var panRecognizer: UIPanGestureRecognizer?
        private var accumulatedDrag: CGFloat = 0
        private var horizontalLocked = false
        private var scrollWasEnabled = true

        init(
            onPrevious: @escaping () -> Void,
            onNext: @escaping () -> Void,
            onHorizontalSwipeActive: @escaping (Bool) -> Void,
            onTabSwipeCommitted: @escaping () -> Void
        ) {
            self.onPrevious = onPrevious
            self.onNext = onNext
            self.onHorizontalSwipeActive = onHorizontalSwipeActive
            self.onTabSwipeCommitted = onTabSwipeCommitted
        }

        func installIfNeeded(from anchor: UIView) {
            guard let scrollView = anchor.enclosingScrollView() else { return }
            if self.scrollView === scrollView, panRecognizer != nil { return }

            if let panRecognizer, let oldScrollView = self.scrollView {
                oldScrollView.removeGestureRecognizer(panRecognizer)
            }

            let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            pan.delegate = self
            pan.cancelsTouchesInView = false
            scrollView.addGestureRecognizer(pan)
            panRecognizer = pan
            self.scrollView = scrollView
        }

        @objc private func handlePan(_ recognizer: UIPanGestureRecognizer) {
            guard isEnabled, let view = recognizer.view else { return }

            switch recognizer.state {
            case .began:
                accumulatedDrag = 0
                horizontalLocked = false
                scrollWasEnabled = scrollView?.isScrollEnabled ?? true

            case .changed:
                let translation = recognizer.translation(in: view)
                if !horizontalLocked {
                    if abs(translation.x) > 10, abs(translation.x) > abs(translation.y) * 1.15 {
                        horizontalLocked = true
                        recognizer.cancelsTouchesInView = true
                        scrollView?.isScrollEnabled = false
                        onHorizontalSwipeActive(true)
                    }
                }
                if horizontalLocked {
                    accumulatedDrag = translation.x
                }

            case .ended, .cancelled, .failed:
                let wasLocked = horizontalLocked
                let velocity = recognizer.velocity(in: view).x
                let flingNext = velocity <= -FashScrollViewTabSwipe.flingVelocityThreshold
                let flingPrev = velocity >= FashScrollViewTabSwipe.flingVelocityThreshold

                let commitNext =
                    wasLocked
                    && (accumulatedDrag <= -FashScrollViewTabSwipe.swipeThreshold
                        || (flingNext && abs(accumulatedDrag) > FashScrollViewTabSwipe.flingDistanceThreshold))
                    && canGoNext
                let commitPrev =
                    wasLocked
                    && (accumulatedDrag >= FashScrollViewTabSwipe.swipeThreshold
                        || (flingPrev && abs(accumulatedDrag) > FashScrollViewTabSwipe.flingDistanceThreshold))
                    && canGoPrevious
                let committed = commitNext || commitPrev

                resetSwipeState(recognizer: recognizer, in: view)

                guard wasLocked else { return }

                if committed {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onTabSwipeCommitted()
                    if commitNext {
                        onNext()
                    } else {
                        onPrevious()
                    }
                } else {
                    onHorizontalSwipeActive(false)
                }

            default:
                break
            }
        }

        private func resetSwipeState(recognizer: UIPanGestureRecognizer, in view: UIView) {
            horizontalLocked = false
            accumulatedDrag = 0
            recognizer.cancelsTouchesInView = false
            scrollView?.isScrollEnabled = scrollWasEnabled
            recognizer.setTranslation(.zero, in: view)
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard isEnabled,
                  let pan = gestureRecognizer as? UIPanGestureRecognizer,
                  let view = pan.view else {
                return false
            }
            let location = pan.location(in: view)
            if view.fash_hasHorizontallyScrollableSubview(at: location) {
                return false
            }
            let velocity = pan.velocity(in: view)
            return abs(velocity.x) > abs(velocity.y) * 1.1
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRequireFailureOf otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            guard let scroll = otherGestureRecognizer.view as? UIScrollView,
                  scroll !== scrollView else {
                return false
            }
            return scroll.fash_isHorizontallyScrollable
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }
    }
}

extension View {
    /// Profile / storefront: tab swipe on sticky tab bar + listing body only (not hero / focus chips).
    func profileTabSwipe(
        enabled: Bool = true,
        currentIndex: Int,
        tabCount: Int,
        listingInteractionEnabled: Binding<Bool>? = nil,
        onIndexChanged: @escaping (Int) -> Void
    ) -> some View {
        fashScrollViewTabSwipe(
            isEnabled: enabled,
            currentIndex: currentIndex,
            tabCount: tabCount,
            listingInteractionEnabled: listingInteractionEnabled,
            onIndexChanged: onIndexChanged
        )
    }

    /// Swipe horizontally on the enclosing scroll view to move between tabs (TikTok-style).
    func fashScrollViewTabSwipe(
        isEnabled: Bool = true,
        currentIndex: Int,
        tabCount: Int,
        listingInteractionEnabled: Binding<Bool>? = nil,
        onIndexChanged: @escaping (Int) -> Void
    ) -> some View {
        background {
            FashScrollViewTabSwipe(
                isEnabled: isEnabled && tabCount > 1,
                canGoPrevious: currentIndex > 0,
                canGoNext: currentIndex < tabCount - 1,
                onPrevious: {
                    guard currentIndex > 0 else { return }
                    onIndexChanged(currentIndex - 1)
                },
                onNext: {
                    guard currentIndex < tabCount - 1 else { return }
                    onIndexChanged(currentIndex + 1)
                },
                onHorizontalSwipeActive: { active in
                    listingInteractionEnabled?.wrappedValue = !active
                },
                onTabSwipeCommitted: {
                    listingInteractionEnabled?.wrappedValue = false
                    DispatchQueue.main.asyncAfter(deadline: .now() + FashScrollViewTabSwipe.postCommitTapGuard) {
                        listingInteractionEnabled?.wrappedValue = true
                    }
                }
            )
        }
    }
}

private extension UIView {
    func enclosingScrollView() -> UIScrollView? {
        var candidate: UIView? = superview
        while let view = candidate {
            if let scrollView = view as? UIScrollView {
                return scrollView
            }
            candidate = view.superview
        }
        return nil
    }

    /// True when [point] hits a nested horizontal scroll view (e.g. category/brand chip rows).
    func fash_hasHorizontallyScrollableSubview(at point: CGPoint) -> Bool {
        guard bounds.contains(point) else { return false }
        guard let hit = hitTest(point, with: nil) else { return false }
        var view: UIView? = hit
        while let current = view {
            if let scroll = current as? UIScrollView, scroll !== self, scroll.fash_isHorizontallyScrollable {
                return true
            }
            if current === self { break }
            view = current.superview
        }
        return false
    }
}

private extension UIScrollView {
    var fash_isHorizontallyScrollable: Bool {
        guard isScrollEnabled, bounds.width > 1 else { return false }
        return contentSize.width > bounds.width + 4
    }
}
