import SwiftUI
import UIKit

/// Seller storefront tab slots — not [ProfileListingTab] raw values (sold = 3 would collide).
enum SellerProfileTab: Int {
    case selling = 0
    case sold = 1
}

enum ProfileListingTabSet {
    case ownProfile
    case sellerStorefront

    var tabCount: Int {
        switch self {
        case .ownProfile: return ProfileListingTab.allCases.count
        case .sellerStorefront: return SellerProfileTab.sold.rawValue + 1
        }
    }

    func title(for index: Int) -> String {
        switch self {
        case .ownProfile:
            return ProfileListingTab(rawValue: index)?.title ?? ""
        case .sellerStorefront:
            switch SellerProfileTab(rawValue: index) {
            case .sold: return L10n.profileTabSold
            default: return L10n.profileTabSelling
            }
        }
    }

    func emptyTitle(for index: Int) -> String {
        switch self {
        case .ownProfile:
            return ProfileListingTab(rawValue: index)?.emptyTitle ?? L10n.feedEmptyTitle
        case .sellerStorefront:
            switch SellerProfileTab(rawValue: index) {
            case .sold: return L10n.profileEmptySoldTitle
            default: return L10n.profileEmptySellingTitle
            }
        }
    }

    func emptySubtitle(for index: Int) -> String {
        switch self {
        case .ownProfile:
            return ProfileListingTab(rawValue: index)?.emptySubtitle ?? L10n.feedEmptySubtitle
        case .sellerStorefront:
            switch SellerProfileTab(rawValue: index) {
            case .sold: return L10n.profileEmptySoldSubtitle
            default: return L10n.profileEmptySellingSubtitle
            }
        }
    }

    func pinnedFooter(for index: Int) -> String? {
        switch self {
        case .ownProfile:
            switch ProfileListingTab(rawValue: index) {
            case .active: return L10n.profileEmptyPinnedFooterSelling
            case .inReview: return L10n.profileEmptyPinnedFooterInReview
            case .rejected: return L10n.profileEmptyPinnedFooterRejected
            case .sold: return L10n.profileEmptyPinnedFooterSold
            case .wishlist: return L10n.profileEmptyPinnedFooterWishlist
            default: return nil
            }
        case .sellerStorefront:
            switch SellerProfileTab(rawValue: index) {
            case .sold: return L10n.profileEmptyPinnedFooterSold
            default: return L10n.profileEmptyPinnedFooterSelling
            }
        }
    }
}

private enum ProfileCollapseMetrics {
    static let scrollDistance: CGFloat = 280
}

private struct ProfileScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
}

private struct ProfileHeaderBoundsKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) { value = nextValue() }
}

/// Collapsing profile scroll — Android [ProfileCollapsingScrollLayout].
struct ProfileCollapsingScrollLayout<ExpandedHeader: View, CompactHeader: View>: View {
    @Environment(\.fashSpacing) private var spacing
    @Binding var selectedTab: Int
    let tabSet: ProfileListingTabSet
    /// Visual order of logical tab indices — Android `orderedTabIndices`.
    var orderedTabIndices: [Int] = ProfileListingTab.allCases.map(\.rawValue)
    /// Optional tab badge from summary counts — `(logicalTabIndex) -> count`.
    var tabBadgeCounts: ((Int) -> Int?)? = nil
    let items: [ListingFeedItem]
    var showQuickActions: Bool = false
    var showStatusOverlay: Bool = false
    /// When true, hide "active"/"inactive" chips (seller storefront); own profile passes false.
    var suppressActiveStatusOnGrid: Bool = true
    var additionalBottomInset: CGFloat = 0
    /// Skeleton grid (Explore-style) while the first page loads.
    var showGridLoading: Bool = false
    var hasMoreListings: Bool = false
    var isLoadingMoreListings: Bool = false
    var isReloadingListings: Bool = false
    var onLoadMore: (() -> Void)? = nil
    /// When false, empty listings are hidden (still loading).
    var showEmptyState: Bool = true
    /// Skip scroll clamp bumps while pull-to-refresh is in flight — avoids snapping back to top.
    var isRefreshing: Bool = false
    /// Block scroll + clamp while profile shell is still loading — prevents jump-to-top during load.
    var lockScroll: Bool = false
    /// Increment to scroll the listing grid under pinned tabs (Home journey shortcuts).
    var scrollToGridToken: Int = 0
    var scrollToListingId: String? = nil
    var scrollToListingToken: Int = 0
    /// Hero scrolled off + tabs pinned — Android `rememberProfilePromoFooterVisible` (index > 0).
    var onTabsPinnedAtTopChange: ((Bool) -> Void)? = nil
    var onListingClick: (ListingFeedItem) -> Void
    var onLike: ((ListingFeedItem) -> Void)?
    var onSave: ((ListingFeedItem) -> Void)?
    @ViewBuilder var expandedHeader: () -> ExpandedHeader
    @ViewBuilder var compactHeader: () -> CompactHeader

