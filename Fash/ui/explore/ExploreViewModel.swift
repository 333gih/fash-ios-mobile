import Foundation
import Observation

enum ExplorePrimarySection: String, CaseIterable {
    case listings
    case sellers
}

private let exploreFeedPageSize = 20

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
    var isRefreshing = false
    var isLoadingMore = false
    var hasMore = true
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
    private var sellersBrowseGeneration = 0

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
            || selectedCountryIso2 != nil
            || !minPriceText.trimmingCharacters(in: .whitespaces).isEmpty
            || !maxPriceText.trimmingCharacters(in: .whitespaces).isEmpty
            || selectedConditionFilter != nil
            || (sizingModeFilter != nil && sizingModeFilter?.lowercased() != "all")
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
        if let name = selectedCategoryName?.trimmingCharacters(in: .whitespacesAndNewlines), !name.isEmpty {
            parts.append(name)
        }
        if let brand = selectedBrandName?.trimmingCharacters(in: .whitespacesAndNewlines), !brand.isEmpty {
            parts.append(brand)
        }
        if let country = selectedCountryName?.trimmingCharacters(in: .whitespacesAndNewlines), !country.isEmpty {
            parts.append(country)
        }
        if let condition = selectedConditionFilter?.trimmingCharacters(in: .whitespacesAndNewlines), !condition.isEmpty {
            parts.append(Self.conditionLabel(for: condition))
        }
        for tagId in selectedAestheticTagIds.sorted() {
            if let label = aestheticTags.first(where: { $0.id == tagId })?.displayLabel().trimmingCharacters(in: .whitespacesAndNewlines),
               !label.isEmpty {
                parts.append(label)
            }
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

    func requestSearchBarExpanded() {
        searchBarExpanded = true
        if primarySection == .listings, isSearchMode, !committedListingSearchQuery.isEmpty {
            query = committedListingSearchQuery
        } else if primarySection == .sellers, !committedSellerSearchQuery.isEmpty {
            query = committedSellerSearchQuery
        }
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
            await refresh(deps: deps, isGuestMode: isGuestMode)
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
            listingsFetchGeneration += 1
            hasMore = true
            isLoading = true
            defer { isLoading = false }
            await loadListings(deps: deps, isGuestMode: isGuestMode, offset: 0, append: false)
        }
    }

    func pullToRefresh(deps: AppDependencies, isGuestMode: Bool) async {
        isRefreshing = true
        defer { isRefreshing = false }
        await refresh(deps: deps, isGuestMode: isGuestMode)
    }

    func loadMore(deps: AppDependencies, isGuestMode: Bool) async {
        guard primarySection == .listings, hasMore, !isLoadingMore, !isLoading else { return }
        guard !(loadError && items.isEmpty) else { return }
        isLoadingMore = true
        defer { isLoadingMore = false }
        await loadListings(deps: deps, isGuestMode: isGuestMode, offset: items.count, append: true)
    }

    func submitSearch(deps: AppDependencies, isGuestMode: Bool) async {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else { return }
        switch primarySection {
        case .listings:
            isLoading = true
            loadError = false
            committedListingSearchQuery = q
            isSearchMode = true
            listingsFetchGeneration += 1
            hasMore = true
            await loadListings(deps: deps, isGuestMode: isGuestMode, offset: 0, append: false)
            isLoading = false
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
        await refresh(deps: deps, isGuestMode: isGuestMode)
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
        await refresh(deps: deps, isGuestMode: isGuestMode)
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

    func clearAllFilters(deps: AppDependencies, isGuestMode: Bool) async {
        selectedCategoryId = nil
        selectedCategoryName = nil
        selectedAestheticTagIds = []
        selectedBrandId = nil
        selectedBrandName = nil
        selectedCountryIso2 = nil
        selectedCountryName = nil
        minPriceText = ""
        maxPriceText = ""
        selectedConditionFilter = nil
        setSizingModeFilter(nil)
        await refresh(deps: deps, isGuestMode: isGuestMode)
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
        guard categoryTree.isEmpty, !filterCatalogLoading else { return }
        filterCatalogLoading = true
        defer { filterCatalogLoading = false }
        if case .success(let tree) = await deps.commonCatalogRepository.getCategoryTree() {
            categoryTree = tree
        }
        if case .success(let tags) = await deps.commonCatalogRepository.getAestheticTags(all: true) {
            aestheticTags = tags
        }
        if case .success(let page) = await deps.commonCatalogRepository.getBrands(limit: 80) {
            brands = page.items
        }
        if case .success(let list) = await deps.commonCatalogRepository.getCountries(all: true) {
            countries = list
        }
    }

    func applyFiltersAndReload(deps: AppDependencies, isGuestMode: Bool) async {
        showFilterSheet = false
        await refresh(deps: deps, isGuestMode: isGuestMode)
    }

    private func loadListings(
        deps: AppDependencies,
        isGuestMode: Bool,
        offset: Int,
        append: Bool
    ) async {
        let gen = listingsFetchGeneration
        let q = committedListingSearchQuery.isEmpty
            ? query.trimmingCharacters(in: .whitespaces)
            : committedListingSearchQuery
        let minPrice = Int64(minPriceText.filter(\.isNumber))
        let maxPrice = Int64(maxPriceText.filter(\.isNumber))
        let tagIds = selectedAestheticTagIds.isEmpty ? nil : Array(selectedAestheticTagIds)
        let useSearch = isSearchMode && !q.isEmpty
        let sort = effectiveListingSort(query: q)
        let result: Result<[ListingFeedItem], Error>
        if !useSearch && q.isEmpty {
            result = await deps.recommendationRepository.exploreListings(
                publicBrowse: isGuestMode,
                categoryId: selectedCategoryId,
                aestheticTagIds: tagIds,
                brandId: selectedBrandId,
                minPrice: minPrice,
                maxPrice: maxPrice,
                condition: selectedConditionFilter,
                countryIso2: selectedCountryIso2,
                limit: exploreFeedPageSize,
                offset: offset,
                sizingMode: sizingModeFilter,
                surface: "explore"
            )
        } else if isGuestMode {
            result = await deps.searchRepository.browseListings(
                q: q,
                categoryId: selectedCategoryId,
                aestheticTagIds: tagIds,
                brandId: selectedBrandId,
                countryIso2: selectedCountryIso2,
                minPrice: minPrice,
                maxPrice: maxPrice,
                condition: selectedConditionFilter,
                sort: sort,
                limit: exploreFeedPageSize,
                offset: offset
            )
        } else {
            result = await deps.searchRepository.searchListings(
                q: q,
                categoryId: selectedCategoryId,
                aestheticTagIds: tagIds,
                sizingMode: sizingModeFilter,
                brandId: selectedBrandId,
                countryIso2: selectedCountryIso2,
                minPrice: minPrice,
                maxPrice: maxPrice,
                condition: selectedConditionFilter,
                sort: sort,
                limit: exploreFeedPageSize,
                offset: offset
            )
        }
        guard gen == listingsFetchGeneration else { return }
        switch result {
        case .success(let feed):
            if append {
                var seen = Set(items.map(\.id))
                let merged = items + feed.filter { seen.insert($0.id).inserted }
                items = merged
            } else {
                items = feed
            }
            hasMore = feed.count >= exploreFeedPageSize
            loadError = false
        case .failure:
            if !append {
                items = []
                loadError = true
            }
            hasMore = false
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
        guard case .success(let liked) = await deps.listingRepository.toggleLike(listingId: item.id) else { return }
        if liked {
            deps.feedEventReporter.like(listingId: item.id, surface: "explore", position: position)
        }
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

    func toggleSave(_ item: ListingFeedItem, position: Int = 0, deps: AppDependencies) async {
        guard case .success(let saved) = await deps.listingRepository.toggleSave(listingId: item.id, currentlySaved: item.isSaved) else { return }
        if saved {
            deps.feedEventReporter.save(listingId: item.id, surface: "explore", position: position)
        }
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
        isLoading = true
        loadError = false
        items = []
        hasMore = true
        if aestheticTags.isEmpty {
            if case .success(let tags) = await deps.commonCatalogRepository.getAestheticTags(all: true) {
                aestheticTags = tags
            }
        }
        if categoryTree.isEmpty {
            if case .success(let tree) = await deps.commonCatalogRepository.getCategoryTree() {
                categoryTree = tree
            }
        }
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
        selectedCategoryId = cat
        selectedCategoryName = nil
        selectedBrandId = brand
        selectedBrandName = nil
        selectedAestheticTagIds = tag.map { Set([$0]) } ?? []
        selectedCountryIso2 = countryIso2?.trimmingCharacters(in: .whitespaces).nilIfEmpty
        selectedCountryName = nil
        committedListingSearchQuery = (cat == nil && brand == nil && tag == nil) ? q : ""
        isSearchMode = !committedListingSearchQuery.isEmpty
        await refresh(deps: deps, isGuestMode: false)
        isLoading = false
    }

    /// Realtime `feed.refresh` — Android ExploreViewModel first-page reload.
    func handleFeedRefresh(deps: AppDependencies, isGuestMode: Bool) async {
        guard primarySection == .listings, !isSearchModeActive else { return }
        await refresh(deps: deps, isGuestMode: isGuestMode)
    }
}

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
