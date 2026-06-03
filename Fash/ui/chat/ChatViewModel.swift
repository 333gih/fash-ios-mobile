import Foundation
import Observation

enum ChatFilter: Equatable {
    case all
    case unread
    case seller
    case buyer
}

enum SellerInboxGroupMode: Equatable {
    case allConversations
    case byProduct
}

@Observable
@MainActor
final class ChatViewModel {
    private var allConversations: [ConversationItem] = []
    private var conversationGroups: [ConversationListingGroup] = []
    private var myUserId: String = ""

    var conversations: [ConversationItem] = []
    var displayGroups: [ConversationListingGroup] = []
    var expandedGroupListingIds: Set<String> = []
    var selectedFilter: ChatFilter = .all
    var sellerInboxGroupMode: SellerInboxGroupMode = .allConversations
    var sellerHasActiveListings = false

    var isLoading = false
    var isRefreshing = false
    private(set) var chatScrollToTopToken = 0

    func requestScrollChatToTop() {
        chatScrollToTopToken &+= 1
    }
    var loadError = false
    var unreadTotal = 0

    private var lastSuccessfulInboxFetchMs: UInt64 = 0

    var conversationIds: [String] { conversations.map(\.conversationId) }

    private func isGroupedInbox() -> Bool {
        sellerHasActiveListings && sellerInboxGroupMode == .byProduct
    }

    func loadConversationsWhenNeeded(deps: AppDependencies, staleAfterMs: UInt64 = 60_000) async {
        if loadError {
            await loadConversations(deps: deps)
            return
        }
        let now = DispatchTime.now().uptimeNanoseconds / 1_000_000
        let everFetched = lastSuccessfulInboxFetchMs > 0
        let stale = (now - lastSuccessfulInboxFetchMs) >= staleAfterMs
        if everFetched, !stale { return }
        await loadConversations(deps: deps)
    }

    func loadConversations(deps: AppDependencies) async {
        myUserId = deps.chatRepository.currentUserId
        isLoading = true
        loadError = false
        defer { isLoading = false }

        await refreshSellerListingEligibility(deps: deps)
        var fetchSucceeded = false

        if isGroupedInbox() {
            switch await deps.chatRepository.getConversationsGroupedByListing() {
            case .success(let groups):
                fetchSucceeded = true
                conversationGroups = groups
                expandedGroupListingIds = Set(groups.map(\.listingId))
                applyCurrentViewFilter()
                syncConversationRoomSubscriptions(deps: deps, from: groups.flatMap(\.conversations))
            case .failure:
                loadError = true
            }
        } else {
            switch await deps.chatRepository.getConversations() {
            case .success(let list):
                fetchSucceeded = true
                allConversations = list
                applyCurrentViewFilter()
                syncConversationRoomSubscriptions(deps: deps, from: list)
            case .failure:
                loadError = true
            }
        }

        if fetchSucceeded {
            lastSuccessfulInboxFetchMs = DispatchTime.now().uptimeNanoseconds / 1_000_000
        }
        await refreshUnreadCount(deps: deps)
    }

    func refresh(deps: AppDependencies) async {
        myUserId = deps.chatRepository.currentUserId
        isLoading = true
        loadError = false
        defer { isLoading = false }
        await refreshSellerListingEligibility(deps: deps)
        await silentRefreshConversations(deps: deps)
        await refreshUnreadCount(deps: deps)
    }

    func pullToRefresh(deps: AppDependencies) async {
        myUserId = deps.chatRepository.currentUserId
        requestScrollChatToTop()
        isRefreshing = true
        defer { isRefreshing = false }
        await silentRefreshConversations(deps: deps)
        await refreshUnreadCount(deps: deps)
    }

    func silentRefresh(deps: AppDependencies) async {
        myUserId = deps.chatRepository.currentUserId
        await silentRefreshConversations(deps: deps)
        await refreshUnreadCount(deps: deps)
    }

