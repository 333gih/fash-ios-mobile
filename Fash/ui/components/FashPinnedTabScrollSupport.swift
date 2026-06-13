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
    /// Bottom-nav re-tap / pull-to-refresh — force `contentOffset.y = 0` (full header), not pinned-tab offset.
    var trueTopToken: Int = 0
    var clampRevision: Int = 0
    var headerHeight: CGFloat
    /// Skip clamp/reset while user is pulling to refresh — avoids fighting overscroll bounce.
    var suspendDuringPull: Bool = false

    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> AnchorView {
        let view = AnchorView()
        view.coordinator = context.coordinator
        return view
    }

    func updateUIView(_ uiView: AnchorView, context: Context) {
        uiView.coordinator = context.coordinator
        let token = resetToken
        let topToken = trueTopToken
        let revision = clampRevision

        // Home re-tap must always reach y=0 — even during pull-to-refresh overscroll.
        let trueTopChanged = topToken != context.coordinator.lastAppliedTrueTopToken
        if trueTopChanged, topToken > 0 {
            context.coordinator.lastAppliedTrueTopToken = topToken
            uiView.scheduleTrueTop(attempt: 0)
        }

        guard !suspendDuringPull else { return }
        guard token > 0 || revision > 0 else { return }

        let tokenChanged = token != context.coordinator.lastAppliedToken
        let revisionChanged = revision != context.coordinator.lastAppliedClampRevision
        guard tokenChanged || revisionChanged else { return }

        context.coordinator.lastAppliedToken = token
        context.coordinator.lastAppliedClampRevision = revision
        let mode: AnchorView.ResetMode = tokenChanged ? .pinnedReset : .clampOnly
        uiView.scheduleReset(headerHeight: headerHeight, mode: mode)
    }

    final class Coordinator {
        var lastAppliedToken = 0
        var lastAppliedTrueTopToken = 0
        var lastAppliedClampRevision = 0
    }

    final class AnchorView: UIView {
        enum ResetMode {
            /// Tab swap — align grid under pinned chrome.
            case pinnedReset
            /// Content height changed — only trim stale deep offsets, never pull user back to tabs.
            case clampOnly
        }

        weak var coordinator: Coordinator?

        func scheduleReset(headerHeight: CGFloat, mode: ResetMode) {
            DispatchQueue.main.async { [weak self] in
                self?.applyReset(headerHeight: headerHeight, mode: mode, attempt: 0)
            }
        }

        func scheduleTrueTop(attempt: Int) {
            DispatchQueue.main.async { [weak self] in
                self?.applyTrueTop(attempt: attempt)
            }
        }

        private func applyTrueTop(attempt: Int) {
            guard let scrollView = enclosingScrollView() else { return }
            scrollView.layoutIfNeeded()
            let visualTop = -scrollView.adjustedContentInset.top
            if scrollView.contentOffset.y > visualTop + 1.5 {
                scrollView.setContentOffset(CGPoint(x: 0, y: visualTop), animated: false)
            }
            guard attempt < 12 else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) { [weak self] in
                self?.applyTrueTop(attempt: attempt + 1)
            }
        }

        private func applyReset(headerHeight: CGFloat, mode: ResetMode, attempt: Int) {
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

            let safeTarget = min(pinnedTarget, maxOffset)

            switch mode {
            case .pinnedReset:
                // Only snap when already in pinned-feed territory — never pull user down from mid-scroll-up.
                if currentY >= safeTarget - 20, abs(currentY - safeTarget) > 1.5 {
                    scrollView.setContentOffset(CGPoint(x: 0, y: safeTarget), animated: false)
                }
            case .clampOnly:
                if currentY > maxOffset + 1.5 {
                    scrollView.setContentOffset(CGPoint(x: 0, y: maxOffset), animated: false)
                }
            }

            let maxAttempts = mode == .pinnedReset ? 12 : 4
            guard attempt < maxAttempts else { return }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) { [weak self] in
                self?.applyReset(headerHeight: headerHeight, mode: mode, attempt: attempt + 1)
            }
        }
    }
}

enum PinnedTabScrollReset {
    /// Programmatic scroll without binding `scrollPosition` (avoids jump-to-top when feed appends).
    @MainActor
    static func scrollToPinnedContent<ID: Hashable>(
        proxy: ScrollViewProxy,
        resetToken: Binding<Int>,
        contentId: ID,
        followUpDelaysMs: [Int] = [60, 140, 260]
    ) {
        proxy.scrollTo(contentId, anchor: .top)
        resetToken.wrappedValue += 1

        guard !followUpDelaysMs.isEmpty else { return }
        Task { @MainActor in
            for delayMs in followUpDelaysMs {
                try? await Task.sleep(for: .milliseconds(delayMs))
                proxy.scrollTo(contentId, anchor: .top)
            }
        }
    }

    @MainActor
    static func scrollToPinnedContent<ID: Hashable>(
        scrollPosition: Binding<ID?>,
        proxy: ScrollViewProxy,
        resetToken: Binding<Int>,
        contentId: ID,
        followUpDelaysMs: [Int] = [60, 140, 260]
    ) {
        scrollPosition.wrappedValue = contentId
        scrollToPinnedContent(
            proxy: proxy,
            resetToken: resetToken,
            contentId: contentId,
            followUpDelaysMs: followUpDelaysMs
        )
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