    @State private var headerHeight: CGFloat = 0
    @State private var reportedTabsPinned = false
    @State private var showBriefBar = false
    @State private var showSectionTitle = false
    @State private var lastScrollOffset: CGFloat = 0
    @State private var profileScrollResetToken = 0
    @State private var scrollClampRevision = 0
    @State private var masonryColumnAssignmentsByTab: [Int: [String: Bool]] = [:]
    @State private var listingInteractionEnabled = true
    @State private var tabSlideDirection: Int = 0
    /// Sticky chrome stayed pinned through rubber-band — avoids tab row flicker / “missing” tabs.
    @State private var chromePinnedLatch = false
    @State private var scrollViewportHeight: CGFloat = 0
    @State private var feedContentBottomY: CGFloat = .infinity
    @State private var lastProximityLoadMoreAt: Date = .distantPast

    /// One id for all tabs — Android keeps one [LazyListState]; do not vary per tab (preserves scroll on swipe).
    private let listingGridScrollId = ProfileScrollIds.listingGrid

    private var masonryColumnAssignments: Binding<[String: Bool]> {
        Binding(
            get: { masonryColumnAssignmentsByTab[selectedTab] ?? [:] },
            set: { masonryColumnAssignmentsByTab[selectedTab] = $0 }
        )
    }

    var body: some View {
        ScrollViewReader { scrollProxy in
            profileScrollRoot(scrollProxy: scrollProxy)
        }
    }

    @ViewBuilder
    private func profileScrollRoot(scrollProxy: ScrollViewProxy) -> some View {
        ScrollView {
            profileLazyStack(scrollProxy: scrollProxy)
        }
        .scrollDisabled(lockScroll)
        .background(profileViewportHeightReader)
        .background {
            PinnedTabScrollOffsetFixer(
                resetToken: profileScrollResetToken,
                clampRevision: scrollClampRevision,
                headerHeight: headerHeight
            )
        }
        .coordinateSpace(name: ProfileScrollIds.coordinateSpaceName)
        .onAppear(perform: resetProfileScrollChromeState)
        .onPreferenceChange(ProfileScrollOffsetKey.self, perform: handleProfileScrollOffset)
        .onPreferenceChange(FeedContentBottomYKey.self, perform: handleFeedContentBottomY)
        .onPreferenceChange(ProfileHeaderBoundsKey.self, perform: handleProfileHeaderBounds)
        .onChange(of: resolvedTabIndices) { _, indices in
            guard !indices.contains(selectedTab) else { return }
            selectedTab = indices.first ?? 0
        }
        .onChange(of: selectedTab) { oldTab, newTab in
            handleSelectedTabChange(from: oldTab, to: newTab)
        }
        .onChange(of: items.count) { oldCount, newCount in
            guard !isRefreshing, !showGridLoading, showEmptyState else { return }
            guard newCount < oldCount else { return }
            scrollClampRevision += 1
        }
        .onChange(of: scrollToGridToken) { _, token in
            guard token > 0, !lockScroll, !showGridLoading else { return }
            applyPinnedGridScroll(using: scrollProxy)
        }
        .onChange(of: scrollToListingToken) { _, token in
            guard token > 0, !lockScroll, !showGridLoading else { return }
            scrollToFocusedListing(using: scrollProxy)
        }
    }

