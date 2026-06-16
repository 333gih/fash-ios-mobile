import SwiftUI
import UIKit

/// Dismisses the software keyboard / first responder before edge-back navigation.
enum FashKeyboard {
    /// Returns `true` when a first responder was resigned (keyboard likely dismissed).
    @MainActor
    static func dismissIfNeeded() -> Bool {
        UIApplication.shared.sendAction(
            #selector(UIResponder.resignFirstResponder),
            to: nil,
            from: nil,
            for: nil
        )
    }
}

/// Live edge-back drag state — drives the chevron affordance without re-rendering the whole tree every frame.
@Observable
@MainActor
final class FashEdgeBackGestureState {
    fileprivate(set) var progress: CGFloat = 0
    fileprivate(set) var isActive = false

    fileprivate func reset() {
        progress = 0
        isActive = false
    }

    fileprivate func apply(translationX: CGFloat, commitThreshold: CGFloat) {
        guard commitThreshold > 1 else {
            reset()
            return
        }
        isActive = true
        progress = min(1, max(0, translationX / commitThreshold))
    }
}

/// Left-edge horizontal swipe to navigate back — interactive chevron, commit only after a full drag.
struct FashEdgeBackNavigation: UIViewRepresentable {
    var isEnabled: Bool = true
    var gestureState: FashEdgeBackGestureState
    let onBack: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(gestureState: gestureState, isEnabled: isEnabled, onBack: onBack)
    }

    func makeUIView(context: Context) -> EdgeBackAnchorView {
        let view = EdgeBackAnchorView()
        view.coordinator = context.coordinator
        return view
    }

    func updateUIView(_ uiView: EdgeBackAnchorView, context: Context) {
        context.coordinator.isEnabled = isEnabled
        context.coordinator.gestureState = gestureState
        context.coordinator.onBack = onBack
        uiView.coordinator = context.coordinator
        uiView.setPanEnabled(isEnabled)
    }

    @MainActor
    final class Coordinator {
        var isEnabled: Bool
        var gestureState: FashEdgeBackGestureState
        var onBack: () -> Void

        init(gestureState: FashEdgeBackGestureState, isEnabled: Bool, onBack: @escaping () -> Void) {
            self.gestureState = gestureState
            self.isEnabled = isEnabled
            self.onBack = onBack
        }

        func commitThreshold(for view: UIView?) -> CGFloat {
            let width = view?.window?.bounds.width ?? UIScreen.main.bounds.width
            // Require a deliberate drag — ~38% of screen width, minimum 112pt (no velocity shortcut).
            return max(112, width * 0.38)
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
            pan.isEnabled = coordinator?.isEnabled ?? true
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
            guard let coordinator else { return }
            guard coordinator.isEnabled else {
                Task { @MainActor in coordinator.gestureState.reset() }
                return
            }

            let translationX = max(0, recognizer.translation(in: recognizer.view).x)
            let threshold = coordinator.commitThreshold(for: recognizer.view)

            switch recognizer.state {
            case .began, .changed:
                Task { @MainActor in
                    coordinator.gestureState.apply(translationX: translationX, commitThreshold: threshold)
                }
            case .ended:
                let shouldCommit = translationX >= threshold
                Task { @MainActor in
                    coordinator.gestureState.reset()
                    if shouldCommit {
                        if FashKeyboard.dismissIfNeeded() {
                            return
                        }
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        coordinator.onBack()
                    }
                }
            case .cancelled, .failed:
                Task { @MainActor in coordinator.gestureState.reset() }
            default:
                break
            }
        }

        func setPanEnabled(_ enabled: Bool) {
            panRecognizer?.isEnabled = enabled
        }
    }
}

extension FashEdgeBackNavigation.EdgeBackAnchorView: UIGestureRecognizerDelegate {
    func gestureRecognizer(
        _ gestureRecognizer: UIGestureRecognizer,
        shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        otherGestureRecognizer is UIScreenEdgePanGestureRecognizer
    }
}

/// Chevron affordance — appears at the left edge and follows drag progress.
private struct FashEdgeBackIndicator: View {
    var progress: CGFloat

    private var indicatorOpacity: Double {
        Double(min(1, progress * 2.2))
    }

    private var horizontalOffset: CGFloat {
        // Starts tucked at the edge, travels with the finger toward center.
        10 + progress * 52
    }

    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.12), radius: 6, y: 2)
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(FashColors.textPrimary)
            }
            .frame(width: 40, height: 40)
            .offset(x: horizontalOffset)
            .opacity(indicatorOpacity)
            .scaleEffect(0.88 + progress * 0.12)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        .padding(.leading, 4)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

extension AppRouter {
    /// Whether a left-edge swipe can pop the current layer (main tab, overlay, or PDP stack).
    func canEdgeBack(notificationsViewModel: NotificationsViewModel? = nil) -> Bool {
        if showNotificationScreen {
            return true
        }
        if showSettingsScreen
            || showChangePasswordScreen
            || showNotificationPreferencesScreen {
            return true
        }
        if showExploreOverlay {
            return true
        }
        if listingDetailRootId != nil {
            return true
        }
        if hasBlockingOverlay {
            return true
        }
        if loginStep == .otp {
            return true
        }
        // Post tab owns edge-back (prev step / discard dialog) via CreateListingFlowScreen.
        if selectedTab != .home, selectedTab != .post {
            return true
        }
        _ = notificationsViewModel
        return false
    }

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
        if showExploreOverlay, exploreOverlayListingId == nil {
            showExploreOverlay = false
            exploreSearchExpanded = false
            return true
        }
        if listingDetailRootId != nil {
            popListingDetail()
            return true
        }
        if hasBlockingOverlay {
            popOverlay()
            return true
        }
        if loginStep == .otp {
            loginStep = .email
            return true
        }
        if selectedTab != .home, selectedTab != .post {
            selectedTab = .home
            return true
        }
        return false
    }
}

extension View {
    /// Custom back action — use on full-screen covers and sheets.
    func fashEdgeBackNavigation(
        isEnabled: Bool = true,
        onBack: @escaping () -> Void
    ) -> some View {
        modifier(FashEdgeBackNavigationModifier(isEnabled: isEnabled, onBack: onBack))
    }

    /// App-router back stack — main shell, tabs, and router-owned overlays.
    func fashEdgeBackNavigation(
        router: AppRouter,
        notificationsViewModel: NotificationsViewModel?,
        isEnabled: Bool? = nil
    ) -> some View {
        modifier(
            FashEdgeBackNavigationModifier(
                isEnabled: isEnabled ?? router.canEdgeBack(notificationsViewModel: notificationsViewModel),
                onBack: {
                    _ = router.handleEdgeBack(notificationsViewModel: notificationsViewModel)
                }
            )
        )
    }
}

private struct FashEdgeBackNavigationModifier: ViewModifier {
    let isEnabled: Bool
    let onBack: () -> Void

    @State private var gestureState = FashEdgeBackGestureState()

    func body(content: Content) -> some View {
        content
            .background {
                FashEdgeBackNavigation(
                    isEnabled: isEnabled,
                    gestureState: gestureState
                ) {
                    onBack()
                }
                .frame(width: 0, height: 0)
                .allowsHitTesting(false)
            }
            .overlay {
                if gestureState.isActive {
                    FashEdgeBackIndicator(progress: gestureState.progress)
                        .transition(.opacity)
                        .zIndex(200)
                }
            }
            .animation(.easeOut(duration: 0.16), value: gestureState.isActive)
    }
}
