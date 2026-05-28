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
    var sizingModeFilter: String?
    var sortMode = "recent"
    var categoryTree: [CategoryTreeNode] = []
    var aestheticTags: [CommonAestheticTagDto] = []
    var brands: [CommonBrandDto] = []
    var countries: [CommonCountryDto] = []
    var filterCatalogLoading = false

    private var listingsFetchGeneration = 0

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
        listingsFetchGeneration += 1
        hasMore = true
        isLoading = true
        loadError = false
        defer { isLoading = false }
        if primarySection == .sellers {
            await loadSellers(deps: deps, isGuestMode: isGuestMode, reset: true)
        } else {
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
            query = q
            committedSellerSearchQuery = q
            await loadSellers(deps: deps, isGuestMode: isGuestMode, reset: true)
            setSearchBarExpanded(false)
        }
    }

    func clearListingSearch(deps: AppDependencies, isGuestMode: Bool) async {
        isSearchMode = false
        committedListingSearchQuery = ""
        query = ""
        await refresh(deps: deps, isGuestMode: isGuestMode)
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
        sizingModeFilter = nil
        await refresh(deps: deps, isGuestMode: isGuestMode)
    }

    func setPrimarySection(_ section: ExplorePrimarySection, deps: AppDependencies, isGuestMode: Bool) async {
        primarySection = section
        await refresh(deps: deps, isGuestMode: isGuestMode)
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
                sizingMode: sizingModeFilter
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
                sort: sortMode,
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
                sort: sortMode,
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

    private func loadSellers(deps: AppDependencies, isGuestMode: Bool, reset: Bool) async {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else {
            sellerResults = []
            loadError = false
            return
        }
        if reset { isLoading = true }
        defer { if reset { isLoading = false } }
        switch await deps.userRepository.searchUsers(query: q, limit: 40, publicBrowse: isGuestMode) {
        case .success(let users):
            sellerResults = users
            loadError = false
        case .failure:
            sellerResults = []
            loadError = true
        }
    }
}
