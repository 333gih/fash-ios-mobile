import SwiftUI

struct ExploreScreen: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps
    @Bindable var viewModel: ExploreViewModel
    @Bindable var listingPreview: ListingPreviewStore
    var isGuestMode: Bool
    var hideInlineSearch: Bool = false

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
    ]

    var body: some View {
        VStack(spacing: 0) {
            if !hideInlineSearch {
                searchRow
            }
            sectionToggle
            filterBar
            content
        }
        .task { await viewModel.refresh(deps: deps, isGuestMode: isGuestMode) }
        .refreshable { await viewModel.pullToRefresh(deps: deps, isGuestMode: isGuestMode) }
        .sheet(isPresented: $viewModel.showFilterSheet) {
            ExploreFilterSheet(viewModel: viewModel, isGuestMode: isGuestMode) {
                viewModel.showFilterSheet = false
            }
        }
    }

    private var searchRow: some View {
        TextField(L10n.searchPlaceholder, text: $viewModel.query)
            .font(FashTypography.bodyMedium)
            .padding(.horizontal, spacing.spacing4)
            .padding(.vertical, spacing.spacing3)
            .background(FashColors.surfaceContainer)
            .clipShape(RoundedRectangle(cornerRadius: spacing.radiusSoftMin, style: .continuous))
            .padding(.horizontal, spacing.editorialStart)
            .padding(.top, spacing.spacing2)
            .onSubmit { Task { await viewModel.submitSearch(deps: deps, isGuestMode: isGuestMode) } }
    }

    private var sectionToggle: some View {
        HStack(spacing: spacing.spacing2) {
            sectionButton(L10n.exploreSectionListings, .listings)
            sectionButton(L10n.exploreSectionSellers, .sellers)
            Spacer()
        }
        .padding(.horizontal, spacing.editorialStart)
        .padding(.top, spacing.spacing2)
    }

    private func sectionButton(_ title: String, _ section: ExplorePrimarySection) -> some View {
        let selected = viewModel.primarySection == section
        return Button {
            Task { await viewModel.setPrimarySection(section, deps: deps, isGuestMode: isGuestMode) }
        } label: {
            Text(title)
                .font(FashTypography.labelLarge)
                .foregroundStyle(selected ? FashColors.brandPrimary : FashColors.textSecondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(selected ? FashColors.surfaceContainerHigh : Color.clear)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
    }

    private var filterBar: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.exploreFiltersBarTitle)
                    .font(FashTypography.labelLarge)
                    .foregroundStyle(FashColors.textPrimary)
                Text(viewModel.hasActiveFilters ? L10n.exploreFiltersBarSubtitleActive : L10n.exploreFiltersBarSubtitleIdle)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
            }
            Spacer()
            Button {
                viewModel.showFilterSheet = true
            } label: {
                Image(systemName: "line.3.horizontal.decrease.circle")
                    .font(.system(size: 22))
                    .foregroundStyle(FashColors.textPrimary)
            }
            if viewModel.hasActiveFilters {
                Button(L10n.exploreFiltersClear) {
                    Task { await viewModel.clearAllFilters(deps: deps, isGuestMode: isGuestMode) }
                }
                .font(FashTypography.labelMedium)
            }
        }
        .padding(.horizontal, spacing.editorialStart)
        .padding(.vertical, spacing.spacing2)
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.primarySection == .listings {
            ExploreCategoryStrip(
                roots: viewModel.categoryTree,
                selectedId: viewModel.selectedCategoryId
            ) { node in
                viewModel.selectedCategoryId = node?.id
                viewModel.selectedCategoryName = node?.name
                Task { await viewModel.refresh(deps: deps, isGuestMode: isGuestMode) }
            }
            listingsGrid
        } else {
            sellersList
        }
    }

    private var listingsGrid: some View {
        ScrollView {
            if viewModel.isLoading && viewModel.items.isEmpty {
                FashSkeleton.listingGrid()
            } else if viewModel.loadError && viewModel.items.isEmpty {
                FashEmptyStateView(title: L10n.feedLoadError, actionTitle: L10n.feedRetry) {
                    Task { await viewModel.refresh(deps: deps, isGuestMode: isGuestMode) }
                }
            } else if viewModel.items.isEmpty {
                FashEmptyStateView(
                    title: viewModel.hasActiveFilters ? L10n.exploreEmptyFilteredTitle : L10n.feedEmptyTitle,
                    subtitle: L10n.feedEmptySubtitle
                )
            } else {
                LazyVGrid(columns: columns, spacing: 12) {
                    ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                        ListingGridCard(item: item) {
                            listingPreview.open(
                                item: item,
                                deps: deps,
                                publicBrowse: isGuestMode,
                                surface: "explore",
                                position: index
                            )
                        }
                    }
                }
                .padding(.horizontal, spacing.editorialStart)
                .padding(.vertical, spacing.spacing4)
            }
        }
    }

    private var sellersList: some View {
        ScrollView {
            if viewModel.sellerResults.isEmpty {
                FashEmptyStateView(title: L10n.searchPlaceholder, subtitle: L10n.feedEmptySubtitle)
                    .padding()
            } else {
                LazyVStack(spacing: spacing.spacing3) {
                    ForEach(viewModel.sellerResults) { seller in
                        HStack(spacing: spacing.spacing3) {
                            FashAsyncImage(url: seller.avatarUrl, contentMode: .fill)
                                .frame(width: 44, height: 44)
                                .clipShape(Circle())
                            VStack(alignment: .leading, spacing: 2) {
                                Text(seller.displayName.isEmpty ? seller.username : seller.displayName)
                                    .font(FashTypography.labelLarge)
                                    .foregroundStyle(FashColors.textPrimary)
                                if !seller.username.isEmpty {
                                    Text("@\(seller.username)")
                                        .font(FashTypography.bodySmall)
                                        .foregroundStyle(FashColors.textSecondary)
                                }
                            }
                            Spacer()
                        }
                        .padding(.horizontal, spacing.editorialStart)
                    }
                }
                .padding(.vertical, spacing.spacing4)
            }
        }
    }
}
