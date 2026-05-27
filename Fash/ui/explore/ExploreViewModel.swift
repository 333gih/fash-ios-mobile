import Foundation
import Observation

enum ExplorePrimarySection: String, CaseIterable {
    case listings
    case sellers
}

@Observable
@MainActor
final class ExploreViewModel {
    var query = ""
    var items: [ListingFeedItem] = []
    var sellerResults: [UserSearchResult] = []
    var primarySection: ExplorePrimarySection = .listings
    var isLoading = false
    var isRefreshing = false
    var loadError = false
    var showFilterSheet = false
    var searchBarExpanded = false

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
    var committedListingSearchQuery = ""

    // Filter catalog
    var categoryTree: [CategoryTreeNode] = []
    var aestheticTags: [CommonAestheticTagDto] = []
    var brands: [CommonBrandDto] = []
    var countries: [CommonCountryDto] = []
    var filterCatalogLoading = false

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

    func refresh(deps: AppDependencies, isGuestMode: Bool) async {
        isLoading = true
        loadError = false
        defer { isLoading = false }
        if primarySection == .sellers {
            await loadSellers(deps: deps, isGuestMode: isGuestMode)
        } else {
            await loadListings(deps: deps, isGuestMode: isGuestMode)
        }
    }

    func pullToRefresh(deps: AppDependencies, isGuestMode: Bool) async {
        isRefreshing = true
        defer { isRefreshing = false }
        await refresh(deps: deps, isGuestMode: isGuestMode)
    }

    func submitSearch(deps: AppDependencies, isGuestMode: Bool) async {
        committedListingSearchQuery = query.trimmingCharacters(in: .whitespaces)
        await refresh(deps: deps, isGuestMode: isGuestMode)
    }

    func clearListingSearch(deps: AppDependencies, isGuestMode: Bool) async {
        query = ""
        committedListingSearchQuery = ""
        await refresh(deps: deps, isGuestMode: isGuestMode)
    }

    func setPrimarySection(_ section: ExplorePrimarySection, deps: AppDependencies, isGuestMode: Bool) async {
        primarySection = section
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

    private func loadListings(deps: AppDependencies, isGuestMode: Bool) async {
        let q = committedListingSearchQuery.isEmpty ? query.trimmingCharacters(in: .whitespaces) : committedListingSearchQuery
        let minPrice = Int64(minPriceText.filter(\.isNumber))
        let maxPrice = Int64(maxPriceText.filter(\.isNumber))
        let tagIds = selectedAestheticTagIds.isEmpty ? nil : Array(selectedAestheticTagIds)
        let result: Result<[ListingFeedItem], Error>
        if q.isEmpty {
            result = await deps.recommendationRepository.exploreListings(
                publicBrowse: isGuestMode,
                categoryId: selectedCategoryId,
                aestheticTagIds: tagIds,
                brandId: selectedBrandId,
                minPrice: minPrice,
                maxPrice: maxPrice,
                condition: selectedConditionFilter,
                countryIso2: selectedCountryIso2,
                limit: 40,
                offset: 0,
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
                limit: 40,
                offset: 0
            )
        } else {
            result = await deps.searchRepository.searchListings(
                q: q,
                categoryId: selectedCategoryId,
                aestheticTagIds: tagIds,
                brandId: selectedBrandId,
                countryIso2: selectedCountryIso2,
                minPrice: minPrice,
                maxPrice: maxPrice,
                condition: selectedConditionFilter,
                sort: sortMode,
                limit: 40,
                offset: 0,
                sizingMode: sizingModeFilter
            )
        }
        switch result {
        case .success(let feed):
            items = feed
            loadError = false
        case .failure:
            items = []
            loadError = true
        }
    }

    private func loadSellers(deps: AppDependencies, isGuestMode: Bool) async {
        let q = query.trimmingCharacters(in: .whitespaces)
        guard !q.isEmpty else {
            sellerResults = []
            loadError = false
            return
        }
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
