import SwiftUI

struct HomeFeedContent: View {
    @Environment(AppDependencies.self) private var deps
    @Bindable var viewModel: HomeViewModel
    var onListingTap: (String) -> Void

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
                ForEach(viewModel.items) { item in
                    ListingGridCard(item: item) {
                        onListingTap(item.id)
                    }
                }
            }
            .padding(20)
        }
        .refreshable { await viewModel.refresh(deps: deps) }
        .task { await viewModel.refresh(deps: deps) }
    }
}
