import SwiftUI

struct ExploreScreen: View {
    @Environment(AppDependencies.self) private var deps
    @Bindable var viewModel: ExploreViewModel
    var onListingTap: (String) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12),
    ]

    var body: some View {
        VStack(spacing: 0) {
            TextField(L10n.searchPlaceholder, text: $viewModel.query)
                .padding(12)
                .background(FashColors.surfaceContainer)
                .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .onSubmit { Task { await viewModel.refresh(deps: deps) } }
            ScrollView {
                LazyVGrid(columns: columns, spacing: 16) {
                    ForEach(viewModel.items) { item in
                        ListingGridCard(item: item) { onListingTap(item.id) }
                    }
                }
                .padding(20)
            }
        }
        .task { await viewModel.refresh(deps: deps) }
        .refreshable { await viewModel.refresh(deps: deps) }
    }
}
