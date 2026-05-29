import SwiftUI

struct ExploreTopBar: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps
    @Bindable var viewModel: ExploreViewModel
    var isGuestMode: Bool
    var animateSearchIcon: Bool = true
    var onCloseOverlay: () -> Void

    @FocusState private var searchFocused: Bool

    var body: some View {
        HStack(spacing: spacing.spacing3) {
            Button(action: handleBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(FashColors.textPrimary)
                    .frame(width: 48, height: 48)
            }
            titleOrSearch
            trailingSearchSlot
        }
        .padding(.leading, spacing.editorialStart)
        .padding(.trailing, spacing.editorialEnd)
        .background(FashColors.surface)
        .onChange(of: viewModel.searchBarExpanded) { _, expanded in
            if expanded {
                searchFocused = true
            } else {
                searchFocused = false
            }
        }
    }

    @ViewBuilder
    private var titleOrSearch: some View {
        Group {
            if viewModel.searchBarExpanded {
                searchField
            } else if animateSearchIcon {
                TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                    let flipProgress = rememberExploreTitleFlipProgress(
                        animate: true,
                        date: timeline.date
                    )
                    Button {
                        openSearch()
                    } label: {
                        ExploreTopBarFlipTitle(
                            progress: flipProgress,
                            placeholder: searchPlaceholder
                        )
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(L10n.searchLabel)
                }
            } else {
                FashScreenTitle(suffix: L10n.brandHeaderSuffixExplore)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .frame(height: 48, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 48)
        .animation(.easeInOut(duration: 0.22), value: viewModel.searchBarExpanded)
    }

    /// Fixed 48×48 slot — icon fades out while title flips to search (no bar reflow).
    @ViewBuilder
    private var trailingSearchSlot: some View {
        ZStack {
            if !viewModel.searchBarExpanded {
                if animateSearchIcon {
                    TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                        let flipProgress = rememberExploreTitleFlipProgress(
                            animate: true,
                            date: timeline.date
                        )
                        let iconOpacity = exploreTrailingSearchIconOpacity(flipProgress: flipProgress)
                        let attention = homeSearchIconAttention(at: timeline.date.timeIntervalSinceReferenceDate * 1000)
                        Button(action: openSearch) {
                            Image(systemName: "magnifyingglass")
                                .font(.system(size: 22))
                                .foregroundStyle(attention > 0.5 ? FashColors.brandPrimary : FashColors.textPrimary)
                                .scaleEffect(1 + attention * 0.14)
                                .frame(width: 48, height: 48)
                        }
                        .buttonStyle(.plain)
                        .opacity(iconOpacity)
                        .allowsHitTesting(iconOpacity > 0.12)
                        .accessibilityHidden(iconOpacity < 0.12)
                        .accessibilityLabel(L10n.searchLabel)
                    }
                } else {
                    Button(action: openSearch) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 20))
                            .foregroundStyle(FashColors.brandPrimary)
                            .frame(width: 48, height: 48)
                    }
                    .accessibilityLabel(L10n.searchLabel)
                }
            }
        }
        .frame(width: 48, height: 48)
    }

    private var searchField: some View {
        HStack(spacing: 8) {
            TextField(
                "",
                text: Binding(
                    get: { viewModel.query },
                    set: { viewModel.setSearchQuery($0, deps: deps, isGuestMode: isGuestMode) }
                ),
                prompt: Text(searchPlaceholder).foregroundStyle(FashColors.textSecondary.opacity(0.38))
            )
            .font(FashTypography.bodyMedium)
            .textFieldStyle(.plain)
            .focused($searchFocused)
            .submitLabel(.search)
            .onSubmit {
                Task { await viewModel.submitSearch(deps: deps, isGuestMode: isGuestMode) }
            }
            Button {
                Task { await viewModel.submitSearch(deps: deps, isGuestMode: isGuestMode) }
            } label: {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18))
                    .foregroundStyle(FashColors.brandPrimary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(FashColors.surfaceVariant.opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 22, style: .continuous)
                .strokeBorder(FashColors.brandPrimary.opacity(0.45), lineWidth: 1)
        )
    }

    private var searchPlaceholder: String {
        viewModel.primarySection == .sellers
            ? L10n.exploreSearchPlaceholderSellers
            : L10n.searchPlaceholder
    }

    private func openSearch() {
        viewModel.requestSearchBarExpanded()
        Task { await viewModel.loadSearchOverlayData(deps: deps) }
    }

    private func handleBack() {
        if viewModel.searchBarExpanded {
            viewModel.setSearchBarExpanded(false)
        } else {
            onCloseOverlay()
        }
    }
}
