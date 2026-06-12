import FirebaseCore
import FirebaseMessaging
import UIKit
import UserNotifications

/// Firebase + APNs lifecycle — mirrors Android `FashFirebaseMessagingService` + `MainActivity` notification permission.
/// `FirebaseAppDelegateProxyEnabled` is NO in Info.plist — all FCM/APNs hooks are implemented here (Firebase iOS get-started).
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        PushNotificationCoordinator.configureFirebaseIfNeeded()
        UNUserNotificationCenter.current().delegate = PushNotificationCoordinator.shared
        Messaging.messaging().delegate = PushNotificationCoordinator.shared
        Task { @MainActor in
            await PushNotificationCoordinator.shared.syncRemoteNotificationRegistrationOnLaunch()
        }
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        PushNotificationCoordinator.applyAPNSToken(deviceToken)
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        PushDiagnostics.error("APNs registration failed: \(error.localizedDescription)")
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        Messaging.messaging().appDidReceiveMessage(userInfo)
        completionHandler(.newData)
    }
}
