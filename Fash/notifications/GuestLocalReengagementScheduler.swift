import Foundation
import UserNotifications

/// Local guest re-engagement reminder — see core-service/docs/guest-local-reminder.md.
@MainActor
final class GuestLocalReengagementScheduler {
    static let shared = GuestLocalReengagementScheduler()

    private let requestId = "guest_local_reminder"
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

    func requestAuthorizationIfNeeded() async {
        guard !wasNotificationPermissionPrompted else { return }
        markNotificationPermissionPrompted()
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
    }

    func scheduleAfterBackground() async {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        guard settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional else {
            return
        }
        center.removePendingNotificationRequests(withIdentifiers: [requestId])
        let content = UNMutableNotificationContent()
        content.title = reminderTitle()
        content.body = reminderBody()
        content.sound = .default
        content.userInfo = ["fash_open": "guest_home"]
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: inactiveInterval, repeats: false)
        let request = UNNotificationRequest(identifier: requestId, content: content, trigger: trigger)
        try? await center.add(request)
    }

    func cancelPending() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [requestId])
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

    private static func vnDayString() -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}
