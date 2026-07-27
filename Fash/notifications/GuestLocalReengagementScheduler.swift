import Foundation
import UserNotifications

/// Local guest re-engagement reminder — see core-service/docs/guest-local-reminder.md.
@MainActor
final class GuestLocalReengagementScheduler {
    static let shared = GuestLocalReengagementScheduler()
    static let requestId = "guest_local_reminder"
    static let eveningRequestId = "guest_local_reminder_evening"
    static let openGuestHomeKey = "fash_open"
    static let openGuestHomeValue = "guest_home"

    private let prefs = UserDefaults.standard
    private let inactiveInterval: TimeInterval = 24 * 3600
    private let nudgeCooldown: TimeInterval = 7 * 24 * 3600
    private let vnTimeZone = TimeZone(identifier: "Asia/Ho_Chi_Minh") ?? .current
    private let maxDailyReminders = 2
    private let eveningHourVN = 20

    private enum Key {
        static let lastFiredDay = "guest_reengagement.last_fired_day_vn"
        static let firedCountDay = "guest_reengagement.fired_count_day_vn"
        static let firedCount = "guest_reengagement.fired_count_today"
        static let reminderTitle = "guest_reengagement.reminder_title"
        static let reminderBody = "guest_reengagement.reminder_body"
        static let sessionCount = "guest_reengagement.browse_session_count"
        static let nudgeLastShown = "guest_reengagement.signup_nudge_last_shown"
        static let permissionPrompted = "guest_reengagement.notif_permission_prompted"
    }

    private struct ReminderVariant {
        let titleVi: String
        let bodyVi: String
        let titleEn: String
        let bodyEn: String
    }

