import SwiftUI

struct ExploreTopBar: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps
    @Bindable var viewModel: ExploreViewModel
    var isGuestMode: Bool
    var onCloseOverlay: () -> Void

    var body: some View {
        HStack(spacing: spacing.spacing3) {
            Button(action: handleBack) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(FashColors.textPrimary)
                    .frame(width: 48, height: 48)
            }
            if viewModel.searchBarExpanded {
                TextField(L10n.searchPlaceholder, text: $viewModel.query)
                    .font(FashTypography.bodyMedium)
                    .textFieldStyle(.plain)
                    .onSubmit {
                        Task { await viewModel.submitSearch(deps: deps, isGuestMode: isGuestMode) }
                    }
            } else {
                FashScreenTitle(suffix: L10n.brandHeaderSuffixExplore)
            }
            Spacer(minLength: 0)
            if !viewModel.searchBarExpanded {
                Button {
                    viewModel.searchBarExpanded = true
                } label: {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 20))
                        .foregroundStyle(FashColors.textPrimary)
                        .frame(width: 48, height: 48)
                }
            }
        }
        .padding(.leading, spacing.editorialStart)
        .padding(.trailing, spacing.editorialEnd)
        .background(FashColors.surfaceContainerHighest)
    }

    private func handleBack() {
        if viewModel.searchBarExpanded {
            viewModel.searchBarExpanded = false
        } else {
            onCloseOverlay()
        }
    }
}
