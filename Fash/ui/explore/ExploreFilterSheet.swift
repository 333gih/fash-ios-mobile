import SwiftUI

struct ExploreFilterSheet: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps
    @Bindable var viewModel: ExploreViewModel
    var isGuestMode: Bool
    var onDismiss: () -> Void

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
                    filterSection(L10n.exploreFilterGroupProductTitle) {
                        categoryPicker
                        brandPicker
                        countryPicker
                        conditionPicker
                    }
                    filterSection(L10n.exploreFilterGroupPriceTitle) {
                        HStack(spacing: spacing.spacing3) {
                            TextField(L10n.exploreFilterMinHint, text: $viewModel.minPriceText)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                            TextField(L10n.exploreFilterMaxHint, text: $viewModel.maxPriceText)
                                .keyboardType(.numberPad)
                                .textFieldStyle(.roundedBorder)
                        }
                    }
                    filterSection(L10n.exploreFilterPersonalTitle) {
                        sizingPicker
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
    private func filterSection(_ title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: spacing.spacing2) {
            Text(title)
                .font(FashTypography.titleSmall)
                .foregroundStyle(FashColors.textPrimary)
            content()
        }
    }

    private var categoryPicker: some View {
        Menu {
            Button(L10n.exploreFilterBrandAny) {
                viewModel.selectedCategoryId = nil
                viewModel.selectedCategoryName = nil
            }
            ForEach(viewModel.categoryTree, id: \.id) { root in
                Button(root.name) {
                    viewModel.selectedCategoryId = root.id
                    viewModel.selectedCategoryName = root.name
                }
            }
        } label: {
            filterRowLabel(
                L10n.exploreCategorySectionTitle,
                value: viewModel.selectedCategoryName ?? L10n.exploreFilterBrandAny
            )
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
            ForEach(["new", "like_new", "good", "fair"], id: \.self) { c in
                Button(c) { viewModel.selectedConditionFilter = c }
            }
        } label: {
            filterRowLabel(
                L10n.exploreFilterConditionTitle,
                value: viewModel.selectedConditionFilter ?? L10n.exploreFilterConditionAny
            )
        }
    }

    private var sizingPicker: some View {
        Menu {
            Button(L10n.exploreFilterSizingAll) { viewModel.sizingModeFilter = nil }
            Button(L10n.exploreFilterSizingMatchProfile) { viewModel.sizingModeFilter = "match_profile" }
        } label: {
            filterRowLabel(
                L10n.exploreFilterSizingTitle,
                value: viewModel.sizingModeFilter == "match_profile"
                    ? L10n.exploreFilterSummarySizingMatch
                    : L10n.exploreFilterSizingAll
            )
        }
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
            Image(systemName: "chevron.down")
                .font(.system(size: 12))
                .foregroundStyle(FashColors.textSecondary)
        }
        .padding(.vertical, 8)
    }
}
