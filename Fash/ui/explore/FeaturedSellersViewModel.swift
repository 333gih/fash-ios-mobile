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
    var totalCount = 0
    var previewCoverUrlsBySellerKey: [String: [String?]] = [:]

    /// Android `ReloadWhenVisible` + `refresh()` when the see-all overlay opens.
    func reloadOnPresent(deps: AppDependencies, isGuestMode: Bool) async {
        guard !isLoading, !isRefreshing else { return }
        await refresh(deps: deps, isGuestMode: isGuestMode)
    }

    func ensureLoaded(deps: AppDependencies, isGuestMode: Bool) async {
        guard items.isEmpty else { return }
        guard !isLoading, !isRefreshing else { return }
        await load(deps: deps, isGuestMode: isGuestMode)
    }

    func load(deps: AppDependencies, isGuestMode: Bool) async {
        isLoading = true
        loadError = false
        loadErrorDetail = nil
        defer { isLoading = false }

        switch await loadAllPages(deps: deps, isGuestMode: isGuestMode) {
        case .success(let result):
            items = result.items
            totalCount = result.total
        case .failure(let error):
            items = []
            totalCount = 0
            loadError = true
            loadErrorDetail = FashErrorPresentation.userMessage(for: error)
        }
    }

    func refresh(deps: AppDependencies, isGuestMode: Bool) async {
        isRefreshing = true
        loadError = false
        loadErrorDetail = nil
        defer { isRefreshing = false }

        switch await loadAllPages(deps: deps, isGuestMode: isGuestMode) {
        case .success(let result):
            items = result.items
            totalCount = result.total
            previewCoverUrlsBySellerKey = [:]
        case .failure(let error):
            loadError = true
            loadErrorDetail = FashErrorPresentation.userMessage(for: error)
        }
    }

    func clearCachesForSignedOutUser() {
        items = []
        previewCoverUrlsBySellerKey = [:]
        loadError = false
        loadErrorDetail = nil
        isLoading = false
        isRefreshing = false
        totalCount = 0
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

    private func loadAllPages(deps: AppDependencies, isGuestMode: Bool) async -> Result<(items: [FeaturedSellerItem], total: Int), Error> {
        let pageSize = 50
        var accumulated: [FeaturedSellerItem] = []
        var seen = Set<String>()
        var offset = 0
        var total = 0

        while true {
            let pageResult: Result<FeaturedSellersPage, Error>
            if isGuestMode {
                pageResult = await deps.searchRepository.browseFeaturedSellersPage(limit: pageSize, offset: offset)
            } else {
                pageResult = await deps.searchRepository.getFeaturedSellersPage(limit: pageSize, offset: offset)
            }

            switch pageResult {
            case .failure(let error):
                return .failure(error)
            case .success(let page):
                total = page.total
                for seller in page.items {
                    let key = seller.sellerKey
                    guard !key.isEmpty, seen.insert(key).inserted else { continue }
                    accumulated.append(seller)
                }
                if page.items.count < pageSize { break }
                if total > 0, accumulated.count >= total { break }
                offset += page.items.count
                if offset > 5_000 { break }
            }
        }

        return .success((accumulated, total))
    }
}
