import Foundation
import Observation

enum ExplorePrimarySection: String, CaseIterable {
    case listings
    case sellers
}

private let exploreFeedPageSize = 20
/// Pinterest / Android Explore — prefetch when this many tiles from the end appear.
private let exploreFeedPrefetchThreshold = 3
/// Matches Android `ExploreStaleThresholdMs` — skip redundant reload when reopening Explore.
private let exploreStaleThreshold: TimeInterval = 60

@Observable
@MainActor
final class ExploreViewModel {
    var query = ""
    var items: [ListingFeedItem] = []
    var sellerResults: [UserSearchResult] = []
    var featuredSellers: [FeaturedSellerItem] = []
    var sellerPreviewPosts: [String: [ListingFeedItem]] = [:]
    var sellersLoading = false
    var sellersLoadError = false
    var quickInterestChips: [String] = []
    var primarySection: ExplorePrimarySection = .listings
    var isLoading = false
    /// True while replacing the first page but keeping the current grid visible (filter/search changes).
    var isReloadingListings = false
    var isRefreshing = false
    var isLoadingMore = false
    var hasMore = true
    /// Bumped to scroll the listings feed back to the top (`ScrollViewReader`).
    private(set) var listingsScrollToTopToken = 0
    var loadError = false
    var showFilterSheet = false
    var searchBarExpanded = false
    var isSearchMode = false
    var committedListingSearchQuery = ""
    var committedSellerSearchQuery = ""

    // Search overlay
    var searchOverlayRecent: [String] = []
    var searchOverlayTrending: [TrendingQueryItem] = []
    var searchOverlayTrendingTags: [String] = []
    var searchOverlayLoading = false
    var autocompleteSuggestions: [String] = []
    var autocompleteLoading = false
    private var autocompleteTask: Task<Void, Never>?

    // Filters
    var selectedCategoryId: String?
    var selectedCategoryName: String?
    var selectedAestheticTagIds: Set<String> = []
    var selectedBrandId: String?
    var selectedBrandName: String?
    var selectedCountryId: String?
    var selectedCountryIso2: String?
    var selectedCountryName: String?
    var minPriceText = ""
    var maxPriceText = ""
    var selectedConditionFilter: String?
    var sizingModeFilter: String? = ExploreViewModel.initialSizingModeFilter()
    var sortMode = "recent"
    var categoryTree: [CategoryTreeNode] = []
    var aestheticTags: [CommonAestheticTagDto] = []
    var brands: [CommonBrandDto] = []
    var countries: [CommonCountryDto] = []
    var filterCatalogLoading = false

    private var listingsFetchGeneration = 0
    private(set) var listingsFeedEpoch = 0
    private var sellersBrowseGeneration = 0
    private var loadMoreCooldownUntil: Date?
    private var loadMoreTask: Task<Void, Never>?
    private var lastSuccessfulExploreRefreshAt: Date?
    private var listingsReloadTask: Task<Void, Never>?

    private static func initialSizingModeFilter() -> String? {
        let mode = ExploreSizingPreference.read()
        return mode == ExploreSizingPreference.modeMatchProfile ? mode : nil
    }

    func setSizingModeFilter(_ mode: String?) {
        if let mode, mode.lowercased() == ExploreSizingPreference.modeMatchProfile {
            sizingModeFilter = ExploreSizingPreference.modeMatchProfile
            ExploreSizingPreference.write(ExploreSizingPreference.modeMatchProfile)
        } else {
            sizingModeFilter = nil
            ExploreSizingPreference.write(ExploreSizingPreference.modeAll)
        }
    }

    func recordView(item: ListingFeedItem, position: Int, deps: AppDependencies) {
        deps.feedEventReporter.impression(listingId: item.id, surface: "explore", position: position)
        Task { _ = await deps.listingRepository.recordView(listingId: item.id) }
    }

    func recordDwell(item: ListingFeedItem, position: Int, dwellMs: Int, deps: AppDependencies) {
        guard dwellMs >= 800 else { return }
        deps.feedEventReporter.dwell(listingId: item.id, surface: "explore", position: position, dwellMs: dwellMs)
    }

    func reportListingClick(item: ListingFeedItem, position: Int, deps: AppDependencies) {
        deps.feedEventReporter.click(listingId: item.id, surface: "explore", position: position)
    }

    var hasActiveFilters: Bool {
        selectedCategoryId != nil
            || !selectedAestheticTagIds.isEmpty
            || selectedBrandId != nil
            || selectedCountryId != nil
            || normalizedCountryIso2(selectedCountryIso2) != nil
            || !minPriceText.trimmingCharacters(in: .whitespaces).isEmpty
            || !maxPriceText.trimmingCharacters(in: .whitespaces).isEmpty
            || selectedConditionFilter != nil
            || (sizingModeFilter != nil && sizingModeFilter?.lowercased() != "all")
    }

    /// Root chip highlight when a nested category id is selected — Android category row behavior.
    var categoryStripHighlightId: String? {
        guard let id = selectedCategoryId?.trimmingCharacters(in: .whitespacesAndNewlines), !id.isEmpty else {
            return nil
        }
        if categoryTree.contains(where: { $0.id == id }) { return id }
        for root in categoryTree where root.containsCategoryId(id) {
            return root.id
        }
        return id
    }

