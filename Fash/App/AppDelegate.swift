import UIKit
import UserNotifications

/// Firebase + APNs lifecycle — mirrors personal-os `POSAppDelegate`.
/// Transport (FCM vs pure APNs) is decided at runtime by `PushNotificationCoordinator` via `USE_FIREBASE_MESSAGING`.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        PushNotificationCoordinator.configureMessagingIfNeeded()
        Task { @MainActor in
            await PushNotificationCoordinator.shared.syncRemoteNotificationRegistrationOnLaunch()
        }
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Task { @MainActor in
            PushNotificationCoordinator.applyAPNSToken(deviceToken)
        }
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        PushDiagnostics.error("APNs registration failed: \(error.localizedDescription)")
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        Task { @MainActor in
            PushNotificationCoordinator.shared.appDidReceiveRemoteMessage(userInfo)
            completionHandler(.newData)
        }
    }
}
