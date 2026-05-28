import SwiftUI

struct ExploreFilterSheet: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps
    @Bindable var viewModel: ExploreViewModel
    var isGuestMode: Bool
    var onDismiss: () -> Void

    @State private var showAestheticPicker = false

    private var categoryLeaves: [CategoryTreeNode] {
        viewModel.categoryTree.allLeaves().sorted {
            $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: spacing.spacing4) {
                    Text(L10n.exploreFiltersBarTitle)
                        .font(FashTypography.titleMedium)
                        .foregroundStyle(FashColors.textPrimary)
                    if viewModel.filterCatalogLoading {
                        ProgressView().frame(maxWidth: .infinity)
                    }
                    filterSection(L10n.exploreFilterPersonalTitle, subtitle: L10n.exploreFilterGroupPersonalSubtitle) {
                        sizingPicker
                    }
                    filterSection(L10n.exploreFilterGroupProductTitle, subtitle: L10n.exploreFilterGroupProductSubtitle) {
                        categoryPicker
                        aestheticTagsPicker
                        brandPicker
                        countryPicker
                    }
                    filterSection(L10n.exploreFilterGroupPriceTitle, subtitle: L10n.exploreFilterGroupPriceSubtitle) {
                        HStack(spacing: spacing.spacing3) {
                            TextField(L10n.exploreFilterMinHint, text: $viewModel.minPriceText)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                            TextField(L10n.exploreFilterMaxHint, text: $viewModel.maxPriceText)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                        }
                        conditionPicker
                        sortPicker
                    }
                    HStack(spacing: spacing.spacing3) {
                        Button(L10n.exploreFiltersClear) {
                            Task { await viewModel.clearAllFilters(deps: deps, isGuestMode: isGuestMode) }
                        }
                        .font(FashTypography.labelLarge)
                        Spacer()
                        FashPrimaryButton(title: L10n.exploreFilterSheetDone) {
                            Task { await viewModel.applyFiltersAndReload(deps: deps, isGuestMode: isGuestMode) }
                            onDismiss()
                        }
                        .frame(width: 140)
                    }
                }
                .padding(spacing.spacing4)
            }
            .background(FashColors.screen)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.createListingCloseCd) { onDismiss() }
                }
            }
            .task { await viewModel.loadFilterCatalogIfNeeded(deps: deps) }
            .sheet(isPresented: $showAestheticPicker) {
                ExploreAestheticTagPickerSheet(
                    tags: viewModel.aestheticTags,
                    selectedIds: $viewModel.selectedAestheticTagIds,
                    onDismiss: { showAestheticPicker = false }
                )
            }
        }
    }

    @ViewBuilder
    private func filterSection(_ title: String, subtitle: String? = nil, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: spacing.spacing2) {
            Text(title)
                .font(FashTypography.titleSmall)
                .foregroundStyle(FashColors.textPrimary)
            if let subtitle, !subtitle.isEmpty {
                Text(subtitle)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
            }
            content()
        }
    }

    private var categoryPicker: some View {
        Menu {
            Button(L10n.exploreFilterBrandAny) {
                viewModel.selectedCategoryId = nil
                viewModel.selectedCategoryName = nil
            }
            ForEach(categoryLeaves) { leaf in
                Button(leaf.name) {
                    viewModel.selectedCategoryId = leaf.id
                    viewModel.selectedCategoryName = leaf.name
                }
            }
        } label: {
            filterRowLabel(
                L10n.exploreCategorySectionTitle,
                value: viewModel.selectedCategoryName ?? L10n.exploreFilterBrandAny
            )
        }
    }

    private var aestheticTagsPicker: some View {
        Button { showAestheticPicker = true } label: {
            filterRowLabel(
                L10n.exploreFilterTeaserStyle,
                value: aestheticSummaryLabel
            )
        }
        .buttonStyle(.plain)
    }

    private var aestheticSummaryLabel: String {
        if viewModel.selectedAestheticTagIds.isEmpty { return L10n.exploreFilterAestheticNone }
        let count = viewModel.selectedAestheticTagIds.count
        if count == 1,
           let id = viewModel.selectedAestheticTagIds.first,
           let tag = viewModel.aestheticTags.first(where: { $0.id == id }) {
            return tag.displayLabel()
        }
        return L10n.exploreFilterAestheticSelectedCount(count)
    }

    private var brandPicker: some View {
        Menu {
            Button(L10n.exploreFilterBrandAny) {
                viewModel.selectedBrandId = nil
                viewModel.selectedBrandName = nil
            }
            ForEach(viewModel.brands, id: \.id) { brand in
                Button(brand.name) {
                    viewModel.selectedBrandId = brand.id
                    viewModel.selectedBrandName = brand.name
                }
            }
        } label: {
            filterRowLabel(L10n.exploreFilterBrandTitle, value: viewModel.selectedBrandName ?? L10n.exploreFilterBrandAny)
        }
    }

    private var countryPicker: some View {
        Menu {
            Button(L10n.exploreFilterCountryAny) {
                viewModel.selectedCountryIso2 = nil
                viewModel.selectedCountryName = nil
            }
            ForEach(viewModel.countries, id: \.id) { country in
                Button(country.name) {
                    viewModel.selectedCountryIso2 = country.iso2
                    viewModel.selectedCountryName = country.name
                }
            }
        } label: {
            filterRowLabel(L10n.exploreFilterCountryTitle, value: viewModel.selectedCountryName ?? L10n.exploreFilterCountryAny)
        }
    }

    private var conditionPicker: some View {
        Menu {
            Button(L10n.exploreFilterConditionAny) { viewModel.selectedConditionFilter = nil }
            conditionOption("new", L10n.conditionNew)
            conditionOption("like_new", L10n.conditionLikeNew)
            conditionOption("good", L10n.conditionGood)
            conditionOption("fair", L10n.conditionFair)
        } label: {
            filterRowLabel(
                L10n.exploreFilterConditionTitle,
                value: viewModel.selectedConditionFilter.map { ExploreFilterSheet.conditionLabel(for: $0) }
                    ?? L10n.exploreFilterConditionAny
            )
        }
    }

    private var sortPicker: some View {
        VStack(alignment: .leading, spacing: spacing.spacing1) {
            Menu {
                sortOption("recent", L10n.exploreSortRecent)
                sortOption("popular", L10n.exploreSortPopular)
                sortOption("price_asc", L10n.exploreSortPriceLow)
                sortOption("price_desc", L10n.exploreSortPriceHigh)
            } label: {
                filterRowLabel(
                    L10n.exploreFilterSortTitle,
                    value: ExploreFilterSheet.sortLabel(for: viewModel.sortMode)
                )
            }
            if !viewModel.isSearchModeActive {
                Text(L10n.exploreSortDisabledHint)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
            }
        }
    }

    private var sizingPicker: some View {
        Menu {
            Button(L10n.exploreFilterSizingAll) { viewModel.setSizingModeFilter(nil) }
            Button(L10n.exploreFilterSizingMatchProfile) {
                viewModel.setSizingModeFilter(ExploreSizingPreference.modeMatchProfile)
            }
        } label: {
            filterRowLabel(
                L10n.exploreFilterSizingTitle,
                value: viewModel.sizingModeFilter == ExploreSizingPreference.modeMatchProfile
                    ? L10n.exploreFilterSummarySizingMatch
                    : L10n.exploreFilterSizingAll
            )
        }
    }

    private func conditionOption(_ apiValue: String, _ label: String) -> some View {
        Button(label) { viewModel.selectedConditionFilter = apiValue }
    }

    private func sortOption(_ apiValue: String, _ label: String) -> some View {
        Button(label) { viewModel.sortMode = apiValue }
    }

    private func filterRowLabel(_ title: String, value: String) -> some View {
        HStack {
            Text(title)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
            Spacer()
            Text(value)
                .font(FashTypography.labelLarge)
                .foregroundStyle(FashColors.textPrimary)
                .lineLimit(1)
            Image(systemName: "chevron.down")
                .font(.system(size: 12))
                .foregroundStyle(FashColors.textSecondary)
        }
        .padding(.vertical, 8)
    }

    static func conditionLabel(for apiValue: String) -> String {
        switch apiValue.lowercased() {
        case "new": return L10n.conditionNew
        case "like_new": return L10n.conditionLikeNew
        case "good": return L10n.conditionGood
        case "fair": return L10n.conditionFair
        default: return apiValue
        }
    }

    static func sortLabel(for apiValue: String) -> String {
        switch apiValue.lowercased() {
        case "popular": return L10n.exploreSortPopular
        case "price_asc": return L10n.exploreSortPriceLow
        case "price_desc": return L10n.exploreSortPriceHigh
        default: return L10n.exploreSortRecent
        }
    }
}