    private func scrollToFocusedListing(using scrollProxy: ScrollViewProxy) {
        guard let listingId = scrollToListingId?.trimmingCharacters(in: .whitespacesAndNewlines),
              !listingId.isEmpty else { return }
        Task { @MainActor in
            for delayMs in [0, 80, 200, 400] {
                try? await Task.sleep(for: .milliseconds(delayMs))
                var transaction = Transaction()
                transaction.disablesAnimations = delayMs == 0
                withTransaction(transaction) {
                    scrollProxy.scrollTo(listingId, anchor: .center)
                }
            }
        }
    }

    private var profileViewportHeightReader: some View {
        GeometryReader { geo in
            Color.clear
                .onAppear { scrollViewportHeight = geo.size.height }
                .onChange(of: geo.size.height) { _, h in
                    if h > 0 { scrollViewportHeight = h }
                }
        }
    }

    private var profileTabSwipeEnabled: Bool {
        resolvedTabIndices.count > 1
    }

    @ViewBuilder
    private func profileLazyStack(scrollProxy: ScrollViewProxy) -> some View {
        LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
            Section {
                expandedHeader()
                    .id(ProfileScrollIds.expandedHeader)
                    .background(profileHeaderOffsetReader)
            }
            Section {
                profileListingGridSection
                    .profileTabSwipe(
                        enabled: profileTabSwipeEnabled,
                        currentIndex: visualTabIndex,
                        tabCount: resolvedTabIndices.count,
                        listingInteractionEnabled: $listingInteractionEnabled
                    ) { visualIndex in
                        commitProfileTabSwipe(toVisualIndex: visualIndex)
                    }
                Color.clear.frame(height: max(120, additionalBottomInset + 80))
            } header: {
                stickyChrome(scrollProxy: scrollProxy)
                    .profileTabSwipe(
                        enabled: profileTabSwipeEnabled,
                        currentIndex: visualTabIndex,
                        tabCount: resolvedTabIndices.count,
                        listingInteractionEnabled: $listingInteractionEnabled
                    ) { visualIndex in
                        commitProfileTabSwipe(toVisualIndex: visualIndex)
                    }
            }
        }
        .scrollTargetLayout()
    }

    private func commitProfileTabSwipe(toVisualIndex visualIndex: Int) {
        guard visualIndex >= 0, visualIndex < resolvedTabIndices.count else { return }
        let nextTab = resolvedTabIndices[visualIndex]
        guard nextTab != selectedTab else { return }
        tabSlideDirection = visualIndex > visualTabIndex ? 1 : -1
        withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
            selectedTab = nextTab
        }
    }

    private var profileHeaderOffsetReader: some View {
        GeometryReader { geo in
            let frame = geo.frame(in: .named(ProfileScrollIds.coordinateSpaceName))
            Color.clear
                .preference(key: ProfileScrollOffsetKey.self, value: frame.minY)
                .preference(key: ProfileHeaderBoundsKey.self, value: frame)
        }
        .allowsHitTesting(false)
    }

    private var profileListingGridSection: some View {
        Group {
            profileListingGridBody
        }
        .id(listingGridScrollId)
        .allowsHitTesting(listingInteractionEnabled)
        .transition(
            .asymmetric(
                insertion: .opacity.combined(with: .offset(x: CGFloat(tabSlideDirection) * 28)),
                removal: .opacity.combined(with: .offset(x: CGFloat(-tabSlideDirection) * 28))
            )
        )
    }

    private func resetProfileScrollChromeState() {
        reportedTabsPinned = false
        chromePinnedLatch = false
        showBriefBar = false
        showSectionTitle = false
        lastScrollOffset = 0
    }

    private func handleProfileScrollOffset(_ offset: CGFloat) {
        applyScrollOffset(offset)
        evaluateScrollProximityLoadMore(headerMinY: offset)
    }

    private func handleFeedContentBottomY(_ bottomY: CGFloat) {
        feedContentBottomY = bottomY
        evaluateScrollProximityLoadMore(headerMinY: lastScrollOffset)
    }

    private func handleProfileHeaderBounds(_ frame: CGRect) {
        guard frame.height > 10 else { return }
        let nextHeight = frame.height
        guard abs(nextHeight - headerHeight) > 0.5 else { return }
        headerHeight = nextHeight
        applyScrollOffset(frame.minY)
    }

    private func handleSelectedTabChange(from oldTab: Int, to newTab: Int) {
        guard oldTab != newTab else { return }
        feedContentBottomY = .infinity
        lastProximityLoadMoreAt = .distantPast
        guard !isRefreshing, !lockScroll else { return }
        let oldVisual = resolvedTabIndices.firstIndex(of: oldTab) ?? 0
        let newVisual = resolvedTabIndices.firstIndex(of: newTab) ?? 0
        tabSlideDirection = newVisual > oldVisual ? 1 : -1
        scheduleClampAfterTabContentLayout()
    }

    private func applyPinnedGridScroll(using scrollProxy: ScrollViewProxy) {
        if headerHeight > 24 {
            showBriefBar = true
            showSectionTitle = true
            chromePinnedLatch = true
            emitTabsPinnedIfNeeded(pinned: true)
        }
        PinnedTabScrollReset.scrollToPinnedContent(
            proxy: scrollProxy,
            resetToken: $profileScrollResetToken,
            contentId: listingGridScrollId,
            followUpDelaysMs: [120]
        )
    }

    /// After tab body height changes, clamp only if offset is past content end — never scroll up to pinned target.
    private func scheduleClampAfterTabContentLayout() {
        let tab = selectedTab
        Task { @MainActor in
            for delayMs in [0, 80, 180, 320] {
                try? await Task.sleep(for: .milliseconds(delayMs))
                guard selectedTab == tab else { return }
                scrollClampRevision += 1
            }
        }
    }

    /// Visual tab order — seller is always selling then sold (Android `tabIndices` for storefront).
    private var resolvedTabIndices: [Int] {
        switch tabSet {
        case .sellerStorefront:
            return [SellerProfileTab.selling.rawValue, SellerProfileTab.sold.rawValue]
        case .ownProfile:
            let base = ProfileListingTab.allCases.map(\.rawValue)
            let filtered = orderedTabIndices.filter { base.contains($0) }
            return filtered.isEmpty ? base : filtered
        }
    }

    private var visualTabIndex: Int {
        resolvedTabIndices.firstIndex(of: selectedTab) ?? 0
    }

    private func evaluateScrollProximityLoadMore(headerMinY: CGFloat) {
        guard let onLoadMore else { return }
        let now = Date()
        guard now.timeIntervalSince(lastProximityLoadMoreAt) >= 0.45 else { return }
        guard FeedScrollPaginationPolicy.shouldLoadMore(
            headerMinY: headerMinY,
            contentBottomY: feedContentBottomY,
            viewportHeight: scrollViewportHeight,
            hasItems: !items.isEmpty,
            hasMore: hasMoreListings,
            isLoadingMore: isLoadingMoreListings,
            isLoadingFirstPage: showGridLoading
        ) else { return }
        lastProximityLoadMoreAt = now
        onLoadMore()
    }

    private func applyScrollOffset(_ offset: CGFloat) {
        let pinned = tabsPinnedAtTop(for: offset)
        let collapseProgress = min(max(-offset / ProfileCollapseMetrics.scrollDistance, 0), 1)
        let wantsSectionTitle = pinned || collapseProgress > 0.55
        let wantsBriefBar: Bool
        if showBriefBar {
            wantsBriefBar = !(collapseProgress < 0.36 && !pinned)
        } else {
            wantsBriefBar = pinned || collapseProgress > 0.52
        }

        if pinned == reportedTabsPinned,
           wantsSectionTitle == showSectionTitle,
           wantsBriefBar == showBriefBar,
           abs(offset - lastScrollOffset) < 2 {
            return
        }
        lastScrollOffset = offset

        emitTabsPinnedIfNeeded(pinned: pinned)
        refreshBriefBarVisibility(collapseProgress: collapseProgress, tabsPinned: pinned)

        if wantsSectionTitle != showSectionTitle {
            showSectionTitle = wantsSectionTitle
        }
    }

    /// Sticky tab row pinned — Android `rememberProfilePromoFooterVisible` (`firstVisibleItemIndex > 0`).
    private func tabsPinnedAtTop(for offset: CGFloat) -> Bool {
        let pinThreshold: CGFloat
        let unpinThreshold: CGFloat
        if headerHeight > 24 {
            pinThreshold = -(headerHeight - 12)
            unpinThreshold = -(headerHeight - 48)
        } else {
            pinThreshold = -ProfileCollapseMetrics.scrollDistance * 0.92
            unpinThreshold = -ProfileCollapseMetrics.scrollDistance * 0.75
        }
        if offset <= pinThreshold {
            chromePinnedLatch = true
            return true
        }
        if chromePinnedLatch {
            if offset > unpinThreshold {
                chromePinnedLatch = false
            }
            return chromePinnedLatch
        }
        return false
    }

    private func emitTabsPinnedIfNeeded(pinned: Bool) {
        guard pinned != reportedTabsPinned else { return }
        reportedTabsPinned = pinned
        onTabsPinnedAtTopChange?(pinned)
    }

    private func refreshBriefBarVisibility(collapseProgress: CGFloat, tabsPinned: Bool) {
        // Android ProfileStickyProfileChrome hysteresis — avoid elastic-scroll flicker.
        if tabsPinned || chromePinnedLatch || collapseProgress > 0.52 {
            if !showBriefBar { showBriefBar = true }
        } else if collapseProgress < 0.36, !tabsPinned, !chromePinnedLatch {
            if showBriefBar { showBriefBar = false }
        }
    }

    @ViewBuilder
    private func stickyChrome(scrollProxy: ScrollViewProxy) -> some View {
        VStack(spacing: 0) {
            if showBriefBar {
                compactHeader()
                    .contentShape(Rectangle())
                    .onTapGesture {
                        scrollProxy.scrollTo(ProfileScrollIds.expandedHeader, anchor: .top)
                    }
                Divider().opacity(0.45)
            }
            ProfileTabSwitcher(
                tabSet: tabSet,
                orderedTabIndices: resolvedTabIndices,
                selectedTab: $selectedTab,
                tabBadgeCounts: tabBadgeCounts
            )
            if showSectionTitle {
                Divider().opacity(0.58)
                Text(tabSet.title(for: selectedTab))
                    .font(FashTypography.titleSmall.weight(.semibold))
                    .foregroundStyle(FashColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, spacing.editorialStart)
                    .padding(.vertical, 8)
            }
        }
        .background(FashColors.screen)
        .shadow(
            color: .black.opacity(showBriefBar || reportedTabsPinned ? 0.08 : 0.04),
            radius: 3,
            y: 1
        )
    }

    @ViewBuilder
    private var profilePaginationFooter: some View {
        if hasMoreListings || isLoadingMoreListings, let onLoadMore {
            FeedLoadMoreFooter(
                enabled: hasMoreListings,
                isLoadingMore: isLoadingMoreListings,
                triggersLoadOnAppear: false,
                onLoadMore: onLoadMore
            )
            FeedScrollContentBottomReporter(coordinateSpace: ProfileScrollIds.coordinateSpaceName)
        }
    }

    @ViewBuilder
    private var profileListingGridBody: some View {
        if showGridLoading {
            profileListingLoadingBlock
        } else if items.isEmpty, showEmptyState {
            emptyBlock
        } else if !items.isEmpty {
            ListingStaggeredMasonryView(
                items: items,
                columnAssignments: masonryColumnAssignments,
                footer: { profilePaginationFooter }
            ) { item, _ in
                ListingGridCard(
                    item: item,
                    onTap: { onListingClick(item) },
                    imageAspectRatio: ListingMasonryGrid.masonryAspectRatio(for: item),
                    showQuickActions: showQuickActions,
                    statusOverlayLabel: showStatusOverlay
                        ? ListingStatusUi.overlayLabel(for: item.listingStatus, suppressActive: suppressActiveStatusOnGrid)
                        : nil,
                    onLike: onLike.map { h in { h(item) } },
                    onSave: onSave.map { h in { h(item) } }
                )
                .id(item.id)
            }
            .padding(.top, 4)
            .overlay(alignment: .top) {
                if isReloadingListings, !isRefreshing {
                    ProgressView()
                        .tint(FashColors.brandPrimary)
                        .scaleEffect(1.05)
                        .frame(maxWidth: .infinity, alignment: .top)
                        .padding(.top, spacing.spacing4)
                        .allowsHitTesting(false)
                }
            }
        }
    }

    private var profileListingLoadingBlock: some View {
        FashSkeleton.listingGrid()
            .padding(.top, 4)
            .padding(.bottom, 24)
    }

    private var emptyBlock: some View {
        VStack(spacing: 12) {
            FashEmptyStateView(
                title: tabSet.emptyTitle(for: selectedTab),
                subtitle: tabSet.emptySubtitle(for: selectedTab)
            )
            .frame(minHeight: 280)
            if reportedTabsPinned, let footer = tabSet.pinnedFooter(for: selectedTab) {
                Divider().padding(.horizontal, spacing.editorialStart).opacity(0.45)
                Text(footer)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, spacing.editorialStart)
            }
        }
        .padding(.vertical, 24)
    }
}

