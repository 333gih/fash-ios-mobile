import Foundation
import Observation

@Observable
@MainActor
final class NotificationPreferencesViewModel {
    var prefs: NotificationPreferences?
    var isLoading = true
    var isSaving = false
    var eventMessage: String?

    func load(deps: AppDependencies) async {
        isLoading = true
        defer { isLoading = false }
        switch await deps.notificationPreferencesRepository.getNotificationPreferences() {
        case .success(let loaded):
            prefs = loaded
        case .failure:
            eventMessage = L10n.notificationPreferencesLoadError
        }
    }

    func onRecommendationPushChanged(_ enabled: Bool, deps: AppDependencies) async {
        guard var current = prefs else { return }
        current.recommendationPushEnabled = enabled
        await persist(current, deps: deps)
    }

    func onRecommendationEmailChanged(_ enabled: Bool, deps: AppDependencies) async {
        guard var current = prefs else { return }
        current.recommendationEmailEnabled = enabled
        await persist(current, deps: deps)
    }

    func onQuietHoursEnabledChanged(_ enabled: Bool, deps: AppDependencies) async {
        guard var current = prefs else { return }
        if enabled {
            current.quietHoursStart = current.quietHoursStart ?? 22
            current.quietHoursEnd = current.quietHoursEnd ?? 8
        } else {
            current.quietHoursStart = nil
            current.quietHoursEnd = nil
        }
        await persist(current, deps: deps)
    }

    func onQuietHoursStartChanged(_ hour: Int, deps: AppDependencies) async {
        guard var current = prefs else { return }
        current.quietHoursStart = min(23, max(0, hour))
        await persist(current, deps: deps)
    }

    func onQuietHoursEndChanged(_ hour: Int, deps: AppDependencies) async {
        guard var current = prefs else { return }
        current.quietHoursEnd = min(23, max(0, hour))
        await persist(current, deps: deps)
    }

    private func persist(_ next: NotificationPreferences, deps: AppDependencies) async {
        prefs = next
        isSaving = true
        defer { isSaving = false }
        switch await deps.notificationPreferencesRepository.updateNotificationPreferences(next) {
        case .success(let saved):
            prefs = saved
        case .failure:
            eventMessage = L10n.notificationPreferencesSaveError
            await load(deps: deps)
        }
    }
}
