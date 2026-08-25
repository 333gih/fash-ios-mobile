import Foundation
import Observation

/// Observable port of Android `FeaturedSellersViewModel` (ui.explore).
@Observable
@MainActor
final class FeaturedSellersViewModel {
    var items: [FeaturedSellerItem] = []
    var isLoading = false
    var loadError = false
    var loadErrorDetail: String?
    var isRefreshing = false
    var isLoadingMore = false
    var hasMore = false
    var totalCount = 0
    var previewCoverUrlsBySellerKey: [String: [String?]] = [:]

    private var seenKeys = Set<String>()
    private var nextOffset = 0
    private var lastLoadedAt: Date?

    private static let pageSize = 20
    private static let memoryCacheTTL: TimeInterval = 60

    func ensureLoaded(deps: AppDependencies, isGuestMode: Bool) async {
        guard !isLoading, !isRefreshing else { return }
        if !items.isEmpty, let last = lastLoadedAt, Date().timeIntervalSince(last) < Self.memoryCacheTTL {
            return
        }
        if items.isEmpty {
            await load(deps: deps, isGuestMode: isGuestMode)
        } else {
            await refresh(deps: deps, isGuestMode: isGuestMode)
        }
    }

    func load(deps: AppDependencies, isGuestMode: Bool) async {
        isLoading = true
        loadError = false
        loadErrorDetail = nil
        defer { isLoading = false }

        switch await fetchPage(deps: deps, isGuestMode: isGuestMode, offset: 0) {
        case .success(let page):
            nextOffset = 0
            merge(page: page, replace: true)
        case .failure(let error):
            items = []
            totalCount = 0
            hasMore = false
            nextOffset = 0
            seenKeys.removeAll()
            loadError = true
            loadErrorDetail = FashErrorPresentation.userMessage(for: error)
        }
    }

    func refresh(deps: AppDependencies, isGuestMode: Bool) async {
        isRefreshing = true
        loadError = false
        loadErrorDetail = nil
        defer { isRefreshing = false }

        switch await fetchPage(deps: deps, isGuestMode: isGuestMode, offset: 0) {
        case .success(let page):
            nextOffset = 0
            merge(page: page, replace: true)
            previewCoverUrlsBySellerKey = [:]
        case .failure(let error):
            loadError = true
            loadErrorDetail = FashErrorPresentation.userMessage(for: error)
        }
    }

    func loadMore(deps: AppDependencies, isGuestMode: Bool) async {
        guard hasMore, !isLoadingMore, !isLoading, !isRefreshing else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        let offset = nextOffset
        switch await fetchPage(deps: deps, isGuestMode: isGuestMode, offset: offset) {
        case .success(let page):
            merge(page: page, replace: false)
        case .failure:
            hasMore = false
        }
    }

    func clearCachesForSignedOutUser() {
        items = []
        previewCoverUrlsBySellerKey = [:]
        loadError = false
        loadErrorDetail = nil
        isLoading = false
        isRefreshing = false
        isLoadingMore = false
        hasMore = false
        totalCount = 0
        nextOffset = 0
        lastLoadedAt = nil
        seenKeys.removeAll()
    }

    func ensurePreviewCoversLoaded(_ seller: FeaturedSellerItem, deps: AppDependencies, isGuestMode: Bool) async {
        let key = seller.sellerKey
        guard !key.isEmpty, previewCoverUrlsBySellerKey[key] == nil else { return }

        var urls: [String?] = []
        for listingId in seller.previewListingIds.prefix(3) {
            let trimmed = listingId.trimmingCharacters(in: .whitespaces)
            if trimmed.isEmpty {
                urls.append(nil)
                continue
            }
            let cover: String?
            switch await deps.listingRepository.getListingDetail(listingId: trimmed, publicBrowse: isGuestMode) {
            case .success(let item):
                let url = item.coverImageUrl.trimmingCharacters(in: .whitespaces)
                let firstImage = item.imageUrls.first?.trimmingCharacters(in: .whitespaces) ?? ""
                cover = url.isEmpty ? (firstImage.isEmpty ? nil : firstImage) : url
            case .failure:
                cover = nil
            }
            urls.append(cover)
        }
        previewCoverUrlsBySellerKey[key] = urls
    }

    private func fetchPage(
        deps: AppDependencies,
        isGuestMode: Bool,
        offset: Int
    ) async -> Result<FeaturedSellersPage, Error> {
        if isGuestMode {
            return await deps.searchRepository.browseFeaturedSellersPage(limit: Self.pageSize, offset: offset)
        }
        return await deps.searchRepository.getFeaturedSellersPage(limit: Self.pageSize, offset: offset)
    }

    private func merge(page: FeaturedSellersPage, replace: Bool) {
        if replace { seenKeys.removeAll() }
        var acc = replace ? [FeaturedSellerItem]() : items
        for seller in page.items where seller.isShopReady {
            let key = seller.sellerKey
            guard !key.isEmpty, seenKeys.insert(key).inserted else { continue }
            acc.append(seller)
        }
        items = acc
        totalCount = page.total
        nextOffset += page.items.count
        hasMore = page.items.count >= Self.pageSize && (page.total <= 0 || nextOffset < page.total)
        lastLoadedAt = Date()
    }
}
