import SwiftUI

struct ProductDetailScreen: View {
    @Environment(AppDependencies.self) private var deps
    let listingId: String
    var onDismiss: () -> Void
    var onBuyNow: (String) -> Void = { _ in }
    var onChat: (String) -> Void = { _ in }
    var onVisitSellerShop: (String) -> Void = { _ in }

    @State private var viewModel = ProductDetailViewModel()

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    if viewModel.isLoading {
                        ProgressView().frame(maxWidth: .infinity, minHeight: 240)
                    } else if let item = viewModel.item {
                        imageGallery
                        Text(item.title)
                            .font(FashTypography.headlineMedium)
                            .foregroundStyle(FashColors.textPrimary)
                        Text(FeedPriceFormat.format(item.priceVnd))
                            .font(FashTypography.titleMedium)
                            .foregroundStyle(FashColors.brandPrimary)
                        if !item.descriptionText.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(L10n.productSectionDescription)
                                    .font(FashTypography.titleSmall)
                                    .foregroundStyle(FashColors.textPrimary)
                                Text(item.descriptionText)
                                    .font(FashTypography.bodyMedium)
                                    .foregroundStyle(FashColors.textSecondary)
                            }
                        }
                        sellerSection(item)
                        actionButtons(item)
                    } else if let err = viewModel.errorMessage {
                        FashEmptyStateView(title: err, actionTitle: L10n.feedRetry) {
                            Task { await viewModel.load(listingId: listingId, deps: deps) }
                        }
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
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: 12) {
                        Button {
                            Task { await viewModel.toggleLike(deps: deps) }
                        } label: {
                            Image(systemName: viewModel.isLiked ? "heart.fill" : "heart")
                                .foregroundStyle(viewModel.isLiked ? FashColors.brandPrimary : FashColors.textPrimary)
                        }
                        Button {
                            Task { await viewModel.toggleSave(deps: deps) }
                        } label: {
                            Image(systemName: viewModel.isSaved ? "bookmark.fill" : "bookmark")
                                .foregroundStyle(viewModel.isSaved ? FashColors.brandPrimary : FashColors.textPrimary)
                        }
                    }
                }
            }
        }
        .task(id: listingId) {
            await viewModel.load(listingId: listingId, deps: deps)
        }
    }

    @ViewBuilder
    private var imageGallery: some View {
        let urls = viewModel.imageUrls
        if urls.isEmpty {
            Rectangle()
                .fill(FashColors.surfaceContainerHigh)
                .frame(height: 320)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        } else if urls.count == 1 {
            FashAsyncImage(url: urls[0])
                .frame(height: 320)
                .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        } else {
            TabView(selection: $viewModel.galleryIndex) {
                ForEach(Array(urls.enumerated()), id: \.offset) { index, url in
                    FashAsyncImage(url: url)
                        .frame(height: 320)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .frame(height: 340)
        }
    }

    private func sellerSection(_ item: ListingFeedItem) -> some View {
        HStack(spacing: 12) {
            FashAvatarCircle(url: nil, size: 44)
            VStack(alignment: .leading, spacing: 2) {
                Text(item.sellerUsername.map { "@\($0)" } ?? L10n.navProfile)
                    .font(FashTypography.titleSmall)
                    .foregroundStyle(FashColors.textPrimary)
                if let sellerUsername = item.sellerUsername, !sellerUsername.isEmpty {
                    Button(L10n.productVisitShop) {
                        onVisitSellerShop(sellerUsername)
                    }
                    .font(FashTypography.labelLarge)
                    .foregroundStyle(FashColors.brandPrimary)
                }
            }
            Spacer()
        }
        .padding(14)
        .background(FashColors.surfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    }

    private func actionButtons(_ item: ListingFeedItem) -> some View {
        VStack(spacing: 12) {
            FashPrimaryButton(title: L10n.buyNow) {
                onBuyNow(item.id)
            }
            Button {
                Task {
                    if let convId = await viewModel.openChat(deps: deps) {
                        onChat(convId)
                    }
                }
            } label: {
                HStack {
                    if viewModel.isOpeningChat { ProgressView().scaleEffect(0.8) }
                    Text(L10n.productChat)
                }
                .font(FashTypography.labelLarge)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(FashColors.surfaceContainer)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            }
            .disabled(viewModel.isOpeningChat)
        }
    }
}
