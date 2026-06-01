import SwiftUI
import UIKit

/// Left-edge horizontal swipe to navigate back — closes overlays first, then returns to Home tab.
struct FashEdgeBackNavigation: UIViewRepresentable {
    let onBack: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onBack: onBack) }

    func makeUIView(context: Context) -> EdgeBackAnchorView {
        let view = EdgeBackAnchorView()
        view.coordinator = context.coordinator
        return view
    }

    func updateUIView(_ uiView: EdgeBackAnchorView, context: Context) {
        uiView.coordinator = context.coordinator
    }

    final class Coordinator {
        let onBack: () -> Void
        init(onBack: @escaping () -> Void) { self.onBack = onBack }
    }

    final class EdgeBackAnchorView: UIView {
        weak var coordinator: Coordinator?
        private var panRecognizer: UIScreenEdgePanGestureRecognizer?

        override func didMoveToWindow() {
            super.didMoveToWindow()
            guard let window, panRecognizer == nil else { return }
            let pan = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleEdgePan(_:)))
            pan.edges = .left
            pan.delegate = self
            window.addGestureRecognizer(pan)
            panRecognizer = pan
        }

        override func willMove(toWindow newWindow: UIWindow?) {
            if newWindow == nil, let panRecognizer, let window {
                window.removeGestureRecognizer(panRecognizer)
            }
            super.willMove(toWindow: newWindow)
        }

        @objc private func handleEdgePan(_ recognizer: UIScreenEdgePanGestureRecognizer) {
            guard recognizer.state == .ended else { return }
            let translation = recognizer.translation(in: recognizer.view).x
            let velocity = recognizer.velocity(in: recognizer.view).x
            guard translation > 72 || velocity > 520 else { return }
            coordinator?.onBack()
        }
    }
}

extension FashEdgeBackNavigation.EdgeBackAnchorView: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        false
    }
}

private enum EdgeBackNavigation {}

extension AppRouter {
    /// Handles edge-swipe / back: overlays first, then Home tab. Returns whether navigation was consumed.
    @discardableResult
    func handleEdgeBack(notificationsViewModel: NotificationsViewModel?) -> Bool {
        if showNotificationScreen {
            if let notificationsViewModel, notificationsViewModel.selectedDetailId != nil {
                notificationsViewModel.closeDetail()
            } else if notificationDetailId != nil {
                notificationDetailId = nil
            } else {
                showNotificationScreen = false
            }
            return true
        }
        if showSettingsScreen {
            showSettingsScreen = false
            return true
        }
        if showChangePasswordScreen {
            showChangePasswordScreen = false
            return true
        }
        if showNotificationPreferencesScreen {
            showNotificationPreferencesScreen = false
            return true
        }
        if showExploreOverlay {
            showExploreOverlay = false
            exploreSearchExpanded = false
            return true
        }
        if hasBlockingOverlay {
            popOverlay()
            return true
        }
        if selectedTab != .home {
            selectedTab = .home
            return true
        }
        return false
    }
}

extension View {
    func fashEdgeBackNavigation(
        router: AppRouter,
        notificationsViewModel: NotificationsViewModel?
    ) -> some View {
        background {
            FashEdgeBackNavigation {
                _ = router.handleEdgeBack(notificationsViewModel: notificationsViewModel)
            }
            .frame(width: 0, height: 0)
            .allowsHitTesting(false)
        }
    }
}
