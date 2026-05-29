import SwiftUI

/// Compact pinned chrome when Explore feed is scrolled — Android `ExploreStickyExploreChrome`.
struct ExploreStickyChrome: View {
    @Environment(\.fashSpacing) private var spacing
    @Bindable var viewModel: ExploreViewModel
    let isGuestMode: Bool
    let deps: AppDependencies

    var body: some View {
        VStack(spacing: 0) {
            Divider()
                .overlay(FashColors.outlineMuted.opacity(0.38))
            VStack(spacing: 0) {
                ExplorePrimarySectionSwitcher(selected: viewModel.primarySection) { section in
                    Task { await viewModel.setPrimarySection(section, deps: deps, isGuestMode: isGuestMode) }
                }
                .padding(.horizontal, spacing.editorialStart)
                .padding(.top, 8)
                .padding(.bottom, viewModel.primarySection == .listings ? 4 : 8)

                if viewModel.primarySection == .listings {
                    Divider()
                        .overlay(FashColors.outlineMuted.opacity(0.45))
                    ExploreStickyFilterRow(
                        hasActiveFilters: viewModel.hasActiveFilters,
                        filterSummaryParts: viewModel.filterSummaryParts,
                        onOpenFilters: { viewModel.showFilterSheet = true },
                        onClearFilters: viewModel.hasActiveFilters ? {
                            Task { await viewModel.clearAllFilters(deps: deps, isGuestMode: isGuestMode) }
                        } : nil
                    )
                }

                if let query = activeSearchQuery, let onClear = onClearActiveSearch {
                    Divider()
                        .overlay(FashColors.outlineMuted.opacity(0.45))
                    ExploreStickyActiveSearchRow(query: query, onClear: onClear)
                }
            }
            .background(FashColors.surfaceContainerLow)
        }
        .background(FashColors.screen)
        .shadow(color: .black.opacity(0.06), radius: 3, y: 2)
    }

    private var activeSearchQuery: String? {
        switch viewModel.primarySection {
        case .listings:
            guard viewModel.isSearchModeActive else { return nil }
            let q = viewModel.committedListingSearchQuery.trimmingCharacters(in: .whitespaces)
            return q.isEmpty ? nil : q
        case .sellers:
            let q = viewModel.committedSellerSearchQuery.trimmingCharacters(in: .whitespaces)
            return q.isEmpty ? nil : q
        }
    }

    private var onClearActiveSearch: (() -> Void)? {
        switch viewModel.primarySection {
        case .listings:
            guard viewModel.isSearchModeActive,
                  !viewModel.committedListingSearchQuery.trimmingCharacters(in: .whitespaces).isEmpty
            else { return nil }
            return {
                Task { await viewModel.clearListingSearch(deps: deps, isGuestMode: isGuestMode) }
            }
        case .sellers:
            guard !viewModel.committedSellerSearchQuery.trimmingCharacters(in: .whitespaces).isEmpty else {
                return nil
            }
            return {
                Task { await viewModel.clearSellerSearch(deps: deps, isGuestMode: isGuestMode) }
            }
        }
    }
}

/// Compact active-search row under sticky tabs — Android `ExploreStickyActiveSearchRow`.
private struct ExploreStickyActiveSearchRow: View {
    @Environment(\.fashSpacing) private var spacing
    let query: String
    let onClear: () -> Void

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 16))
                .foregroundStyle(FashColors.brandPrimary)
            Text(query)
                .font(FashTypography.bodySmall.weight(.medium))
                .foregroundStyle(FashColors.textPrimary)
                .lineLimit(1)
            Spacer(minLength: 0)
            Button(L10n.exploreSearchClearActive, action: onClear)
                .font(FashTypography.labelLarge)
                .foregroundStyle(FashColors.brandPrimary)
        }
        .padding(.horizontal, spacing.editorialStart)
        .padding(.vertical, 8)
    }
}

/// Expanded header `minY` in the feed scroll space (negative when scrolled down).
struct ExploreHeaderScrollKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = min(value, nextValue())
    }
}

extension View {
    func exploreExpandedHeaderScrollReporting(space: String = "exploreFeedScroll") -> some View {
        background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: ExploreHeaderScrollKey.self,
                    value: geo.frame(in: .named(space)).minY
                )
            }
            .allowsHitTesting(false)
        )
    }
}

/// Scroll thresholds aligned with Android `showStickyExploreChrome` (~88dp).
enum ExploreStickyChromePolicy {
    static let showThreshold: CGFloat = 88
    static let hideThreshold: CGFloat = 72

    static func shouldShowSticky(currentlyShown: Bool, headerMinY: CGFloat) -> Bool {
        if currentlyShown {
            return headerMinY < -hideThreshold
        }
        return headerMinY < -showThreshold
    }

    static func shouldCompactTopBar(currentlyCompact: Bool, headerMinY: CGFloat) -> Bool {
        shouldShowSticky(currentlyShown: currentlyCompact, headerMinY: headerMinY)
    }
}
