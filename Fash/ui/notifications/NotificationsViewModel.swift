import Foundation
import Observation

@Observable
@MainActor
final class NotificationsViewModel {
    private let userRepository: UserRepository

    var groups: [NotificationGroupSummaryItem] = []
    var selectedGroup: String?
    var items: [InboxNotificationItem] = []
    var isLoading = false
    var isRefreshing = false
    var loadMoreBusy = false
    var hasMore = false
    var loadError: String?
    var inboxUnavailable = false
    var selectedDetailId: String?
    var selectedDetailItem: InboxNotificationItem?
    var unreadCount = 0
    var markAllReadBusy = false

    var canMarkAllReadInSelectedGroup: Bool {
        guard let group = selectedGroup else { return false }
        let groupUnread = groups.first { $0.group == group }?.unreadCount ?? 0
        return items.contains(where: \.isUnread) || groupUnread > 0
    }

    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }

    func refreshUnreadSummary() async {
        unreadCount = (try? await userRepository.getMyNotificationsUnreadCount().get()) ?? 0
    }

    func refresh() async {
        if selectedGroup == nil {
            await refreshGroups()
        } else {
            await refreshGroupItems()
        }
    }

    func openGroup(_ group: String) {
        selectedGroup = group
        items = []
        hasMore = false
        Task { await refreshGroupItems() }
    }

    func closeGroup() {
        selectedGroup = nil
        items = []
        hasMore = false
        selectedDetailId = nil
        Task { await refreshGroups() }
    }

    func markAllRead() async {
        guard !markAllReadBusy, !inboxUnavailable else { return }
        guard let group = selectedGroup?.trimmingCharacters(in: .whitespaces), !group.isEmpty else { return }
        let groupUnread = groups.first { $0.group == group }?.unreadCount ?? 0
        guard items.contains(where: \.isUnread) || groupUnread > 0 else { return }
        markAllReadBusy = true
        defer { markAllReadBusy = false }
        let result = await userRepository.markAllNotificationsRead(group: group)
        if case .success = result {
            let stamp = ISO8601DateFormatter().string(from: Date())
            items = items.map { $0.readAtIso == nil ? InboxNotificationItem(
                id: $0.id, title: $0.title, body: $0.body, dataMap: $0.dataMap,
                payloadType: $0.payloadType, notificationGroup: $0.notificationGroup,
                source: $0.source, sourceEventId: $0.sourceEventId, readAtIso: stamp, createdAtIso: $0.createdAtIso
            ) : $0 }
            groups = groups.map { row in
                row.group == group ? NotificationGroupSummaryItem(
                    group: row.group,
                    unreadCount: 0,
                    latestId: row.latestId,
                    latestTitle: row.latestTitle,
                    latestBody: row.latestBody,
                    latestCreatedAtIso: row.latestCreatedAtIso
                ) : row
            }
            await refreshUnreadSummary()
            await refreshGroups()
        }
    }

    private func refreshGroups() async {
        if groups.isEmpty { isLoading = true } else { isRefreshing = true }
        defer { isLoading = false; isRefreshing = false }
        loadError = nil
        inboxUnavailable = false
        switch await userRepository.listMyNotificationGroups() {
        case .success(let page):
            groups = mergeGroupSummaries(page.groups)
            await refreshUnreadSummary()
        case .failure(let error):
            if isInboxUnavailable(error) {
                loadError = L10n.notificationInboxUnavailableSubtitle
                inboxUnavailable = true
            } else {
                loadError = FashErrorPresentation.userMessage(for: error)
                inboxUnavailable = false
            }
            groups = []
        }
    }

    private func isInboxUnavailable(_ error: Error) -> Bool {
        if let http = error as? CoreServiceHttpException {
            return http.statusCode == 503 || http.statusCode == 404
        }
        let message = FashErrorPresentation.userMessage(for: error)
        return message.contains("503") || message.contains("404")
    }

    private func refreshGroupItems() async {
        guard let group = selectedGroup else { return }
        if items.isEmpty { isLoading = true } else { isRefreshing = true }
        defer { isLoading = false; isRefreshing = false }
        loadError = nil
        inboxUnavailable = false
        switch await userRepository.listMyNotifications(limit: 30, group: group) {
        case .success(let page):
            items = page.items
            hasMore = page.items.count >= 30
            await refreshUnreadSummary()
        case .failure(let error):
            loadError = FashErrorPresentation.userMessage(for: error)
            items = []
            hasMore = false
        }
    }

    private func mergeGroupSummaries(_ serverGroups: [NotificationGroupSummaryItem]) -> [NotificationGroupSummaryItem] {
        let byGroup = Dictionary(uniqueKeysWithValues: serverGroups.map { ($0.group, $0) })
        let merged = NotificationGroups.displayOrder.map { code in
            byGroup[code] ?? NotificationGroupSummaryItem(
                group: code, unreadCount: 0, latestId: nil, latestTitle: nil, latestBody: nil, latestCreatedAtIso: nil
            )
        }
        return merged
    }

    func loadMore() async {
        guard let group = selectedGroup, let last = items.last, hasMore, !loadMoreBusy, !isLoading else { return }
        loadMoreBusy = true
        defer { loadMoreBusy = false }
        switch await userRepository.listMyNotifications(limit: 30, beforeId: last.id, group: group) {
        case .success(let page):
            let have = Set(items.map(\.id))
            items.append(contentsOf: page.items.filter { !have.contains($0.id) })
            hasMore = page.items.count >= 30
        case .failure:
            break
        }
    }

    func openDetail(_ item: InboxNotificationItem) {
        selectedDetailId = item.id
        selectedDetailItem = item
    }

    func openDetail(_ id: String) {
        selectedDetailId = id
        if let item = items.first(where: { $0.id == id }) {
            selectedDetailItem = item
        }
    }

    func closeDetail() {
        selectedDetailId = nil
        selectedDetailItem = nil
    }

    func markReadIfNeeded(_ item: InboxNotificationItem) async {
        guard item.isUnread else { return }
        guard case .success = await userRepository.markNotificationRead(notificationId: item.id) else { return }
        let stamp = ISO8601DateFormatter().string(from: Date())
        items = items.map { row in
            row.id == item.id ? InboxNotificationItem(
                id: row.id, title: row.title, body: row.body, dataMap: row.dataMap,
                payloadType: row.payloadType, notificationGroup: row.notificationGroup,
                source: row.source, sourceEventId: row.sourceEventId, readAtIso: stamp, createdAtIso: row.createdAtIso
            ) : row
        }
        groups = groups.map { row in
            guard row.group == item.notificationGroup, row.unreadCount > 0 else { return row }
            return NotificationGroupSummaryItem(
                group: row.group,
                unreadCount: max(0, row.unreadCount - 1),
                latestId: row.latestId,
                latestTitle: row.latestTitle,
                latestBody: row.latestBody,
                latestCreatedAtIso: row.latestCreatedAtIso
            )
        }
        await refreshUnreadSummary()
    }
}
