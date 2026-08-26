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
    var pushDetailLoading = false
    var pushDetailNotFound = false
    private var pushDetailTask: Task<Void, Never>?

    var canMarkAllReadInSelectedGroup: Bool {
        guard let group = selectedGroup else { return false }
        let groupUnread = groups.first { $0.group == group }?.unreadCount ?? 0
        return items.contains(where: \.isUnread) || groupUnread > 0
    }

    init(userRepository: UserRepository) {
        self.userRepository = userRepository
    }

    func refreshUnreadSummary() async {
        if case .success(let count) = await userRepository.getMyNotificationsUnreadCount() {
            unreadCount = count
        }
    }

    func refresh() async {
        if pushDetailLoading { return }
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
        pushDetailTask?.cancel()
        pushDetailTask = nil
        selectedGroup = nil
        items = []
        hasMore = false
        selectedDetailId = nil
        selectedDetailItem = nil
        pushDetailLoading = false
        pushDetailNotFound = false
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
        if let item = items.first(where: { $0.id == id }) ?? selectedDetailItem, item.id == id {
            selectedDetailItem = item
        }
    }

    func closeDetail() {
        pushDetailTask?.cancel()
        pushDetailTask = nil
        selectedDetailId = nil
        selectedDetailItem = nil
        pushDetailLoading = false
        pushDetailNotFound = false
    }

    /// Resolve a tray-tap / deep-link inbox id (Android `openInboxDetailFromPush`).
    func openInboxDetailFromPush(_ notificationId: String) {
        let id = notificationId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty else { return }
        if selectedDetailItem?.id == id, !pushDetailLoading { return }
        pushDetailTask?.cancel()
        selectedDetailId = id
        selectedDetailItem = items.first(where: { $0.id == id })
        pushDetailNotFound = false
        if selectedDetailItem != nil {
            pushDetailLoading = false
            if let item = selectedDetailItem {
                Task { await markReadIfNeeded(item) }
            }
            return
        }
        pushDetailLoading = true
        pushDetailTask = Task { await resolvePushDetail(id) }
    }

    private func resolvePushDetail(_ id: String) async {
        defer {
            if !Task.isCancelled {
                pushDetailLoading = false
            }
        }
        if groups.isEmpty {
            await refreshGroups()
        }
        guard !Task.isCancelled else { return }
        if let cached = items.first(where: { $0.id == id }) {
            applyResolvedPushItem(cached)
            return
        }
        guard let item = await findNotificationInInbox(id) else {
            guard !Task.isCancelled else { return }
            pushDetailNotFound = true
            return
        }
        guard !Task.isCancelled else { return }
        applyResolvedPushItem(item)
    }

    private func applyResolvedPushItem(_ item: InboxNotificationItem) {
        selectedDetailItem = item
        selectedDetailId = item.id
        pushDetailNotFound = false
        if let group = item.notificationGroup?.trimmingCharacters(in: .whitespacesAndNewlines), !group.isEmpty {
            selectedGroup = group
            Task { await loadGroupItemsForPushDetail(group: group, resolved: item) }
        }
        Task { await markReadIfNeeded(item) }
    }

    private func findNotificationInInbox(_ id: String) async -> InboxNotificationItem? {
        var beforeId: String? = nil
        for _ in 0..<Self.pushDetailMaxPages {
            guard !Task.isCancelled else { return nil }
            switch await listNotificationsWithRetry(beforeId: beforeId, group: nil) {
            case .success(let page):
                if let match = page.items.first(where: { $0.id == id }) {
                    return match
                }
                if page.items.count < Self.pageLimit { return nil }
                beforeId = page.items.last?.id
                if beforeId == nil { return nil }
            case .failure:
                return nil
            }
        }
        return nil
    }

    private func loadGroupItemsForPushDetail(group: String, resolved: InboxNotificationItem) async {
        switch await userRepository.listMyNotifications(limit: Self.pageLimit, group: group) {
        case .success(let page):
            if page.items.contains(where: { $0.id == resolved.id }) {
                items = page.items
            } else {
                items = [resolved] + page.items
            }
            hasMore = page.items.count >= Self.pageLimit
        case .failure:
            if items.isEmpty { items = [resolved] }
        }
    }

    private func listNotificationsWithRetry(beforeId: String?, group: String?) async -> Result<InboxNotificationsPage, Error> {
        var last: Result<InboxNotificationsPage, Error> = .failure(URLError(.unknown))
        for attempt in 0..<Self.inboxLoadRetryAttempts {
            let result = await userRepository.listMyNotifications(
                limit: Self.pageLimit,
                beforeId: beforeId,
                group: group
            )
            if case .success = result { return result }
            last = result
            if case .failure(let error) = result, !Self.isTransientInboxFailure(error) {
                return result
            }
            try? await Task.sleep(for: .milliseconds(Self.inboxRetryBaseDelayMs * (attempt + 1)))
        }
        return last
    }

    private static func isTransientInboxFailure(_ error: Error) -> Bool {
        if let http = error as? CoreServiceHttpException {
            return http.statusCode == 401 || http.statusCode == 408 || http.statusCode >= 500
        }
        let ns = error as NSError
        if ns.domain == NSURLErrorDomain {
            return true
        }
        let message = error.localizedDescription.lowercased()
        return message.contains("timeout") || message.contains("401") || message.contains("connection")
    }

    private static let pageLimit = 30
    private static let pushDetailMaxPages = 15
    private static let inboxLoadRetryAttempts = 4
    private static let inboxRetryBaseDelayMs = 350

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
            guard row.group == resolveInboxNotificationGroup(item), row.unreadCount > 0 else { return row }
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
