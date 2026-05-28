import SwiftUI

struct ProductDetailScreen: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps
    let listingId: String
    var onDismiss: () -> Void
    var onBuyNow: (String) -> Void = { _ in }
    var onChat: (String) -> Void = { _ in }
    var onVisitSellerShop: (String) -> Void = { _ in }

    @State private var viewModel = ProductDetailViewModel()

    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                VStack(alignment: .leading, spacing: spacing.spacing3) {
                    if viewModel.isLoading {
                        ProgressView().frame(maxWidth: .infinity, minHeight: 320)
                    } else if let item = viewModel.item {
                        imageGallery
                        titlePriceSection(item)
                        metaChips(item)
                        if let description = viewModel.preview?.description ?? Optional(item.descriptionText),
                           !description.isEmpty {
                            VStack(alignment: .leading, spacing: 8) {
                                Text(L10n.productSectionDescription)
                                    .font(FashTypography.titleSmall.weight(.semibold))
                                Text(description)
                                    .font(FashTypography.bodyMedium)
                                    .foregroundStyle(FashColors.textSecondary)
                            }
                        }
                        sellerSection(item)
                        Spacer(minLength: 100)
                    } else if let err = viewModel.errorMessage {
                        FashEmptyStateView(title: err, actionTitle: L10n.feedRetry) {
                            Task { await viewModel.load(listingId: listingId, deps: deps) }
                        }
                    }
                }
                .padding(.horizontal, spacing.editorialStart)
                .padding(.top, 56)
                .padding(.bottom, 24)
            }
            topBar
        }
        .background(FashColors.screen)
        .safeAreaInset(edge: .bottom) {
            if viewModel.item != nil, !viewModel.isSold {
                bottomBar
            }
        }
        .task(id: listingId) {
            await viewModel.load(listingId: listingId, deps: deps)
        }
    }

    private var topBar: some View {
        HStack {
            Button(action: onDismiss) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(FashColors.textPrimary)
                    .frame(width: 44, height: 44)
                    .background(FashColors.screen.opacity(0.85))
                    .clipShape(Circle())
            }
            Spacer()
            if viewModel.item != nil {
                HStack(spacing: 8) {
                    circleIconButton(
                        viewModel.isLiked ? "heart.fill" : "heart",
                        highlighted: viewModel.isLiked
                    ) {
                        Task { await viewModel.toggleLike(deps: deps) }
                    }
                    circleIconButton(
                        viewModel.isSaved ? "bookmark.fill" : "bookmark",
                        highlighted: viewModel.isSaved
                    ) {
                        Task { await viewModel.toggleSave(deps: deps) }
                    }
                }
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 4)
    }

    private func circleIconButton(_ systemName: String, highlighted: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .foregroundStyle(highlighted ? FashColors.brandPrimary : FashColors.textPrimary)
                .frame(width: 44, height: 44)
                .background(FashColors.screen.opacity(0.9))
                .clipShape(Circle())
        }
    }

    @ViewBuilder
    private var imageGallery: some View {
        let urls = viewModel.resolvedImageUrls
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        if urls.isEmpty {
            Rectangle()
                .fill(FashColors.surfaceContainerHigh)
                .frame(height: 360)
                .clipShape(shape)
        } else if urls.count == 1 {
            FashAsyncImage(url: urls[0], contentMode: .fill)
                .frame(height: 360)
                .clipShape(shape)
        } else {
            let safeIndex = min(max(viewModel.galleryIndex, 0), urls.count - 1)
            TabView(selection: Binding(
                get: { safeIndex },
                set: { viewModel.galleryIndex = $0 }
            )) {
                ForEach(Array(urls.enumerated()), id: \.offset) { index, url in
                    FashAsyncImage(url: url, contentMode: .fill)
                        .frame(height: 360)
                        .clipShape(shape)
                        .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .automatic))
            .frame(height: 380)
        }
    }

    private func titlePriceSection(_ item: ListingFeedItem) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.preview?.title ?? item.title)
                .font(FashTypography.headlineSmall.weight(.bold))
                .foregroundStyle(FashColors.textPrimary)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(FeedPriceFormat.format(viewModel.preview?.priceVnd ?? item.priceVnd))
                    .font(FashTypography.titleLarge)
                    .foregroundStyle(FashColors.brandPrimary)
                if let original = viewModel.preview?.listPriceVnd, original > item.priceVnd {
                    Text(FeedPriceFormat.format(original))
                        .font(FashTypography.bodyMedium)
                        .foregroundStyle(FashColors.textSecondary)
                        .strikethrough()
                }
            }
            if let fee = viewModel.preview?.estimatedShippingVnd, fee > 0 {
                Text(L10n.productShippingEstimate(FeedPriceFormat.format(fee)))
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
            }
        }
    }

    private func metaChips(_ item: ListingFeedItem) -> some View {
        let chips: [String] = [
            viewModel.preview?.condition ?? item.condition,
            viewModel.preview?.size ?? item.size,
            viewModel.preview?.brand ?? item.brand,
            viewModel.preview?.category ?? item.categoryName,
        ].compactMap { $0?.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
        return Group {
            if !chips.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(chips, id: \.self) { chip in
                            Text(chip)
                                .font(FashTypography.labelMedium)
                                .foregroundStyle(FashColors.textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(FashColors.surfaceContainer)
                                .clipShape(Capsule())
                        }
                    }
                }
            }
        }
    }

    private func sellerSection(_ item: ListingFeedItem) -> some View {
        Button {
            if let u = item.sellerUsername, !u.isEmpty { onVisitSellerShop(u) }
        } label: {
            HStack(spacing: 12) {
                FashAvatarCircle(url: viewModel.sellerAvatarUrl, size: 48)
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.sellerDisplayName)
                        .font(FashTypography.titleSmall.weight(.semibold))
                        .foregroundStyle(FashColors.textPrimary)
                    if let username = item.sellerUsername, !username.isEmpty {
                        Text("@\(username)")
                            .font(FashTypography.bodySmall)
                            .foregroundStyle(FashColors.textSecondary)
                    }
                }
                Spacer()
                if let u = item.sellerUsername, !u.isEmpty {
                    Text(L10n.productVisitShop)
                        .font(FashTypography.labelLarge)
                        .foregroundStyle(FashColors.brandPrimary)
                }
            }
            .padding(14)
            .background(FashColors.surfaceContainer)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    private var bottomBar: some View {
        VStack(spacing: 10) {
            FashPrimaryButton(title: L10n.buyNow) {
                if let id = viewModel.item?.id { onBuyNow(id) }
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
                .font(FashTypography.labelLarge.weight(.semibold))
                .foregroundStyle(FashColors.brandPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(FashColors.brandPrimary, lineWidth: 1)
                )
            }
            .disabled(viewModel.isOpeningChat)
        }
        .padding(.horizontal, spacing.editorialStart)
        .padding(.vertical, 12)
        .background(FashColors.surfaceContainerHighest)
    }
}
