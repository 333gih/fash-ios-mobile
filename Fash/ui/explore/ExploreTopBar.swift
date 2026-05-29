import SwiftUI

struct ExploreTopBar: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps
    @Bindable var viewModel: ExploreViewModel
    var isGuestMode: Bool
    /// Subtle pulse on the trailing search icon (no title flip).
    var animateSearchIcon: Bool = true
    /// Compact search chip when the feed header has scrolled away.
    var compact: Bool = false
    var onCloseOverlay: () -> Void

    @FocusState private var searchFocused: Bool

    private enum TitleSlot: Equatable {
        case idle
        case compact
        case expanded
    }

    private var titleSlot: TitleSlot {
        if viewModel.searchBarExpanded { return .expanded }
        if compact { return .compact }
        return .idle
    }

    var body: some View {
        HStack(alignment: .center, spacing: spacing.spacing2) {
            FashBackButton(style: .navigation, action: handleBack)
            titleOrSearch
            trailingSearchSlot
        }
        .frame(minHeight: 48)
        .padding(.leading, FashBackButton.leadingScreenInset)
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
            switch titleSlot {
            case .idle:
                idleTitle
            case .compact:
                compactSearchChip
            case .expanded:
                searchField
            }
        }
        .id(titleSlot)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 48)
        .animation(exploreTopBarContentAnimation, value: titleSlot)
    }

    /// Static brand lockup — Android collapsed `TopAppBar` title (no periodic flip).
    private var idleTitle: some View {
        FashScreenTitle(suffix: L10n.brandHeaderSuffixExplore)
            .frame(maxWidth: .infinity, alignment: .leading)
            .frame(height: 48, alignment: .leading)
            .accessibilityElement(children: .combine)
    }

    private var compactSearchChip: some View {
        Button(action: openSearch) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(FashColors.brandPrimary)
                Text(searchPlaceholder)
                    .font(FashTypography.bodyMedium)
                    .foregroundStyle(FashColors.textSecondary.opacity(0.72))
                    .lineLimit(1)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(FashColors.surfaceVariant.opacity(0.38))
            .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(FashColors.outlineMuted.opacity(0.35), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.searchLabel)
    }

    @ViewBuilder
    private var trailingSearchSlot: some View {
        ZStack {
            if titleSlot == .idle {
                searchIconButton
            }
        }
        .frame(width: 48, height: 48)
    }

    private var searchIconButton: some View {
        Button(action: openSearch) {
            Group {
                if animateSearchIcon {
                    TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
                        let attention = homeSearchIconAttention(
                            at: timeline.date.timeIntervalSinceReferenceDate * 1000
                        )
                        searchIconImage
                            .scaleEffect(1 + attention * 0.1)
                    }
                } else {
                    searchIconImage
                }
            }
            .frame(width: 48, height: 48)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.searchLabel)
    }

    private var searchIconImage: some View {
        Image(systemName: "magnifyingglass")
            .font(.system(size: 22, weight: .medium))
            .foregroundStyle(FashColors.brandPrimary)
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
        .accessibilityLabel(L10n.searchLabel)
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

// MARK: - Transitions (Material `AnimatedContent` fade — Android ExploreTopBar)

private var exploreTopBarContentAnimation: Animation {
    .easeInOut(duration: 0.22)
}

private var exploreTopBarContentTransition: AnyTransition {
    .asymmetric(
        insertion: .opacity.combined(with: .scale(scale: 0.98, anchor: .leading)),
        removal: .opacity.combined(with: .scale(scale: 0.98, anchor: .leading))
    )
}
