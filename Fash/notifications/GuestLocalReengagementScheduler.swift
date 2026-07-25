import Foundation
import UserNotifications

/// Local guest re-engagement reminder — see core-service/docs/guest-local-reminder.md.
@MainActor
final class GuestLocalReengagementScheduler {
    static let shared = GuestLocalReengagementScheduler()
    static let requestId = "guest_local_reminder"
    static let openGuestHomeKey = "fash_open"
    static let openGuestHomeValue = "guest_home"

    private let prefs = UserDefaults.standard
    private let inactiveInterval: TimeInterval = 24 * 3600
    private let nudgeCooldown: TimeInterval = 7 * 24 * 3600
    private let vnTimeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh") ?? .current

    private enum Key {
        static let lastFiredDay = "guest_reengagement.last_fired_day_vn"
        static let reminderTitle = "guest_reengagement.reminder_title"
        static let reminderBody = "guest_reengagement.reminder_body"
        static let sessionCount = "guest_reengagement.browse_session_count"
        static let nudgeLastShown = "guest_reengagement.signup_nudge_last_shown"
        static let permissionPrompted = "guest_reengagement.notif_permission_prompted"
    }

    func onGuestShellEntered() -> Int {
        let next = prefs.integer(forKey: Key.sessionCount) + 1
        prefs.set(next, forKey: Key.sessionCount)
        return next
    }

    func shouldShowSignupNudge() -> Bool {
        guard prefs.integer(forKey: Key.sessionCount) >= 2 else { return false }
        let last = prefs.double(forKey: Key.nudgeLastShown)
        return Date().timeIntervalSince1970 - last >= nudgeCooldown
    }

    func markSignupNudgeShown() {
        prefs.set(Date().timeIntervalSince1970, forKey: Key.nudgeLastShown)
    }

    var wasNotificationPermissionPrompted: Bool {
        prefs.bool(forKey: Key.permissionPrompted)
    }

    func markNotificationPermissionPrompted() {
        prefs.set(true, forKey: Key.permissionPrompted)
    }

    func updateReminderCopy(title: String?, body: String?) {
        if let title, !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            prefs.set(title.trimmingCharacters(in: .whitespacesAndNewlines), forKey: Key.reminderTitle)
        }
        if let body, !body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            prefs.set(body.trimmingCharacters(in: .whitespacesAndNewlines), forKey: Key.reminderBody)
        }
    }

    func reminderTitle() -> String {
        let cached = prefs.string(forKey: Key.reminderTitle)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return cached.isEmpty ? L10n.guestLocalReminderTitle : cached
    }

    func reminderBody() -> String {
        let cached = prefs.string(forKey: Key.reminderBody)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return cached.isEmpty ? L10n.guestLocalReminderBody : cached
    }

    /// Prompt once, then register for remote/local delivery and schedule if already authorized.
    func requestAuthorizationIfNeeded() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            await scheduleAfterBackground()
            return
        case .denied:
            return
        default:
            break
        }
        guard !wasNotificationPermissionPrompted else { return }
        markNotificationPermissionPrompted()
        let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
        if granted {
            await scheduleAfterBackground()
        }
    }

    func scheduleAfterBackground() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
            return
        }
        center.removePendingNotificationRequests(withIdentifiers: [Self.requestId])
        let content = UNMutableNotificationContent()
        content.title = reminderTitle()
        content.body = reminderBody()
        content.sound = .default
        content.userInfo = [Self.openGuestHomeKey: Self.openGuestHomeValue]
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: inactiveInterval, repeats: false)
        let request = UNNotificationRequest(identifier: Self.requestId, content: content, trigger: trigger)
        try? await center.add(request)
    }

    func cancelPending() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [Self.requestId])
    }

    func clearGuestState() {
        cancelPending()
        prefs.removeObject(forKey: Key.reminderTitle)
        prefs.removeObject(forKey: Key.reminderBody)
    }

    func canFireToday() -> Bool {
        let today = Self.vnDayString()
        return prefs.string(forKey: Key.lastFiredDay) != today
    }

    func markFiredToday() {
        prefs.set(Self.vnDayString(), forKey: Key.lastFiredDay)
    }

    /// Marks daily cap when a guest reminder was delivered while the app was backgrounded.
    func syncDeliveredCap() async {
        let center = UNUserNotificationCenter.current()
        let delivered = await center.deliveredNotifications()
        guard delivered.contains(where: { $0.request.identifier == Self.requestId }) else { return }
        if canFireToday() {
            markFiredToday()
        }
    }

    /// Returns presentation options for guest local reminder; suppresses when daily cap hit.
    func presentationOptionsForLocalReminder(willPresent notification: UNNotification) async -> UNNotificationPresentationOptions? {
        guard notification.request.identifier == Self.requestId else { return nil }
        if !canFireToday() {
            let center = UNUserNotificationCenter.current()
            center.removeDeliveredNotifications(withIdentifiers: [Self.requestId])
            center.removePendingNotificationRequests(withIdentifiers: [Self.requestId])
            await scheduleAfterBackground()
            return []
        }
        markFiredToday()
        await scheduleAfterBackground()
        return [.banner, .list, .sound, .badge]
    }

    func handleGuestOpenPayload(_ userInfo: [AnyHashable: Any]) -> Bool {
        guard let raw = userInfo[Self.openGuestHomeKey] as? String,
              raw.trimmingCharacters(in: .whitespacesAndNewlines) == Self.openGuestHomeValue else {
            return false
        }
        let deps = AppDependencies.shared
        deps.isGuestBrowseActive = true
        deps.navigationRouter?.isGuestMode = true
        markFiredToday()
        Task { await scheduleAfterBackground() }
        return true
    }

    private static func vnDayString() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