private enum ProfileScrollIds {
    static let expandedHeader = "profile_expanded_header"
    static let listingGrid = "profile_listing_grid"
    static let coordinateSpaceName = "profileScroll"
}

/// Scrollable tab row with primary underline — Android [ProfileTabSwitcher].
struct ProfileTabSwitcher: View {
    @Environment(\.fashSpacing) private var spacing
    @Namespace private var tabIndicator
    let tabSet: ProfileListingTabSet
    let orderedTabIndices: [Int]
    @Binding var selectedTab: Int
    var tabBadgeCounts: ((Int) -> Int?)? = nil

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(orderedTabIndices, id: \.self) { logicalIndex in
                        let selected = selectedTab == logicalIndex
                        Button {
                            withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                                selectedTab = logicalIndex
                            }
                        } label: {
                            VStack(spacing: 6) {
                                Text(tabLabel(for: logicalIndex))
                                    .font(FashTypography.labelLarge.weight(selected ? .bold : .regular))
                                    .foregroundStyle(selected ? FashColors.textPrimary : FashColors.textSecondary.opacity(0.75))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                                ZStack {
                                    Rectangle()
                                        .fill(Color.clear)
                                        .frame(height: 2)
                                    if selected {
                                        Rectangle()
                                            .fill(FashColors.brandPrimary)
                                            .frame(height: 2)
                                            .matchedGeometryEffect(id: "profile_tab_indicator", in: tabIndicator)
                                    }
                                }
                            }
                            .frame(minWidth: tabMinWidth)
                            .padding(.horizontal, 8)
                            .padding(.top, 10)
                        }
                        .buttonStyle(.plain)
                        .id(logicalIndex)
                    }
                }
                .padding(.horizontal, spacing.editorialStart)
            }
            .background(FashColors.screen)
            .animation(.spring(response: 0.34, dampingFraction: 0.86), value: selectedTab)
            .onChange(of: selectedTab) { _, tab in
                guard orderedTabIndices.contains(tab) else { return }
                withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                    proxy.scrollTo(tab, anchor: .center)
                }
            }
            .onAppear {
                guard orderedTabIndices.contains(selectedTab) else { return }
                proxy.scrollTo(selectedTab, anchor: .center)
            }
            .onChange(of: orderedTabIndices) { _, indices in
                guard indices.contains(selectedTab) else { return }
                proxy.scrollTo(selectedTab, anchor: .center)
            }
        }
    }

    private func tabLabel(for logicalIndex: Int) -> String {
        let title = tabSet.title(for: logicalIndex)
        guard let count = tabBadgeCounts?(logicalIndex), count > 0 else { return title }
        return "\(title) (\(count))"
    }

    private var tabMinWidth: CGFloat {
        let screen = UIScreen.main.bounds.width
        let edge = spacing.editorialStart * 2
        let slots = min(3, CGFloat(max(orderedTabIndices.count, 1)))
        return max((screen - edge) / slots, 96)
    }
}
