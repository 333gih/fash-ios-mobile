import SwiftUI

struct HomeEditorialListScreen: View {
    @Environment(\.fashSpacing) private var spacing
    var onDismiss: () -> Void = {}
    var onPostClick: (HomeEditorialPostStub) -> Void = { _ in }

    @State private var viewModel = HomeEditorialListViewModel()

    var body: some View {
        FashScreenScaffold(title: L10n.homeEditorialListTitle, showBack: true, onBack: onDismiss) {
            Group {
                if viewModel.loading, viewModel.posts.isEmpty {
                    ProgressView()
                        .tint(FashColors.brandPrimary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.error, viewModel.posts.isEmpty {
                    FashEmptyStateView(
                        title: L10n.feedLoadError,
                        systemImage: "exclamationmark.triangle"
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        LazyVStack(alignment: .leading, spacing: spacing.spacing2) {
                            Text(L10n.homeEditorialListSubtitle)
                                .font(FashTypography.bodyMedium)
                                .foregroundStyle(FashColors.textSecondary)
                                .padding(.bottom, spacing.spacing2)

                            ForEach(Array(viewModel.posts.enumerated()), id: \.element.listId) { index, post in
                                EditorialGuideListCard(post: post) {
                                    onPostClick(post)
                                }
                                .onAppear {
                                    Task { await viewModel.loadMoreIfNeeded(currentIndex: index) }
                                }
                            }

                            if viewModel.loadingMore {
                                ProgressView()
                                    .tint(FashColors.brandPrimary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 16)
                            }
                        }
                        .padding(.horizontal, spacing.editorialStart)
                        .padding(.vertical, spacing.spacing3)
                    }
                }
            }
            .background(FashColors.screen)
        }
        .task { await viewModel.loadInitial() }
    }
}

private struct EditorialGuideListCard: View {
    @Environment(\.fashSpacing) private var spacing
    let post: HomeEditorialPostStub
    let onClick: () -> Void

    var body: some View {
        Button(action: onClick) {
            VStack(alignment: .leading, spacing: 0) {
                cover
                VStack(alignment: .leading, spacing: 4) {
                    Text(post.title.isEmpty ? post.slug : post.title)
                        .font(FashTypography.titleSmall.weight(.bold))
                        .foregroundStyle(FashColors.textPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.leading)
                    if !post.summary.isEmpty {
                        Text(post.summary)
                            .font(FashTypography.bodySmall)
                            .foregroundStyle(FashColors.textSecondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                    Text(L10n.homeEditorialViewDetail)
                        .font(FashTypography.labelMedium.weight(.semibold))
                        .foregroundStyle(FashColors.brandPrimary)
                }
                .padding(.horizontal, spacing.spacing3)
                .padding(.vertical, spacing.spacing2)
            }
            .background(FashColors.surfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: spacing.radiusCard, style: .continuous))
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var cover: some View {
        let url = post.coverImageUrl.flatMap { FeedImageUrl.resolveListingImageUrlOrNil($0) }
        Group {
            if let url {
                FashAsyncImage(url: url, contentMode: .fill)
            } else {
                FashColors.surfaceVariant
            }
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(16 / 9, contentMode: .fill)
        .clipped()
    }
}
