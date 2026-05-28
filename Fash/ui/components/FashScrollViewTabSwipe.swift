import SwiftUI
import UIKit

/// Horizontal swipe between tabs inside a SwiftUI `ScrollView` — Android `detectHorizontalDragGestures`.
/// Attaches a native pan recognizer to the enclosing `UIScrollView` so vertical scroll still works.
struct FashScrollViewTabSwipe: UIViewRepresentable {
    var isEnabled: Bool = true
    var canGoPrevious: Bool
    var canGoNext: Bool
    var onPrevious: () -> Void
    var onNext: () -> Void

    static let swipeThreshold: CGFloat = 72

    func makeCoordinator() -> Coordinator {
        Coordinator(
            onPrevious: onPrevious,
            onNext: onNext
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

        private weak var scrollView: UIScrollView?
        private var panRecognizer: UIPanGestureRecognizer?
        private var accumulatedDrag: CGFloat = 0

        init(onPrevious: @escaping () -> Void, onNext: @escaping () -> Void) {
            self.onPrevious = onPrevious
            self.onNext = onNext
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
            case .changed:
                let translation = recognizer.translation(in: view)
                if abs(translation.x) > abs(translation.y) {
                    accumulatedDrag = translation.x
                }
            case .ended, .cancelled, .failed:
                defer {
                    accumulatedDrag = 0
                    recognizer.setTranslation(.zero, in: view)
                }
                guard abs(accumulatedDrag) >= FashScrollViewTabSwipe.swipeThreshold else { return }
                if accumulatedDrag <= -FashScrollViewTabSwipe.swipeThreshold, canGoNext {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onNext()
                } else if accumulatedDrag >= FashScrollViewTabSwipe.swipeThreshold, canGoPrevious {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    onPrevious()
                }
            default:
                break
            }
        }

        func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
            guard isEnabled, let pan = gestureRecognizer as? UIPanGestureRecognizer, let view = pan.view else {
                return false
            }
            let velocity = pan.velocity(in: view)
            return abs(velocity.x) > abs(velocity.y) * 1.1
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
    /// Swipe horizontally on the enclosing scroll view to move between tabs.
    func fashScrollViewTabSwipe(
        isEnabled: Bool = true,
        currentIndex: Int,
        tabCount: Int,
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
}