    private func silentRefreshConversations(deps: AppDependencies) async {
        if isGroupedInbox() {
            if case .success(let groups) = await deps.chatRepository.getConversationsGroupedByListing() {
                conversationGroups = groups
                if expandedGroupListingIds.isEmpty {
                    expandedGroupListingIds = Set(groups.map(\.listingId))
                }
                syncConversationRoomSubscriptions(deps: deps, from: groups.flatMap(\.conversations))
                applyCurrentViewFilter()
                loadError = false
            }
        } else if case .success(let list) = await deps.chatRepository.getConversations() {
            allConversations = list
            applyCurrentViewFilter()
            syncConversationRoomSubscriptions(deps: deps, from: list)
            loadError = false
        }
    }

    func resyncConversationSubscriptions(deps: AppDependencies) async {
        let items = isGroupedInbox()
            ? conversationGroups.flatMap(\.conversations)
            : allConversations
        syncConversationRoomSubscriptions(deps: deps, from: items)
    }

    private func syncConversationRoomSubscriptions(deps: AppDependencies, from items: [ConversationItem]) {
        for id in items.prefix(50).map(\.conversationId) where !id.isEmpty {
            deps.realtimeManager.subscribeToConversation(id)
        }
    }

    func refreshSellerListingEligibility(deps: AppDependencies) async {
        let userId = deps.chatRepository.currentUserId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userId.isEmpty else {
            sellerHasActiveListings = false
            return
        }
        switch await deps.listingRepository.getListingsBySeller(sellerId: userId, status: "active", limit: 1, offset: 0) {
        case .success(let list):
            sellerHasActiveListings = !list.isEmpty
        case .failure:
            sellerHasActiveListings = false
        }
    }

    func refreshUnreadCount(deps: AppDependencies) async {
        if case .success(let count) = await deps.chatRepository.getUnreadCount() {
            unreadTotal = count
        }
        publishUnreadSnapshot(to: deps)
    }

    func publishUnreadSnapshot(to deps: AppDependencies) {
        var map: [String: Int] = [:]
        for item in allConversations where !item.conversationId.isEmpty {
            map[item.conversationId] = item.unreadCount
        }
        for group in conversationGroups {
            for item in group.conversations where !item.conversationId.isEmpty {
                map[item.conversationId] = item.unreadCount
            }
        }
        deps.updateChatUnreadSnapshot(total: unreadTotal, perConversation: map)
    }

    func setFilter(_ filter: ChatFilter) {
        selectedFilter = filter
        applyCurrentViewFilter()
    }

    func setSellerInboxGroupMode(_ mode: SellerInboxGroupMode, deps: AppDependencies) async {
        guard sellerInboxGroupMode != mode else { return }
        sellerInboxGroupMode = mode
        loadError = false
        await silentRefreshConversations(deps: deps)
        await refreshUnreadCount(deps: deps)
    }

    func toggleListingGroupExpanded(_ listingId: String) {
        if expandedGroupListingIds.contains(listingId) {
            expandedGroupListingIds.remove(listingId)
        } else {
            expandedGroupListingIds.insert(listingId)
        }
    }

    func clearCachesForSignedOutUser() {
        lastSuccessfulInboxFetchMs = 0
        myUserId = ""
        allConversations = []
        conversationGroups = []
        conversations = []
        displayGroups = []
        expandedGroupListingIds = []
        unreadTotal = 0
        loadError = false
        isLoading = false
        isRefreshing = false
        sellerHasActiveListings = false
        sellerInboxGroupMode = .allConversations
        selectedFilter = .all
        AppDependencies.shared.updateChatUnreadSnapshot(total: 0, perConversation: [:])
    }

    private func applyCurrentViewFilter() {
        if isGroupedInbox() {
            applyGroupFilter(selectedFilter, conversationGroups)
        } else {
            displayGroups = []
            applyFilter(selectedFilter, allConversations)
        }
    }

