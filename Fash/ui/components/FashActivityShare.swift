import SwiftUI
import UIKit

/// Presents the system share sheet; dismisses it before feedback so snackbars show on the current screen.
enum FashActivityShare {
    static let dismissSettleNanoseconds: UInt64 = 350_000_000

    static func present(
        activityItems: [Any],
        onCompleted: ((Bool) -> Void)? = nil
    ) {
        guard let host = topPresenterForPresentation() else { return }
        let activity = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        if let popover = activity.popoverPresentationController {
            popover.sourceView = host.view
            popover.sourceRect = CGRect(
                x: host.view.bounds.midX,
                y: host.view.bounds.midY,
                width: 0,
                height: 0
            )
        }
        activity.completionWithItemsHandler = { _, completed, _, _ in
            finishPresentedShare(
                activity: activity,
                presentingHost: host,
                completed: completed,
                onCompleted: onCompleted
            )
        }
        host.present(activity, animated: true)
    }

    @MainActor
    static func showSuccessIfNeeded(_ completed: Bool, message: String, deps: AppDependencies) {
        guard completed else { return }
        deps.showSnackbar(message)
    }

    private static func finishPresentedShare(
        activity: UIActivityViewController,
        presentingHost: UIViewController,
        completed: Bool,
        onCompleted: ((Bool) -> Void)?
    ) {
        let deliver: () -> Void = {
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: dismissSettleNanoseconds)
                onCompleted?(completed)
            }
        }
        if activity.presentingViewController != nil {
            activity.dismiss(animated: true, completion: deliver)
        } else if presentingHost.presentedViewController === activity {
            presentingHost.dismiss(animated: true, completion: deliver)
        } else {
            deliver()
        }
    }

    private static func topPresenterForPresentation() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
            ?? scene.windows.first?.rootViewController else { return nil }
        var presenter = root
        while let presented = presenter.presentedViewController {
            if presented is UIActivityViewController { break }
            presenter = presented
        }
        return presenter
    }
}

/// SwiftUI sheet wrapper — dismisses sheet then reports share completion.
struct ActivityShareSheet: View {
    let items: [Any]
    var onCompleted: ((Bool) -> Void)?

    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ActivityShareViewControllerRepresentable(items: items) { completed in
            dismiss()
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: FashActivityShare.dismissSettleNanoseconds)
                onCompleted?(completed)
            }
        }
        .ignoresSafeArea()
    }
}

private struct ActivityShareViewControllerRepresentable: UIViewControllerRepresentable {
    let items: [Any]
    let onFinish: (Bool) -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, completed, _, _ in
            Task { @MainActor in
                onFinish(completed)
            }
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
