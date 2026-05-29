import SwiftUI

/// Compact overlay chrome when Explore feed is scrolled — filters/search only (tabs stay in expanded header).
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
                if viewModel.primarySection == .listings {
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
        value = nextValue()
    }
}

/// Bottom edge of the expanded filter + active-search block in feed scroll space.
/// Sticky chrome appears when this scrolls above the visible top (`maxY` → 0).
struct ExploreMarketplaceControlsScrollKey: PreferenceKey {
    static var defaultValue: CGFloat = .infinity
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// Host (overlay) should pin [ExploreStickyChrome] below the app bar — not tabs, filters/search only.
struct ExploreStickyChromeVisibleKey: PreferenceKey {
    static var defaultValue: Bool = false
    static func reduce(value: inout Bool, nextValue: () -> Bool) {
        value = nextValue()
    }
}

/// Always the first `LazyVStack` child so scroll offset keeps updating while scrolling.
struct ExploreFeedScrollOffsetAnchor: View {
    var body: some View {
        Color.clear
            .frame(height: 0)
            .exploreExpandedHeaderScrollReporting()
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

    /// Reports the bottom (`maxY`) of filter + active-search rows for sticky timing.
    func exploreMarketplaceControlsScrollReporting(space: String = "exploreFeedScroll") -> some View {
        background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: ExploreMarketplaceControlsScrollKey.self,
                    value: geo.frame(in: .named(space)).maxY
                )
            }
            .allowsHitTesting(false)
        )
    }
}

/// Fade **tabs only** while scrolling — tabs are not pinned (unlike Android sticky chrome).
enum ExploreTabsCollapse {
    static let fadeDistance: CGFloat = ExploreStickyChromePolicy.showThreshold

    static func fadeOpacity(headerMinY: CGFloat) -> CGFloat {
        guard headerMinY < 0 else { return 1 }
        let progress = min(1, -headerMinY / fadeDistance)
        return 1 - progress
    }
}

/// Scroll thresholds aligned with Android `showStickyExploreChrome` (~88dp).
enum ExploreStickyChromePolicy {
    static let showThreshold: CGFloat = 88
    static let hideThreshold: CGFloat = 72
    /// Controls block has scrolled past the top inset — show compact filter/search.
    static let controlsPinnedThreshold: CGFloat = 8
    /// Controls are back near the top — hide compact chrome.
    static let controlsRestoredThreshold: CGFloat = 80

    static func shouldShowSticky(
        currentlyShown: Bool,
        headerMinY: CGFloat,
        controlsMaxY: CGFloat
    ) -> Bool {
        if controlsMaxY.isFinite, controlsMaxY < 10_000 {
            if currentlyShown {
                return controlsMaxY < controlsRestoredThreshold
            }
            return controlsMaxY < controlsPinnedThreshold
        }
        if currentlyShown {
            return headerMinY < -hideThreshold
        }
        return headerMinY < -showThreshold
    }

    static func shouldCompactTopBar(
        currentlyShown: Bool,
        headerMinY: CGFloat,
        controlsMaxY: CGFloat
    ) -> Bool {
        shouldShowSticky(
            currentlyShown: currentlyShown,
            headerMinY: headerMinY,
            controlsMaxY: controlsMaxY
        )
    }

    static func shouldPinMarketplaceChrome(
        currentlyShown: Bool,
        headerMinY: CGFloat,
        controlsMaxY: CGFloat,
        primarySection: ExplorePrimarySection,
        hasSellerSearch: Bool
    ) -> Bool {
        let scrolled = shouldShowSticky(
            currentlyShown: currentlyShown,
            headerMinY: headerMinY,
            controlsMaxY: controlsMaxY
        )
        guard scrolled else { return false }
        switch primarySection {
        case .listings: return true
        case .sellers: return hasSellerSearch
        }
    }
}
