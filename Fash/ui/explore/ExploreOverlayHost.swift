import SwiftUI

/// Full-screen Explore from Home search — Android `ExploreOverlayHost`.
struct ExploreOverlayHost: View {
    @Environment(AppDependencies.self) private var deps
    @Bindable var viewModel: ExploreViewModel
    @Bindable var listingPreview: ListingPreviewStore
    var isGuestMode: Bool
    var expandSearchOnAppear: Bool = false
    var onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            ExploreTopBar(viewModel: viewModel, isGuestMode: isGuestMode, onCloseOverlay: onClose)
            ExploreScreen(
                viewModel: viewModel,
                listingPreview: listingPreview,
                isGuestMode: isGuestMode,
                hideInlineSearch: true
            )
        }
        .background(FashColors.screen)
        .task {
            if expandSearchOnAppear {
                viewModel.searchBarExpanded = true
            }
            await viewModel.loadFilterCatalogIfNeeded(deps: deps)
            await viewModel.refresh(deps: deps, isGuestMode: isGuestMode)
        }
    }
}