    private let variants: [ReminderVariant] = [
        ReminderVariant(
            titleVi: "Fash đang chờ bạn",
            bodyVi: "Khám phá thêm đồ second-hand — đăng ký để nhận gợi ý riêng mỗi ngày.",
            titleEn: "Fash is waiting for you",
            bodyEn: "Discover more pre-loved fashion — sign up for daily picks made for you."
        ),
        ReminderVariant(
            titleVi: "Style mới vừa lên kệ",
            bodyVi: "Xem bộ sưu tập pre-loved hôm nay — mở Fash không cần đăng nhập.",
            titleEn: "Fresh pre-loved drops",
            bodyEn: "Browse today's curated second-hand picks — no login required."
        ),
        ReminderVariant(
            titleVi: "Mùa này mặc gì?",
            bodyVi: "Gợi ý outfit second-hand phù hợp khí hậu VN — khám phá ngay trên Fash.",
            titleEn: "What to wear this season?",
            bodyEn: "Climate-friendly pre-loved outfit ideas are waiting on Fash."
        ),
        ReminderVariant(
            titleVi: "Lưu món yêu thích",
            bodyVi: "Đăng ký miễn phí để lưu listing và nhận thông báo giảm giá.",
            titleEn: "Save what you love",
            bodyEn: "Sign up free to save listings and get price-drop alerts."
        ),
        ReminderVariant(
            titleVi: "Cộng đồng Fash đang sôi động",
            bodyVi: "Người bán C2C đang đăng hàng mới — ghé xem trước khi hết size.",
            titleEn: "Fash community is buzzing",
            bodyEn: "C2C sellers just listed new pieces — browse before they're gone."
        ),
        ReminderVariant(
            titleVi: "Deal second-hand hôm nay",
            bodyVi: "Món đẹp, giá tốt — mở Fash khám phá kho pre-loved gần bạn.",
            titleEn: "Today's pre-loved deals",
            bodyEn: "Great style, better prices — explore pre-loved near you on Fash."
        ),
    ]

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
        if !cached.isEmpty { return cached }
        return pickVariant().titleVi
    }

    func reminderBody() -> String {
        let cached = prefs.string(forKey: Key.reminderBody)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if !cached.isEmpty { return cached }
        return pickVariant().bodyVi
    }

    private func pickVariant() -> ReminderVariant {
        let session = prefs.integer(forKey: Key.sessionCount)
        let hour = vnHour()
        let idx = (session + hour + Calendar.current.component(.day, from: Date())) % variants.count
        let v = variants[max(0, idx)]
        let isEn = Locale.current.language.languageCode?.identifier == "en"
        if isEn {
            return ReminderVariant(titleVi: v.titleEn, bodyVi: v.bodyEn, titleEn: v.titleEn, bodyEn: v.bodyEn)
        }
        return v
    }

    private func vnHour() -> Int {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = vnTimeZone
        return cal.component(.hour, from: Date())
    }

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
        center.removePendingNotificationRequests(withIdentifiers: [Self.requestId, Self.eveningRequestId])

        let variant = pickVariant()
        let content = UNMutableNotificationContent()
        content.title = variant.titleVi
        content.body = variant.bodyVi
        content.sound = .default
        content.userInfo = [Self.openGuestHomeKey: Self.openGuestHomeValue]
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: inactiveInterval, repeats: false)
        let request = UNNotificationRequest(identifier: Self.requestId, content: content, trigger: trigger)
        try? await center.add(request)

        if remainingToday() > 0 {
            await scheduleEveningSlot(center: center, variant: pickVariant())
        }
    }

    private func scheduleEveningSlot(center: UNUserNotificationCenter, variant: ReminderVariant) async {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = vnTimeZone
        let now = Date()
        var comps = cal.dateComponents([.year, .month, .day], from: now)
        comps.hour = eveningHourVN
        comps.minute = 0
        guard var fireDate = cal.date(from: comps) else { return }
        if fireDate <= now {
            fireDate = cal.date(byAdding: .day, value: 1, to: fireDate) ?? fireDate
        }
        let content = UNMutableNotificationContent()
        content.title = variant.titleVi
        content.body = variant.bodyVi
        content.sound = .default
        content.userInfo = [Self.openGuestHomeKey: Self.openGuestHomeValue]
        let triggerComps = cal.dateComponents([.year, .month, .day, .hour, .minute], from: fireDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComps, repeats: false)
        let request = UNNotificationRequest(identifier: Self.eveningRequestId, content: content, trigger: trigger)
        try? await center.add(request)
    }

    func cancelPending() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [Self.requestId, Self.eveningRequestId]
        )
    }

    func clearGuestState() {
        cancelPending()
        prefs.removeObject(forKey: Key.reminderTitle)
        prefs.removeObject(forKey: Key.reminderBody)
        prefs.removeObject(forKey: Key.firedCount)
        prefs.removeObject(forKey: Key.firedCountDay)
    }

    func canFireToday() -> Bool {
        remainingToday() > 0
    }

    private func remainingToday() -> Int {
        resetDailyCountIfNeeded()
        let count = prefs.integer(forKey: Key.firedCount)
        return max(0, maxDailyReminders - count)
    }

    func markFiredToday() {
        resetDailyCountIfNeeded()
        let count = prefs.integer(forKey: Key.firedCount) + 1
        prefs.set(count, forKey: Key.firedCount)
        prefs.set(Self.vnDayString(), forKey: Key.lastFiredDay)
        prefs.set(Self.vnDayString(), forKey: Key.firedCountDay)
    }

    private func resetDailyCountIfNeeded() {
        let today = Self.vnDayString()
        if prefs.string(forKey: Key.firedCountDay) != today {
            prefs.set(0, forKey: Key.firedCount)
            prefs.set(today, forKey: Key.firedCountDay)
        }
    }

    func syncDeliveredCap() async {
        let center = UNUserNotificationCenter.current()
        let delivered = await center.deliveredNotifications()
        let ids = Set([Self.requestId, Self.eveningRequestId])
        guard delivered.contains(where: { ids.contains($0.request.identifier) }) else { return }
        if canFireToday() {
            markFiredToday()
        }
    }

    func presentationOptionsForLocalReminder(willPresent notification: UNNotification) async -> UNNotificationPresentationOptions? {
        let id = notification.request.identifier
        guard id == Self.requestId || id == Self.eveningRequestId else { return nil }
        if !canFireToday() {
            let center = UNUserNotificationCenter.current()
            center.removeDeliveredNotifications(withIdentifiers: [id])
            center.removePendingNotificationRequests(withIdentifiers: [id])
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
