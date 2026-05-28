import SwiftUI

struct ExploreFilterSheet: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps
    @Bindable var viewModel: ExploreViewModel
    var isGuestMode: Bool
    var onDismiss: () -> Void

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
        VStack(alignment: .leading, spacing: spacing.spacing2) {
            HStack {
                Text(L10n.exploreFilterTeaserStyle)
                    .font(FashTypography.bodyMedium)
                    .foregroundStyle(FashColors.textSecondary)
                Spacer()
                if !viewModel.selectedAestheticTagIds.isEmpty {
                    Button(L10n.exploreFilterAestheticClear) {
                        viewModel.selectedAestheticTagIds = []
                    }
                    .font(FashTypography.labelMedium)
                    .foregroundStyle(FashColors.brandPrimary)
                }
            }
            if viewModel.aestheticTags.isEmpty {
                Text(L10n.exploreFilterAestheticNone)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
            } else {
                FlowLayoutTags {
                    ForEach(viewModel.aestheticTags) { tag in
                        let selected = viewModel.selectedAestheticTagIds.contains(tag.id)
                        Button {
                            if selected {
                                viewModel.selectedAestheticTagIds.remove(tag.id)
                            } else {
                                viewModel.selectedAestheticTagIds.insert(tag.id)
                            }
                        } label: {
                            Text(tag.displayLabel())
                                .font(FashTypography.labelMedium)
                                .foregroundStyle(selected ? FashColors.onBrandPrimary : FashColors.textPrimary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(selected ? FashColors.brandPrimary : FashColors.surfaceContainer)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
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

/// Simple wrapping tag layout for aesthetic filters.
private struct FlowLayoutTags<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        _FlowLayout {
            content()
        }
    }
}

private struct _FlowLayout: Layout {
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + 8
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            x += size.width + 8
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + 8
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            rowHeight = max(rowHeight, size.height)
            x += size.width + 8
        }
    }
}
