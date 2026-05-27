import FirebaseCore
import FirebaseMessaging
import UIKit
import UserNotifications

/// Firebase + APNs lifecycle — mirrors Android `FashFirebaseMessagingService` + `MainActivity` notification permission.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        PushNotificationCoordinator.configureFirebaseIfNeeded()
        UNUserNotificationCenter.current().delegate = PushNotificationCoordinator.shared
        Messaging.messaging().delegate = PushNotificationCoordinator.shared
        return true
    }

    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        #if DEBUG
        print("[Push] APNs registration failed: \(error.localizedDescription)")
        #endif
    }
}