    var isSearchModeActive: Bool {
        isSearchMode && !committedListingSearchQuery.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var selectedInterestChipNames: Set<String> {
        Set(selectedAestheticTagIds.compactMap { id in
            aestheticTags.first(where: { $0.id == id }).map { tag in
                let label = tag.displayLabel().trimmingCharacters(in: .whitespacesAndNewlines)
                return label.isEmpty ? tag.name : label
            }
        })
    }

    var isSizingFilterActive: Bool {
        sizingModeFilter?.lowercased() == ExploreSizingPreference.modeMatchProfile
    }

    private static func conditionLabel(for apiValue: String) -> String {
        switch apiValue.lowercased() {
        case "new": return L10n.conditionNew
        case "like_new": return L10n.conditionLikeNew
        case "good": return L10n.conditionGood
        case "fair": return L10n.conditionFair
        default: return apiValue
        }
    }

    private func effectiveListingSort(query: String) -> String {
        let q = query.trimmingCharacters(in: .whitespaces)
        if isSearchMode && !q.isEmpty { return sortMode }
        return "popular"
    }

    var filterSummaryParts: [String] {
        var parts: [String] = []
        if let catId = selectedCategoryId?.trimmingCharacters(in: .whitespacesAndNewlines), !catId.isEmpty,
           let name = categoryTree.categoryName(for: catId) {
            parts.append(name)
        }
        for tagId in selectedAestheticTagIds.sorted() {
            if let label = aestheticTags.first(where: { $0.id == tagId })?.displayLabel().trimmingCharacters(in: .whitespacesAndNewlines),
               !label.isEmpty {
                parts.append(label)
            }
        }
        if let brandId = selectedBrandId?.trimmingCharacters(in: .whitespacesAndNewlines), !brandId.isEmpty,
           let brand = brands.first(where: { $0.id == brandId })?.name.trimmingCharacters(in: .whitespacesAndNewlines),
           !brand.isEmpty {
            parts.append(brand)
        }
        if let country = resolvedCountryDisplayName() {
            parts.append(country)
        }
        if let condition = selectedConditionFilter?.trimmingCharacters(in: .whitespacesAndNewlines), !condition.isEmpty {
            parts.append(Self.conditionLabel(for: condition))
        }
        let minP = minPriceText.trimmingCharacters(in: .whitespacesAndNewlines)
        let maxP = maxPriceText.trimmingCharacters(in: .whitespacesAndNewlines)
        if !minP.isEmpty || !maxP.isEmpty {
            parts.append([minP, maxP].filter { !$0.isEmpty }.joined(separator: "–"))
        }
        if let sizing = sizingModeFilter?.trimmingCharacters(in: .whitespacesAndNewlines),
           !sizing.isEmpty, sizing.lowercased() != "all" {
            parts.append(L10n.exploreFilterSummarySizingMatch)
        }
        return parts
    }

    /// Opens the full-screen suggestions overlay with a fresh draft query (recent / trending).
    func requestSearchBarExpanded() {
        autocompleteTask?.cancel()
        autocompleteSuggestions = []
        autocompleteLoading = false
        query = ""
        searchBarExpanded = true
    }

    func setSearchBarExpanded(_ expanded: Bool) {
        searchBarExpanded = expanded
        if !expanded {
            autocompleteTask?.cancel()
            autocompleteSuggestions = []
            autocompleteLoading = false
            query = ""
        }
    }

    func setSearchQuery(_ text: String, deps: AppDependencies, isGuestMode: Bool) {
        query = text
        autocompleteTask?.cancel()
        let snapshot = text.trimmingCharacters(in: .whitespaces)
        if snapshot.isEmpty {
            autocompleteSuggestions = []
            autocompleteLoading = false
            return
        }
        autocompleteLoading = true
        autocompleteTask = Task {
            try? await Task.sleep(for: .milliseconds(280))
            guard !Task.isCancelled, query.trimmingCharacters(in: .whitespaces) == snapshot else { return }
            let suggestions: [String]
            switch primarySection {
            case .listings:
                if case .success(let list) = await deps.searchRepository.autocompleteListingTitles(prefix: snapshot) {
                    suggestions = list
                } else {
                    suggestions = []
                }
            case .sellers:
                if case .success(let users) = await deps.userRepository.searchUsers(query: snapshot, limit: 8, publicBrowse: isGuestMode) {
                    suggestions = users.compactMap { u -> String? in
                        let uu = u.username.trimmingCharacters(in: .whitespaces)
                        if !uu.isEmpty { return "@\(uu)" }
                        if !u.displayName.isEmpty { return u.displayName.trimmingCharacters(in: .whitespaces) }
                        return nil
                    }
                } else {
                    suggestions = []
                }
            }
            guard !Task.isCancelled, query.trimmingCharacters(in: .whitespaces) == snapshot else { return }
            autocompleteSuggestions = Array(Set(suggestions))
            autocompleteLoading = false
        }
    }

    func loadSearchOverlayData(deps: AppDependencies?) async {
        guard let deps else { return }
        searchOverlayLoading = true
        defer { searchOverlayLoading = false }
        async let recent = deps.searchRepository.getRecentQueries()
        async let trending = deps.searchRepository.getTrendingQueries()
        async let tags = deps.searchRepository.getTrendingTags()
        if case .success(let r) = await recent { searchOverlayRecent = r }
        if case .success(let t) = await trending { searchOverlayTrending = t }
        if case .success(let g) = await tags { searchOverlayTrendingTags = g }
    }

    /// Launch waiting-screen prefetch — suggestions, catalog, and first listings page when empty.
    func warmLaunchCaches(
        deps: AppDependencies,
        isGuestMode: Bool,
        launchProgress: LaunchWaitingProgress? = nil
    ) async {
        async let overlay: Void = {
            await loadSearchOverlayData(deps: deps)
            launchProgress?.completeExploreStep()
        }()
        async let catalog: Void = {
            await loadFilterCatalogIfNeeded(deps: deps)
            launchProgress?.completeExploreStep()
        }()
        async let chips: Void = {
            await loadQuickInterestChips(deps: deps)
            launchProgress?.completeExploreStep()
        }()
        async let sellers: Void = {
            await loadFeaturedSellers(deps: deps, isGuestMode: isGuestMode)
            launchProgress?.completeExploreStep()
        }()
        _ = await (overlay, catalog, chips, sellers)
        if items.isEmpty {
            await fetchListingsFirstPage(deps: deps, isGuestMode: isGuestMode)
            launchProgress?.completeExploreStep()
        }
    }

    func selectSearchSuggestionAndSubmit(_ text: String, deps: AppDependencies, isGuestMode: Bool) async {
        let t = text.trimmingCharacters(in: .whitespaces)
        guard !t.isEmpty else { return }
        autocompleteTask?.cancel()
        query = t
        autocompleteSuggestions = []
        autocompleteLoading = false
        await submitSearch(deps: deps, isGuestMode: isGuestMode)
    }

    func selectSearchOverlayTrendingTag(_ tag: String, deps: AppDependencies, isGuestMode: Bool) async {
        let cleaned = tag.trimmingCharacters(in: .whitespaces)
        guard !cleaned.isEmpty else { return }
        if primarySection == .sellers {
            await selectSearchSuggestionAndSubmit(cleaned, deps: deps, isGuestMode: isGuestMode)
            return
        }
        if let match = aestheticTags.first(where: {
            $0.name.caseInsensitiveCompare(cleaned) == .orderedSame
                || $0.displayName.caseInsensitiveCompare(cleaned) == .orderedSame
        }) {
            selectedAestheticTagIds = [match.id]
            isSearchMode = false
            committedListingSearchQuery = ""
            setSearchBarExpanded(false)
            await reloadListingsAfterFilterChange(deps: deps, isGuestMode: isGuestMode)
        } else {
            await selectSearchSuggestionAndSubmit(cleaned, deps: deps, isGuestMode: isGuestMode)
        }
    }

    func refresh(deps: AppDependencies, isGuestMode: Bool) async {
        loadError = false
        sellersLoadError = false
        await loadFilterCatalogIfNeeded(deps: deps)
        async let featured: Void = loadFeaturedSellers(deps: deps, isGuestMode: isGuestMode)
        async let chips: Void = loadQuickInterestChips(deps: deps)
        _ = await (featured, chips)
        if primarySection == .sellers {
            await refreshSellerBrowse(deps: deps, isGuestMode: isGuestMode)
        } else {
            await fetchListingsFirstPage(deps: deps, isGuestMode: isGuestMode)
        }
    }

    /// Android `onExploreOpened` — reload only when feed data is stale.
    func onExploreOpened(deps: AppDependencies, isGuestMode: Bool) async {
        await refreshIfStale(deps: deps, isGuestMode: isGuestMode)
    }

    func refreshIfStale(deps: AppDependencies, isGuestMode: Bool) async {
        if let last = lastSuccessfulExploreRefreshAt,
           Date().timeIntervalSince(last) < exploreStaleThreshold {
            if items.isEmpty, !isLoading, !isReloadingListings {
                await refresh(deps: deps, isGuestMode: isGuestMode)
            }
            return
        }
        await reloadExploreContent(deps: deps, isGuestMode: isGuestMode)
    }

    private func reloadExploreContent(deps: AppDependencies, isGuestMode: Bool) async {
        if primarySection == .sellers {
            await refreshSellerBrowse(deps: deps, isGuestMode: isGuestMode)
        } else {
            await fetchListingsFirstPage(deps: deps, isGuestMode: isGuestMode)
        }
    }

    func pullToRefresh(deps: AppDependencies, isGuestMode: Bool) async {
        isRefreshing = true
        defer { isRefreshing = false }
        await refresh(deps: deps, isGuestMode: isGuestMode)
    }

    func requestListingsScrollToTop() {
        listingsScrollToTopToken &+= 1
    }

    /// Coalesced entry point from the pagination sentinel — avoids duplicate loads from multiple `onAppear` calls.
    func requestLoadMore(deps: AppDependencies, isGuestMode: Bool) {
        guard canLoadMoreListings else { return }
        guard loadMoreTask == nil else { return }
        loadMoreTask = Task { @MainActor in
            defer { loadMoreTask = nil }
            await loadMore(deps: deps, isGuestMode: isGuestMode)
        }
    }

    /// Android Explore grid — prefetch when [position] is within [exploreFeedPrefetchThreshold] of the end.
    func requestLoadMoreIfNearEnd(position: Int, deps: AppDependencies, isGuestMode: Bool) {
        guard canLoadMoreListings else { return }
        let threshold = max(0, items.count - exploreFeedPrefetchThreshold)
        guard position >= threshold else { return }
        requestLoadMore(deps: deps, isGuestMode: isGuestMode)
    }

    func cancelLoadMore() {
        loadMoreTask?.cancel()
        loadMoreTask = nil
        isLoadingMore = false
    }

    private var canLoadMoreListings: Bool {
        primarySection == .listings
            && hasMore
            && !isLoadingMore
            && !isLoading
            && !isReloadingListings
            && !isRefreshing
            && !(loadError && items.isEmpty)
    }

    func loadMore(deps: AppDependencies, isGuestMode: Bool) async {
        guard canLoadMoreListings else { return }
        let now = Date()
        if let until = loadMoreCooldownUntil, now < until { return }
        loadMoreCooldownUntil = now.addingTimeInterval(0.4)
        let fetchGen = listingsFetchGeneration
        let offset = items.count
        guard offset > 0 else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        await loadListings(
            deps: deps,
            isGuestMode: isGuestMode,
            offset: offset,
            append: true,
            expectedFetchGeneration: fetchGen
        )
    }

    func submitSearch(deps: AppDependencies, isGuestMode: Bool) async {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return }
        switch primarySection {
        case .listings:
            loadError = false
            committedListingSearchQuery = q
            isSearchMode = true
            requestListingsScrollToTop()
            await fetchListingsFirstPage(deps: deps, isGuestMode: isGuestMode)
            setSearchBarExpanded(false)
        case .sellers:
            committedSellerSearchQuery = q
            await searchSellers(deps: deps, isGuestMode: isGuestMode, query: q)
            setSearchBarExpanded(false)
        }
    }

