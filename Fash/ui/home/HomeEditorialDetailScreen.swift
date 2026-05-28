import SwiftUI

struct HomeEditorialDetailScreen: View {
    @Environment(\.fashSpacing) private var spacing
    var slug: String = ""
    var onDismiss: () -> Void = {}

    @State private var viewModel = HomeEditorialDetailViewModel()

    var body: some View {
        FashScreenScaffold(
            title: screenTitle,
            showBack: true,
            onBack: onDismiss
        ) {
            Group {
                if viewModel.loading {
                    ProgressView()
                        .tint(FashColors.brandPrimary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.error || viewModel.guide == nil {
                    FashEmptyStateView(
                        title: L10n.feedLoadError,
                        systemImage: "exclamationmark.triangle"
                    )
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let guide = viewModel.guide {
                    ScrollView {
                        VStack(alignment: .leading, spacing: spacing.spacing3) {
                            if let cover = FeedImageUrl.resolveListingImageUrlOrNil(guide.coverImageUrl) {
                                FashAsyncImage(url: cover, contentMode: .fill)
                                    .frame(maxWidth: .infinity)
                                    .aspectRatio(16 / 9, contentMode: .fill)
                                    .clipShape(RoundedRectangle(cornerRadius: spacing.radiusCard, style: .continuous))
                            }
                            Text(guide.title)
                                .font(FashTypography.headlineSmall.weight(.bold))
                                .foregroundStyle(FashColors.textPrimary)
                            if !guide.summary.isEmpty {
                                Text(guide.summary)
                                    .font(FashTypography.bodyLarge)
                                    .foregroundStyle(FashColors.textSecondary)
                            }
                            EditorialMarkdownBody(markdown: guide.bodyMarkdown)
                        }
                        .padding(.horizontal, spacing.editorialStart)
                        .padding(.vertical, spacing.spacing3)
                    }
                }
            }
            .background(FashColors.screen)
        }
        .task(id: slug) { await viewModel.load(slug: slug) }
    }

    private var screenTitle: String {
        guard let t = viewModel.guide?.title, !t.isEmpty else { return L10n.homeSectionEditorialTitle }
        return String(t.prefix(48))
    }
}

struct EditorialMarkdownBody: View {
    let markdown: String

    var body: some View {
        let blocks = markdown
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        VStack(alignment: .leading, spacing: 12) {
            ForEach(Array(blocks.enumerated()), id: \.offset) { _, block in
                if block.hasPrefix("## ") {
                    Text(block.dropFirst(3).trimmingCharacters(in: .whitespaces))
                        .font(FashTypography.titleMedium.weight(.semibold))
                        .foregroundStyle(FashColors.textPrimary)
                } else {
                    Text(block.replacingOccurrences(of: "**", with: "").replacingOccurrences(of: "*", with: ""))
                        .font(FashTypography.bodyMedium)
                        .foregroundStyle(FashColors.textPrimary)
                }
            }
        }
    }
}
