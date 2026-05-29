import SwiftUI

/// Idle / autocomplete suggestions when Explore search bar is expanded — Android `ExploreSearchOverlay`.
struct ExploreSearchOverlay: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps
    @Bindable var viewModel: ExploreViewModel
    var isGuestMode: Bool

    private var trimmedQuery: String {
        viewModel.query.trimmingCharacters(in: .whitespaces)
    }

    private var isTyping: Bool {
        !trimmedQuery.isEmpty
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                if isTyping {
                    typingContent
                } else {
                    idleContent
                }
            }
            .padding(.bottom, 12)
        }
        .background(FashColors.screen)
        .task {
            await viewModel.loadSearchOverlayData(deps: deps)
        }
    }

    @ViewBuilder
    private var typingContent: some View {
        sectionTitle(
            viewModel.primarySection == .sellers
                ? L10n.exploreSearchSuggestionsTitleSellers
                : L10n.exploreSearchSuggestionsTitleListings
        )
        if viewModel.autocompleteLoading && viewModel.autocompleteSuggestions.isEmpty {
            ProgressView()
                .tint(FashColors.brandPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
        } else if viewModel.autocompleteSuggestions.isEmpty {
            Text(L10n.exploreSearchNoSuggestions)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
                .padding(.horizontal, spacing.editorialStart)
                .padding(.vertical, 8)
        } else {
            ForEach(viewModel.autocompleteSuggestions, id: \.self) { title in
                suggestionRow(title) {
                    Task {
                        await viewModel.selectSearchSuggestionAndSubmit(title, deps: deps, isGuestMode: isGuestMode)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var idleContent: some View {
        browseEntryRow
        if viewModel.searchOverlayLoading
            && viewModel.searchOverlayRecent.isEmpty
            && viewModel.searchOverlayTrending.isEmpty
            && viewModel.searchOverlayTrendingTags.isEmpty {
            ProgressView()
                .tint(FashColors.brandPrimary)
                .frame(maxWidth: .infinity, minHeight: 120)
        }
        if !viewModel.searchOverlayLoading
            && viewModel.searchOverlayRecent.isEmpty
            && viewModel.searchOverlayTrending.isEmpty
            && viewModel.searchOverlayTrendingTags.isEmpty {
            Text(L10n.exploreSearchIdleEmpty)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
                .padding(.horizontal, spacing.editorialStart)
                .padding(.vertical, 16)
        }
        if !viewModel.searchOverlayRecent.isEmpty {
            sectionTitle(L10n.exploreSearchRecentTitle)
            ForEach(viewModel.searchOverlayRecent, id: \.self) { q in
                suggestionRow(q) {
                    Task {
                        await viewModel.selectSearchSuggestionAndSubmit(q, deps: deps, isGuestMode: isGuestMode)
                    }
                }
            }
        }
        if !viewModel.searchOverlayTrending.isEmpty {
            sectionTitle(L10n.exploreSearchTrendingQueriesTitle)
            ForEach(viewModel.searchOverlayTrending, id: \.query) { item in
                suggestionRow(item.query) {
                    Task {
                        await viewModel.selectSearchSuggestionAndSubmit(item.query, deps: deps, isGuestMode: isGuestMode)
                    }
                }
            }
        }
        if !viewModel.searchOverlayTrendingTags.isEmpty {
            sectionTitle(L10n.exploreSearchTrendingTagsTitle)
            FlowLayoutTags(tags: viewModel.searchOverlayTrendingTags) { tag in
                Task {
                    await viewModel.selectSearchOverlayTrendingTag(tag, deps: deps, isGuestMode: isGuestMode)
                }
            }
            .padding(.horizontal, spacing.editorialStart)
            .padding(.bottom, 8)
        }
    }

    private var browseEntryRow: some View {
        Button {
            viewModel.setSearchBarExpanded(false)
        } label: {
            HStack(spacing: 10) {
                Image(systemName: "square.grid.2x2")
                    .foregroundStyle(FashColors.brandPrimary)
                Text(L10n.exploreSearchBrowseTitle)
                    .font(FashTypography.bodyMedium.weight(.semibold))
                    .foregroundStyle(FashColors.textPrimary)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(FashColors.textSecondary)
            }
            .padding(.horizontal, spacing.editorialStart)
            .padding(.vertical, 12)
        }
        .buttonStyle(.plain)
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(FashTypography.labelLarge.weight(.bold))
            .foregroundStyle(FashColors.textPrimary)
            .padding(.horizontal, spacing.editorialStart)
            .padding(.top, 14)
            .padding(.bottom, 6)
    }

    private func suggestionRow(_ title: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16))
                    .foregroundStyle(FashColors.textSecondary)
                Text(title)
                    .font(FashTypography.bodyMedium)
                    .foregroundStyle(FashColors.textPrimary)
                    .lineLimit(1)
                Spacer()
            }
            .padding(.horizontal, spacing.editorialStart)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }
}

/// Simple wrapping tag chips for trending aesthetic tags.
private struct FlowLayoutTags: View {
    let tags: [String]
    let onTag: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            var row: [String] = []
            let _ = row
            FlexibleTagWrap(tags: tags, onTag: onTag)
        }
    }
}

private struct FlexibleTagWrap: View {
    let tags: [String]
    let onTag: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(tags, id: \.self) { tag in
                Button(tag) { onTag(tag) }
                    .font(FashTypography.labelMedium)
                    .foregroundStyle(FashColors.brandPrimary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(FashColors.surfaceContainerHigh)
                    .clipShape(Capsule())
                    .buttonStyle(.plain)
            }
        }
    }
}
