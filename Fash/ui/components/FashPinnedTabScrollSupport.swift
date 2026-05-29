import SwiftUI
import UIKit

enum PinnedTabScrollPolicy {
    /// Scroll offset where the hero/header has scrolled away and tab chrome is pinned — feed/grid starts below.
    static func pinnedContentOffset(headerHeight: CGFloat, maxScrollOffset: CGFloat) -> CGFloat {
        guard headerHeight > 1 else { return max(0, maxScrollOffset) }
        let ideal = max(0, headerHeight - 8)
        if maxScrollOffset >= ideal {
            return ideal
        }
        // Short tab body (e.g. empty state) — clamp to end so stale deep offsets do not hide copy.
        return max(0, maxScrollOffset)
    }
}

/// Resets UIScrollView offset after tab swaps when feed/grid height shrinks — SwiftUI `scrollTo` alone keeps stale offset.
struct PinnedTabScrollOffsetFixer: UIViewRepresentable {
    var resetToken: Int
    var headerHeight: CGFloat

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> AnchorView {
        let view = AnchorView()
        view.coordinator = context.coordinator
        return view
    }

    func updateUIView(_ uiView: AnchorView, context: Context) {
        uiView.coordinator = context.coordinator
        guard resetToken > 0, resetToken != context.coordinator.lastAppliedToken else { return }
        context.coordinator.lastAppliedToken = resetToken
        uiView.scheduleReset(headerHeight: headerHeight)
    }

    final class Coordinator {
        var lastAppliedToken = 0
    }

    final class AnchorView: UIView {
        weak var coordinator: Coordinator?

        func scheduleReset(headerHeight: CGFloat) {
            DispatchQueue.main.async { [weak self] in
                self?.applyReset(headerHeight: headerHeight, attempt: 0)
            }
        }

        private func applyReset(headerHeight: CGFloat, attempt: Int) {
            guard let scrollView = enclosingScrollView() else { return }
            scrollView.layoutIfNeeded()

            let maxOffset = max(
                0,
                scrollView.contentSize.height
                    - scrollView.bounds.height
                    + scrollView.adjustedContentInset.bottom
            )
            let pinnedTarget = PinnedTabScrollPolicy.pinnedContentOffset(
                headerHeight: headerHeight,
                maxScrollOffset: maxOffset
            )
            let currentY = scrollView.contentOffset.y

            if abs(currentY - pinnedTarget) > 1.5 || currentY > maxOffset + 1.5 {
                scrollView.setContentOffset(CGPoint(x: 0, y: pinnedTarget), animated: false)
            }

            guard attempt < 5 else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) { [weak self] in
                self?.applyReset(headerHeight: headerHeight, attempt: attempt + 1)
            }
        }
    }
}

enum PinnedTabScrollReset {
    @MainActor
    static func scrollToPinnedContent<ID: Hashable>(
        scrollPosition: Binding<ID?>,
        proxy: ScrollViewProxy,
        resetToken: Binding<Int>,
        contentId: ID
    ) {
        scrollPosition.wrappedValue = contentId
        proxy.scrollTo(contentId, anchor: .top)
        resetToken.wrappedValue += 1

        Task { @MainActor in
            for delayMs in [60, 140, 260] {
                try? await Task.sleep(for: .milliseconds(delayMs))
                scrollPosition.wrappedValue = contentId
                proxy.scrollTo(contentId, anchor: .top)
            }
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
