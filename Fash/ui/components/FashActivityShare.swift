import SwiftUI
import UIKit

/// Presents the system share sheet and reports whether the user completed a share action.
enum FashActivityShare {
    static func present(
        activityItems: [Any],
        onCompleted: ((Bool) -> Void)? = nil
    ) {
        let activity = UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
        activity.completionWithItemsHandler = { _, completed, _, _ in
            onCompleted?(completed)
        }
        guard let presenter = topPresenter() else { return }
        if let popover = activity.popoverPresentationController {
            popover.sourceView = presenter.view
            popover.sourceRect = CGRect(
                x: presenter.view.bounds.midX,
                y: presenter.view.bounds.midY,
                width: 0,
                height: 0
            )
        }
        presenter.present(activity, animated: true)
    }

    private static func topPresenter() -> UIViewController? {
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first(where: { $0.isKeyWindow })?.rootViewController
            ?? scene.windows.first?.rootViewController else { return nil }
        var presenter = root
        while let presented = presenter.presentedViewController { presenter = presented }
        return presenter
    }
}

struct ActivityShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    var onCompleted: ((Bool) -> Void)?

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        controller.completionWithItemsHandler = { _, completed, _, _ in
            onCompleted?(completed)
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
