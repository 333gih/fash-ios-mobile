import SwiftUI

struct HomeFeedContent: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps
    @Bindable var viewModel: HomeViewModel
    @Bindable var listingPreview: ListingPreviewStore
    var isGuestMode: Bool

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
    ]

    var body: some View {
        ScrollView {
            if viewModel.isLoading && viewModel.items.isEmpty {
                FashSkeleton.listingGrid()
            } else if let error = viewModel.errorMessage, viewModel.items.isEmpty {
                FashEmptyStateView(
                    title: L10n.feedLoadError,
                    subtitle: error,
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
                                surface: "home",
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
        .refreshable { await viewModel.pullToRefresh(deps: deps, isGuestMode: isGuestMode) }
        .task { await viewModel.refresh(deps: deps, isGuestMode: isGuestMode) }
    }
}