    private func applyFilter(_ filter: ChatFilter, _ all: [ConversationItem]) {
        conversations = switch filter {
        case .all: all
        case .unread: all.filter(\.hasUnread)
        case .seller: myUserId.isEmpty ? all : all.filter { $0.sellerUserId == myUserId }
        case .buyer: myUserId.isEmpty ? all : all.filter { $0.buyerUserId == myUserId }
        }
    }

    private func applyGroupFilter(_ filter: ChatFilter, _ groups: [ConversationListingGroup]) {
        func passItem(_ item: ConversationItem) -> Bool {
            switch filter {
            case .all: return true
            case .unread: return item.hasUnread
            case .seller: return myUserId.isEmpty || item.sellerUserId == myUserId
            case .buyer: return myUserId.isEmpty || item.buyerUserId == myUserId
            }
        }
        displayGroups = groups.compactMap { g in
            let convs = g.conversations.filter(passItem)
            guard !convs.isEmpty else { return nil }
            return ConversationListingGroup(
                listingId: g.listingId,
                coverImageUrl: g.coverImageUrl,
                title: g.title,
                priceVnd: g.priceVnd,
                conversations: convs,
                conversationCountBadge: convs.count
            )
        }
    }

    func formatTimestamp(_ raw: String) -> String {
        ChatTimestampFormat.format(raw)
    }

    func formatPriceVnd(_ amount: Int64) -> String {
        FeedPriceFormat.format(amount)
    }

    func conversationPreviewLine(_ item: ConversationItem) -> String {
        ChatInboxPreview.conversationPreviewLine(item, myUserId: myUserId)
    }

    func conversationPreviewIsPlaceholder(_ item: ConversationItem) -> Bool {
        ChatInboxPreview.conversationPreviewIsPlaceholder(item, myUserId: myUserId)
    }

    func unreadCountForConversation(_ conversationId: String) -> Int {
        let cid = conversationId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cid.isEmpty else { return 0 }
        if let row = allConversations.first(where: { $0.conversationId == cid }) {
            return row.unreadCount
        }
        return conversationGroups
            .flatMap(\.conversations)
            .first(where: { $0.conversationId == cid })?
            .unreadCount ?? 0
    }

    func unreadCountExcludingConversation(_ conversationId: String) -> Int {
        max(0, unreadTotal - unreadCountForConversation(conversationId))
    }

    /// Display label for in-app chat toasts — prefers display name, then @username.
    func peerLabel(forConversationId conversationId: String) -> String? {
        let cid = conversationId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cid.isEmpty else { return nil }
        if let item = allConversations.first(where: {
            $0.conversationId.compare(cid, options: .caseInsensitive) == .orderedSame
        }) {
            return peerLabel(for: item)
        }
        if let item = conversationGroups
            .flatMap(\.conversations)
            .first(where: { $0.conversationId.compare(cid, options: .caseInsensitive) == .orderedSame }) {
            return peerLabel(for: item)
        }
        return nil
    }

    func peerLabel(forOtherUserId userId: String) -> String? {
        let uid = userId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !uid.isEmpty else { return nil }
        if let item = allConversations.first(where: {
            $0.otherUserId.compare(uid, options: .caseInsensitive) == .orderedSame
        }) {
            return peerLabel(for: item)
        }
        if let item = conversationGroups
            .flatMap(\.conversations)
            .first(where: { $0.otherUserId.compare(uid, options: .caseInsensitive) == .orderedSame }) {
            return peerLabel(for: item)
        }
        return nil
    }

    private func peerLabel(for item: ConversationItem) -> String? {
        let name = item.displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty { return name }
        let user = item.username.trimmingCharacters(in: .whitespacesAndNewlines)
        if user.isEmpty { return nil }
        return user.hasPrefix("@") ? user : "@\(user)"
    }
}
