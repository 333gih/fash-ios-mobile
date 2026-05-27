import SwiftUI

struct ExploreScreen: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps
    @Bindable var viewModel: ExploreViewModel
    @Bindable var listingPreview: ListingPreviewStore
    var isGuestMode: Bool

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TextField(L10n.searchPlaceholder, text: $viewModel.query)
                .font(FashTypography.bodyMedium)
                .padding(.horizontal, spacing.spacing4)
                .padding(.vertical, spacing.spacing3)
                .background(FashColors.surfaceContainer)
                .clipShape(RoundedRectangle(cornerRadius: spacing.radiusSoftMin, style: .continuous))
                .padding(.leading, spacing.editorialStart)
                .padding(.trailing, spacing.editorialEnd)
                .padding(.top, spacing.spacing2)
                .onSubmit { Task { await viewModel.refresh(deps: deps, isGuestMode: isGuestMode) } }
            ScrollView {
                if viewModel.isLoading && viewModel.items.isEmpty {
                    FashSkeleton.listingGrid()
                } else if viewModel.loadError && viewModel.items.isEmpty {
                    FashEmptyStateView(
                        title: L10n.feedLoadError,
                        actionTitle: L10n.feedRetry
                    ) {
                        Task { await viewModel.refresh(deps: deps, isGuestMode: isGuestMode) }
                    }
                } else if viewModel.items.isEmpty {
                    FashEmptyStateView(
                        title: L10n.feedEmptyTitle,
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
                    .padding(.leading, spacing.editorialStart)
                    .padding(.trailing, spacing.editorialEnd)
                    .padding(.vertical, spacing.spacing4)
                }
            }
        }
        .task { await viewModel.refresh(deps: deps, isGuestMode: isGuestMode) }
        .refreshable { await viewModel.pullToRefresh(deps: deps, isGuestMode: isGuestMode) }
    }
}
