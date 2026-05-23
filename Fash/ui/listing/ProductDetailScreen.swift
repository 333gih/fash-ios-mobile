import SwiftUI

struct ProductDetailScreen: View {
    @Environment(AppDependencies.self) private var deps
    let listingId: String
    var onDismiss: () -> Void
    @State private var viewModel = ProductDetailViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if viewModel.isLoading {
                        ProgressView().frame(maxWidth: .infinity, minHeight: 240)
                    } else if let item = viewModel.item {
                        FashAsyncImage(url: item.imageURL)
                            .frame(height: 320)
                            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        Text(item.title)
                            .font(FashTypography.headlineMedium)
                            .foregroundStyle(FashColors.textPrimary)
                        Text(FeedPriceFormat.format(item.price))
                            .font(FashTypography.titleMedium)
                            .foregroundStyle(FashColors.brandPrimary)
                        FashPrimaryButton(title: L10n.buyNow) {
                            // Checkout wired from RootView overlay
                        }
                    } else if let err = viewModel.errorMessage {
                        Text(err)
                            .font(FashTypography.bodyMedium)
                            .foregroundStyle(FashColors.error)
                    }
                }
                .padding(20)
            }
            .background(FashColors.screen)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onDismiss) {
                        Image(systemName: "chevron.left")
                    }
                }
            }
        }
        .task { await viewModel.load(listingId: listingId, deps: deps) }
    }
}
