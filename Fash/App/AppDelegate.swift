import UIKit
import UserNotifications
import Kingfisher

/// Firebase + APNs lifecycle — mirrors personal-os `POSAppDelegate`.
/// Transport (FCM vs pure APNs) is decided at runtime by `PushNotificationCoordinator` via `USE_FIREBASE_MESSAGING`.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        configureKingfisherCache()
        PushNotificationCoordinator.configureMessagingIfNeeded()
        SentryBootstrap.configureIfNeeded()
        Task { @MainActor in
            await PushNotificationCoordinator.shared.syncRemoteNotificationRegistrationOnLaunch()
        }
        return true
    }
    
    private func configureKingfisherCache() {
        // Memory cache: 100MB total, max 150 images
        ImageCache.default.memoryStorage.config.totalCostLimit = 100 * 1024 * 1024
        ImageCache.default.memoryStorage.config.countLimit = 150
        
        // Disk cache: 500MB max
        ImageCache.default.diskStorage.config.sizeLimit = 500 * 1024 * 1024
        
        // Cache expiration: 7 days for disk
        ImageCache.default.diskStorage.config.expiration = .days(7)
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
            FashFirebaseMessagingService.handleForegroundNotification(userInfo: userInfo)
            completionHandler(.newData)
        }
    }
}
