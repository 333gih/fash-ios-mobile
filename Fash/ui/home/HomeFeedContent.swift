import SwiftUI

struct HomeFeedContent: View {
    @Environment(AppDependencies.self) private var deps
    @Bindable var viewModel: HomeViewModel
    @Bindable var listingPreview: ListingPreviewStore
    var isGuestMode: Bool

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        ScrollView {
            if viewModel.isLoading && viewModel.items.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.top, 40)
            }
            LazyVGrid(columns: columns, spacing: 16) {
                ForEach(Array(viewModel.items.enumerated()), id: \.element.id) { index, item in
                    ListingGridCard(item: item) {
                        listingPreview.open(
                            item: item,
                            deps: deps,
                            publicBrowse: isGuestMode,
                            surface: "home",
                            position: index,
                        )
                    }
                }
            }
            .padding(20)
        }
        .refreshable { await viewModel.refresh(deps: deps) }
        .task { await viewModel.refresh(deps: deps) }
    }
}
