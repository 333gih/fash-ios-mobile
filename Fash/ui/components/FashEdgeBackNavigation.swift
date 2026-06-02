import SwiftUI
import UIKit

/// Left-edge horizontal swipe to navigate back — closes overlays first, then returns to Home tab.
struct FashEdgeBackNavigation: UIViewRepresentable {
    var isEnabled: Bool = true
    let onBack: () -> Void

    func makeCoordinator() -> Coordinator { Coordinator(isEnabled: isEnabled, onBack: onBack) }

    func makeUIView(context: Context) -> EdgeBackAnchorView {
        let view = EdgeBackAnchorView()
        view.coordinator = context.coordinator
        return view
    }

    func updateUIView(_ uiView: EdgeBackAnchorView, context: Context) {
        context.coordinator.isEnabled = isEnabled
        uiView.coordinator = context.coordinator
    }

    final class Coordinator {
        var isEnabled: Bool
        let onBack: () -> Void
        init(isEnabled: Bool, onBack: @escaping () -> Void) {
            self.isEnabled = isEnabled
            self.onBack = onBack
        }
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
            guard coordinator?.isEnabled == true else { return }
            guard recognizer.state == .ended else { return }
            let translation = recognizer.translation(in: recognizer.view).x
            let velocity = recognizer.velocity(in: recognizer.view).x
            guard translation > 72 || velocity > 520 else { return }
            coordinator?.onBack()
        }
    }
}

extension FashEdgeBackNavigation.EdgeBackAnchorView: UIGestureRecognizerDelegate {
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        coordinator?.isEnabled == true
    }

    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        otherGestureRecognizer is UIScreenEdgePanGestureRecognizer
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
        notificationsViewModel: NotificationsViewModel?,
        isEnabled: Bool = true
    ) -> some View {
        background {
            FashEdgeBackNavigation(isEnabled: isEnabled) {
                _ = router.handleEdgeBack(notificationsViewModel: notificationsViewModel)
            }
            .frame(width: 0, height: 0)
            .allowsHitTesting(false)
        }
    }
}