    func clearListingSearch(deps: AppDependencies, isGuestMode: Bool) async {
        isSearchMode = false
        committedListingSearchQuery = ""
        query = ""
        await clearExploreConstraints(deps: deps, isGuestMode: isGuestMode)
    }

    func clearSellerSearch(deps: AppDependencies, isGuestMode: Bool) async {
        committedSellerSearchQuery = ""
        query = ""
        await refreshSellerBrowse(deps: deps, isGuestMode: isGuestMode)
    }

    func retrySellerBrowse(deps: AppDependencies, isGuestMode: Bool) async {
        if committedSellerSearchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
            await refreshSellerBrowse(deps: deps, isGuestMode: isGuestMode)
        } else {
            await searchSellers(deps: deps, isGuestMode: isGuestMode, query: committedSellerSearchQuery)
        }
    }

    func toggleAestheticTagFilter(_ tagId: String, deps: AppDependencies, isGuestMode: Bool) async {
        let id = tagId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty else { return }
        if selectedAestheticTagIds.contains(id) {
            selectedAestheticTagIds.remove(id)
        } else {
            selectedAestheticTagIds.insert(id)
        }
        await reloadListingsAfterFilterChange(deps: deps, isGuestMode: isGuestMode)
    }

    func toggleInterestChip(_ tagName: String, deps: AppDependencies, isGuestMode: Bool) async {
        let cleaned = tagName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !cleaned.isEmpty else { return }
        if let match = aestheticTags.first(where: {
            $0.name.caseInsensitiveCompare(cleaned) == .orderedSame
                || $0.displayName.caseInsensitiveCompare(cleaned) == .orderedSame
                || $0.displayNameVi.caseInsensitiveCompare(cleaned) == .orderedSame
        }) {
            await toggleAestheticTagFilter(match.id, deps: deps, isGuestMode: isGuestMode)
        } else {
            query = cleaned
            await submitSearch(deps: deps, isGuestMode: isGuestMode)
        }
    }

    /// Clears marketplace filters + search text (Android `clearExploreConstraints` fields).
    private func clearMarketplaceFilterFields() {
        selectedCategoryId = nil
        selectedCategoryName = nil
        selectedAestheticTagIds = []
        selectedBrandId = nil
        selectedBrandName = nil
        selectedCountryId = nil
        selectedCountryIso2 = nil
        selectedCountryName = nil
        minPriceText = ""
        maxPriceText = ""
        selectedConditionFilter = nil
        setSizingModeFilter(nil)
    }

    /// Called when the Explore overlay closes — fresh session on next open.
    func resetSessionOnOverlayClose() {
        autocompleteTask?.cancel()
        autocompleteTask = nil
        autocompleteSuggestions = []
        autocompleteLoading = false
        searchBarExpanded = false
        showFilterSheet = false
        query = ""
        isSearchMode = false
        committedListingSearchQuery = ""
        committedSellerSearchQuery = ""
        clearMarketplaceFilterFields()
        sortMode = "recent"
        primarySection = .listings
        listingsReloadTask?.cancel()
        listingsReloadTask = nil
        cancelLoadMore()
        listingsFetchGeneration += 1
        sellersBrowseGeneration += 1
        items = []
        sellerResults = []
        sellerPreviewPosts = [:]
        isLoading = false
        isReloadingListings = false
        isRefreshing = false
        lastSuccessfulExploreRefreshAt = nil
        hasMore = true
        loadError = false
        sellersLoading = false
        sellersLoadError = false
        loadMoreCooldownUntil = nil
    }

    func clearAllFilters(deps: AppDependencies, isGuestMode: Bool) async {
        clearMarketplaceFilterFields()
        await clearExploreConstraints(deps: deps, isGuestMode: isGuestMode)
    }

    func setPrimarySection(_ section: ExplorePrimarySection, deps: AppDependencies, isGuestMode: Bool) async {
        guard primarySection != section else { return }
        primarySection = section
        autocompleteTask?.cancel()
        autocompleteSuggestions = []
        if section == .sellers {
            await refreshSellerBrowse(deps: deps, isGuestMode: isGuestMode)
        }
    }

    func loadFeaturedSellers(deps: AppDependencies, isGuestMode: Bool) async {
        switch await deps.searchRepository.getFeaturedSellers(limit: 10, publicBrowse: isGuestMode) {
        case .success(let sellers):
            featuredSellers = sellers
        case .failure:
            featuredSellers = []
        }
    }

    func loadQuickInterestChips(deps: AppDependencies) async {
        if case .success(let tags) = await deps.searchRepository.getTrendingTags() {
            if !tags.isEmpty { quickInterestChips = tags }
        }
    }

    func loadFilterCatalogIfNeeded(deps: AppDependencies) async {
        guard !filterCatalogLoading else { return }
        let needsCatalog = categoryTree.isEmpty || aestheticTags.isEmpty || brands.isEmpty || countries.isEmpty
        guard needsCatalog else { return }
        filterCatalogLoading = true
        defer { filterCatalogLoading = false }
        await ensureFilterCatalogLoaded(deps: deps)
    }

    private func ensureFilterCatalogLoaded(deps: AppDependencies) async {
        if aestheticTags.isEmpty,
           case .success(let tags) = await deps.commonCatalogRepository.getAestheticTags(all: true) {
            aestheticTags = tags
        }
        if categoryTree.isEmpty,
           case .success(let tree) = await deps.commonCatalogRepository.getCategoryTree() {
            categoryTree = tree
        }
        if brands.isEmpty,
           case .success(let page) = await deps.commonCatalogRepository.getBrands(limit: 80) {
            brands = page.items
        }
        if countries.isEmpty,
           case .success(let list) = await deps.commonCatalogRepository.getCountries(all: true) {
            countries = list
        }
    }

    func applyFiltersAndReload(deps: AppDependencies, isGuestMode: Bool) async {
        showFilterSheet = false
        await reloadListingsAfterFilterChange(deps: deps, isGuestMode: isGuestMode)
    }

    /// Android `reloadAfterFilterChange` — keep visible tiles, swap in the new first page.
    func reloadListingsAfterFilterChange(deps: AppDependencies, isGuestMode: Bool) async {
        requestListingsScrollToTop()
        listingsReloadTask?.cancel()
        let task = Task {
            await fetchListingsFirstPage(deps: deps, isGuestMode: isGuestMode)
        }
        listingsReloadTask = task
        await task.value
        if listingsReloadTask == task {
            listingsReloadTask = nil
        }
    }

    /// Full reset when clearing search/filters from empty state — Android `clearExploreConstraints`.
    private func clearExploreConstraints(deps: AppDependencies, isGuestMode: Bool) async {
        listingsReloadTask?.cancel()
        listingsReloadTask = nil
        cancelLoadMore()
        listingsFetchGeneration += 1
        listingsFeedEpoch += 1
        items = []
        hasMore = true
        loadError = false
        isLoading = true
        defer { isLoading = false }
        await loadListings(deps: deps, isGuestMode: isGuestMode, offset: 0, append: false)
    }

    /// Replaces the first page in place — does not clear [items] first (smooth filter/search UX).
    private func fetchListingsFirstPage(deps: AppDependencies, isGuestMode: Bool) async {
        cancelLoadMore()
        listingsFetchGeneration += 1
        let generation = listingsFetchGeneration
        let hadItems = !items.isEmpty
        loadError = false
        if hadItems {
            isReloadingListings = true
        } else {
            isLoading = true
        }
        defer {
            isLoading = false
            isReloadingListings = false
        }
        let result = await searchListingsWithRetry(
            deps: deps,
            isGuestMode: isGuestMode,
            offset: 0
        )
        guard generation == listingsFetchGeneration else { return }
        listingsFeedEpoch += 1
        switch result {
        case .success(let feed):
            items = feed
            hasMore = feed.count >= exploreFeedPageSize
            loadError = false
            lastSuccessfulExploreRefreshAt = Date()
        case .failure:
            if !hadItems {
                items = []
                loadError = true
            }
            hasMore = false
        }
    }

    private func searchListingsWithRetry(
        deps: AppDependencies,
        isGuestMode: Bool,
        offset: Int
    ) async -> Result<[ListingFeedItem], Error> {
        var result = await requestListingsPage(deps: deps, isGuestMode: isGuestMode, offset: offset)
        if case .failure = result {
            try? await Task.sleep(for: .milliseconds(400))
            result = await requestListingsPage(deps: deps, isGuestMode: isGuestMode, offset: offset)
        }
        return result
    }

    private func requestListingsPage(
        deps: AppDependencies,
        isGuestMode: Bool,
        offset: Int
    ) async -> Result<[ListingFeedItem], Error> {
        let q = committedListingSearchQuery.isEmpty
            ? query.trimmingCharacters(in: .whitespaces)
            : committedListingSearchQuery
        let minPrice = Int64(minPriceText.filter(\.isNumber))
        let maxPrice = Int64(maxPriceText.filter(\.isNumber))
        let tagIds = selectedAestheticTagIds.isEmpty ? nil : Array(selectedAestheticTagIds)
        let useSearch = isSearchMode && !q.isEmpty
        let sort = effectiveListingSort(query: q)
        if !useSearch && q.isEmpty {
            return await deps.recommendationRepository.exploreListings(
                publicBrowse: isGuestMode,
                categoryId: selectedCategoryId,
                aestheticTagIds: tagIds,
                brandId: selectedBrandId,
                minPrice: minPrice,
                maxPrice: maxPrice,
                condition: selectedConditionFilter,
                countryIso2: countryIso2ForApi(),
                limit: exploreFeedPageSize,
                offset: offset,
                sizingMode: sizingModeFilter,
                surface: "explore"
            )
        }
        if isGuestMode {
            return await deps.searchRepository.browseListings(
                q: q,
                categoryId: selectedCategoryId,
                aestheticTagIds: tagIds,
                brandId: selectedBrandId,
                countryIso2: countryIso2ForApi(),
                minPrice: minPrice,
                maxPrice: maxPrice,
                condition: selectedConditionFilter,
                sort: sort,
                limit: exploreFeedPageSize,
                offset: offset
            )
        }
        return await deps.searchRepository.searchListings(
            q: q,
            categoryId: selectedCategoryId,
            aestheticTagIds: tagIds,
            sizingMode: sizingModeFilter,
            brandId: selectedBrandId,
            countryIso2: countryIso2ForApi(),
            minPrice: minPrice,
            maxPrice: maxPrice,
            condition: selectedConditionFilter,
            sort: sort,
            limit: exploreFeedPageSize,
            offset: offset
        )
    }

    private func loadListings(
        deps: AppDependencies,
        isGuestMode: Bool,
        offset: Int,
        append: Bool,
        expectedFetchGeneration gen: Int? = nil
    ) async {
        let fetchGen = gen ?? listingsFetchGeneration
        let result = await requestListingsPage(deps: deps, isGuestMode: isGuestMode, offset: offset)
        guard fetchGen == listingsFetchGeneration else { return }
        switch result {
        case .success(let feed):
            if append {
                var seen = Set(items.map(\.id))
                let fresh = feed.filter { seen.insert($0.id).inserted }
                guard !fresh.isEmpty || feed.isEmpty else {
                    hasMore = feed.count >= exploreFeedPageSize
                    return
                }
                items = items + fresh
            } else {
                items = feed
            }
            hasMore = feed.count >= exploreFeedPageSize
            loadError = false
            if !append {
                lastSuccessfulExploreRefreshAt = Date()
            }
        case .failure:
            if !append {
                items = []
                loadError = true
                hasMore = false
            }
        }
    }

    private func refreshSellerBrowse(deps: AppDependencies, isGuestMode: Bool) async {
        sellersBrowseGeneration += 1
        let gen = sellersBrowseGeneration
        committedSellerSearchQuery = ""
        sellersLoading = true
        sellersLoadError = false
        sellerPreviewPosts = [:]
        defer { sellersLoading = false }
        switch await deps.userRepository.searchUsers(query: "a", limit: 40, publicBrowse: isGuestMode) {
        case .success(let users):
            guard gen == sellersBrowseGeneration else { return }
            sellerResults = users
            sellersLoadError = false
            if !users.isEmpty {
                await loadSellerListingPreviews(deps: deps, isGuestMode: isGuestMode, expectedGen: gen)
            }
        case .failure:
            guard gen == sellersBrowseGeneration else { return }
            sellerResults = []
            sellerPreviewPosts = [:]
            sellersLoadError = true
        }
    }

    private func searchSellers(deps: AppDependencies, isGuestMode: Bool, query: String) async {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else {
            await refreshSellerBrowse(deps: deps, isGuestMode: isGuestMode)
            return
        }
        sellersBrowseGeneration += 1
        let gen = sellersBrowseGeneration
        sellersLoading = true
        sellersLoadError = false
        sellerPreviewPosts = [:]
        defer { sellersLoading = false }
        switch await deps.userRepository.searchUsers(query: q, limit: 50, publicBrowse: isGuestMode) {
        case .success(let users):
            guard gen == sellersBrowseGeneration else { return }
            sellerResults = users
            sellersLoadError = false
            if !users.isEmpty {
                await loadSellerListingPreviews(deps: deps, isGuestMode: isGuestMode, expectedGen: gen)
            }
        case .failure:
            guard gen == sellersBrowseGeneration else { return }
            sellerResults = []
            sellerPreviewPosts = [:]
            committedSellerSearchQuery = ""
            sellersLoadError = true
        }
    }

    private func loadSellerListingPreviews(
        deps: AppDependencies,
        isGuestMode: Bool,
        expectedGen: Int
    ) async {
        sellerPreviewPosts = [:]
        let sellers = sellerResults
        await withTaskGroup(of: (String, [ListingFeedItem]).self) { group in
            for seller in sellers {
                let key = seller.userId.trimmingCharacters(in: .whitespaces).isEmpty
                    ? seller.username.trimmingCharacters(in: .whitespaces)
                    : seller.userId.trimmingCharacters(in: .whitespaces)
                guard !key.isEmpty else { continue }
                group.addTask {
                    let listings: [ListingFeedItem]
                    switch await deps.listingRepository.getListingsBySeller(
                        sellerId: key,
                        status: nil,
                        limit: 3,
                        offset: 0,
                        publicBrowse: isGuestMode
                    ) {
                    case .success(let items):
                        listings = Array(items.prefix(3))
                    case .failure:
                        listings = []
                    }
                    return (key, listings)
                }
            }
            for await (key, listings) in group {
                guard expectedGen == sellersBrowseGeneration else { return }
                sellerPreviewPosts[key] = listings
            }
        }
    }

    func toggleLike(_ item: ListingFeedItem, position: Int = 0, deps: AppDependencies) async {
        switch await deps.listingRepository.toggleLike(listingId: item.id) {
        case .failure(let error):
            deps.showSnackbar(FeedEngagementFeedback.actionErrorMessage(for: error))
            return
        case .success(let liked):
            if liked {
                deps.feedEventReporter.like(listingId: item.id, surface: "explore", position: position)
            }
            deps.showSnackbar(FeedEngagementFeedback.likeMessage(liked: liked))
            patchListing(item.id) { cur in
                let delta = (liked && !cur.isLiked) ? 1 : ((!liked && cur.isLiked) ? -1 : 0)
                return ListingFeedItem(
                    id: cur.id, title: cur.title, coverImageUrl: cur.coverImageUrl, imageUrls: cur.imageUrls,
                    priceVnd: cur.priceVnd, brand: cur.brand, size: cur.size, categoryName: cur.categoryName,
                    listingAestheticTag: cur.listingAestheticTag, condition: cur.condition,
                    likeCount: max(0, cur.likeCount + delta), saveCount: cur.saveCount,
                    sellerId: cur.sellerId, sellerUsername: cur.sellerUsername, sellerStyleTag: cur.sellerStyleTag,
                    createdAt: cur.createdAt, isLiked: liked, isSaved: cur.isSaved,
                    onsiteInspectionCommitment: cur.onsiteInspectionCommitment,
                    listingStatus: cur.listingStatus, descriptionText: cur.descriptionText
                )
            }
        }
    }

    func toggleSave(_ item: ListingFeedItem, position: Int = 0, deps: AppDependencies) async {
        switch await deps.listingRepository.toggleSave(listingId: item.id, currentlySaved: item.isSaved) {
        case .failure(let error):
            deps.showSnackbar(FeedEngagementFeedback.actionErrorMessage(for: error))
        case .success(let saved):
            if saved {
                deps.feedEventReporter.save(listingId: item.id, surface: "explore", position: position)
            }
            deps.showSnackbar(FeedEngagementFeedback.saveMessage(saved: saved))
            patchListing(item.id) { cur in
                let delta = (saved && !cur.isSaved) ? 1 : ((!saved && cur.isSaved) ? -1 : 0)
                return ListingFeedItem(
                    id: cur.id, title: cur.title, coverImageUrl: cur.coverImageUrl, imageUrls: cur.imageUrls,
                    priceVnd: cur.priceVnd, brand: cur.brand, size: cur.size, categoryName: cur.categoryName,
                    listingAestheticTag: cur.listingAestheticTag, condition: cur.condition,
                    likeCount: cur.likeCount, saveCount: max(0, cur.saveCount + delta),
                    sellerId: cur.sellerId, sellerUsername: cur.sellerUsername, sellerStyleTag: cur.sellerStyleTag,
                    createdAt: cur.createdAt, isLiked: cur.isLiked, isSaved: saved,
                    onsiteInspectionCommitment: cur.onsiteInspectionCommitment,
                    listingStatus: cur.listingStatus, descriptionText: cur.descriptionText
                )
            }
        }
    }

    private func patchListing(_ id: String, transform: (ListingFeedItem) -> ListingFeedItem) {
        items = items.map { $0.id == id ? transform($0) : $0 }
    }

    /// Opens Explore with filters from profile chips — mirrors Android [openExploreFromProfileFilter].
    func openFromProfileFilter(
        deps: AppDependencies,
        categoryId: String? = nil,
        brandId: String? = nil,
        aestheticTagId: String? = nil,
        searchQuery: String = "",
        countryId: String? = nil,
        countryIso2: String? = nil
    ) async {
        primarySection = .listings
        searchBarExpanded = false
        loadError = false
        await ensureFilterCatalogLoaded(deps: deps)

        let q = searchQuery.trimmingCharacters(in: .whitespaces)
        let cat = categoryId?.trimmingCharacters(in: .whitespaces).nilIfEmpty
        let brand = brandId?.trimmingCharacters(in: .whitespaces).nilIfEmpty
        var tag = aestheticTagId?.trimmingCharacters(in: .whitespaces).nilIfEmpty
        if tag == nil, cat == nil, brand == nil, !q.isEmpty {
            tag = aestheticTags.first(where: { t in
                t.name.caseInsensitiveCompare(q) == .orderedSame
                    || t.displayName.caseInsensitiveCompare(q) == .orderedSame
                    || t.displayNameVi.caseInsensitiveCompare(q) == .orderedSame
            })?.id
        }

        if let cat {
            selectedCategoryId = cat
            selectedBrandId = nil
            selectedAestheticTagIds = []
        } else if let brand {
            selectedCategoryId = nil
            selectedBrandId = brand
            selectedAestheticTagIds = []
        } else if let tag {
            selectedCategoryId = nil
            selectedBrandId = nil
            selectedAestheticTagIds = [tag]
        } else {
            selectedCategoryId = nil
            selectedBrandId = nil
            selectedAestheticTagIds = []
        }
        selectedCategoryName = categoryTree.categoryName(for: selectedCategoryId)
        selectedBrandName = brands.first(where: { $0.id == selectedBrandId })?.name

        selectedCountryId = countryId?.trimmingCharacters(in: .whitespaces).nilIfEmpty
        selectedCountryIso2 = normalizedCountryIso2(countryIso2)
        if selectedCountryIso2 == nil, let cid = selectedCountryId {
            selectedCountryIso2 = normalizedCountryIso2(
                countries.first(where: { $0.id == cid })?.iso2
            )
        }
        selectedCountryName = resolvedCountryDisplayName()

        let hasStructuredFilter = cat != nil || brand != nil || tag != nil
            || selectedCountryId != nil || normalizedCountryIso2(selectedCountryIso2) != nil

        if hasStructuredFilter {
            committedListingSearchQuery = ""
            isSearchMode = false
            query = ""
            await fetchListingsFirstPage(deps: deps, isGuestMode: false)
        } else if !q.isEmpty {
            committedListingSearchQuery = q
            isSearchMode = true
            query = ""
            await fetchListingsFirstPage(deps: deps, isGuestMode: false)
        } else {
            committedListingSearchQuery = ""
            isSearchMode = false
            query = ""
            await fetchListingsFirstPage(deps: deps, isGuestMode: false)
        }
    }

    func countryIso2ForApi() -> String? {
        if let iso = normalizedCountryIso2(selectedCountryIso2) { return iso }
        guard let id = selectedCountryId?.trimmingCharacters(in: .whitespacesAndNewlines), !id.isEmpty else {
            return nil
        }
        return normalizedCountryIso2(countries.first(where: { $0.id == id })?.iso2)
    }

    private func resolvedCountryDisplayName() -> String? {
        let byId = selectedCountryId.flatMap { id in
            countries.first(where: { $0.id == id })?.name
        }
        if let name = byId?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
            return name
        }
        if let iso = normalizedCountryIso2(selectedCountryIso2),
           let name = countries.first(where: { $0.iso2.caseInsensitiveCompare(iso) == .orderedSame })?.name
            .trimmingCharacters(in: .whitespacesAndNewlines),
           !name.isEmpty {
            return name
        }
        let stored = selectedCountryName?.trimmingCharacters(in: .whitespacesAndNewlines)
        return stored?.isEmpty == false ? stored : nil
    }

    private func normalizedCountryIso2(_ raw: String?) -> String? {
        let trimmed = raw?.trimmingCharacters(in: .whitespacesAndNewlines).uppercased() ?? ""
        guard trimmed.count == 2, trimmed.allSatisfy({ $0 >= "A" && $0 <= "Z" }) else { return nil }
        return trimmed
    }

    /// Realtime `feed.refresh` — Android ExploreViewModel first-page reload.
    func handleFeedRefresh(deps: AppDependencies, isGuestMode: Bool) async {
        guard primarySection == .listings, !isSearchModeActive else { return }
        await fetchListingsFirstPage(deps: deps, isGuestMode: isGuestMode)
    }
}

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}

private extension CategoryTreeNode {
    func containsCategoryId(_ target: String) -> Bool {
        if id == target { return true }
        return children.contains { $0.containsCategoryId(target) }
    }

    func findById(_ target: String) -> CategoryTreeNode? {
        if id == target { return self }
        for child in children {
            if let found = child.findById(target) { return found }
        }
        return nil
    }
}

private extension Array where Element == CategoryTreeNode {
    func categoryName(for id: String?) -> String? {
        guard let id = id?.trimmingCharacters(in: .whitespacesAndNewlines), !id.isEmpty else { return nil }
        for root in self {
            if let node = root.findById(id) {
                let name = node.name.trimmingCharacters(in: .whitespacesAndNewlines)
                if !name.isEmpty { return name }
            }
        }
        return nil
    }
}
