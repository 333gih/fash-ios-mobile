import SwiftUI

struct ExploreTopBar: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps
    @Bindable var viewModel: ExploreViewModel
    var isGuestMode: Bool
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
            Group {
                if viewModel.searchBarExpanded {
                    searchField
                } else {
                    FashScreenTitle(suffix: L10n.brandHeaderSuffixExplore)
                }
            }
            .animation(.easeInOut(duration: 0.22), value: viewModel.searchBarExpanded)
            Spacer(minLength: 0)
            if !viewModel.searchBarExpanded {
                Button {
                    viewModel.requestSearchBarExpanded()
                    Task { await viewModel.loadSearchOverlayData(deps: deps) }
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20))
                        .foregroundStyle(FashColors.brandPrimary)
                        .frame(width: 48, height: 48)
                }
            }
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

    private func handleBack() {
        if viewModel.searchBarExpanded {
            viewModel.setSearchBarExpanded(false)
        } else {
            onCloseOverlay()
        }
    }
}
