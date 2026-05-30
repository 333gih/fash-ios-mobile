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
    let items: [ListingFeedItem]
    var showQuickActions: Bool = false
    var showStatusOverlay: Bool = false
    var additionalBottomInset: CGFloat = 0
    /// Increment to scroll the listing grid under pinned tabs (Home journey shortcuts).
    var scrollToGridToken: Int = 0
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
    @State private var profileScrollPosition: String?
    @State private var profileScrollResetToken = 0
    @State private var scrollClampRevision = 0
    @State private var pendingPinnedGridScroll = false
    @State private var pinnedScrollTaskGeneration = 0
    @State private var masonryColumnAssignmentsByTab: [Int: [String: Bool]] = [:]

    /// Stable per tab — do not branch on empty/rows or SwiftUI recreates the grid and jumps scroll.
    private var listingGridScrollId: String {
        ProfileScrollIds.listingGrid(tab: selectedTab)
    }

    private var masonryColumnAssignments: Binding<[String: Bool]> {
        Binding(
            get: { masonryColumnAssignmentsByTab[selectedTab] ?? [:] },
            set: { masonryColumnAssignmentsByTab[selectedTab] = $0 }
        )
    }

    var body: some View {
        ScrollViewReader { scrollProxy in
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    Section {
                        expandedHeader()
                            .id(ProfileScrollIds.expandedHeader)
                            .background(
                                GeometryReader { geo in
                                    let frame = geo.frame(in: .named("profileScroll"))
                                    Color.clear
                                        .preference(key: ProfileScrollOffsetKey.self, value: frame.minY)
                                        .preference(key: ProfileHeaderBoundsKey.self, value: frame)
                                }
                                .allowsHitTesting(false)
                            )
                    }
                    Section {
                        Group {
                            if items.isEmpty {
                                emptyBlock
                            } else {
                                ListingStaggeredMasonryView(
                                    items: items,
                                    columnAssignments: masonryColumnAssignments
                                ) { item, _ in
                                    ListingGridCard(
                                        item: item,
                                        onTap: { onListingClick(item) },
                                        imageAspectRatio: ListingMasonryGrid.staggerAspectRatio(for: item.id),
                                        showQuickActions: showQuickActions,
                                        statusOverlayLabel: showStatusOverlay
                                            ? ListingStatusUi.overlayLabel(for: item.listingStatus)
                                            : nil,
                                        onLike: onLike.map { h in { h(item) } },
                                        onSave: onSave.map { h in { h(item) } }
                                    )
                                }
                                .padding(.top, 4)
                            }
                        }
                        .id(listingGridScrollId)

                        Color.clear.frame(height: max(120, additionalBottomInset + 80))
                    } header: {
                        stickyChrome(scrollProxy: scrollProxy)
                    }
                }
                .fashScrollViewTabSwipe(
                    currentIndex: visualTabIndex,
                    tabCount: resolvedTabIndices.count
                ) { visualIndex in
                    guard visualIndex >= 0, visualIndex < resolvedTabIndices.count else { return }
                    let nextTab = resolvedTabIndices[visualIndex]
                    guard nextTab != selectedTab else { return }
                    selectedTab = nextTab
                }
                .scrollTargetLayout()
            }
            .scrollPosition(id: $profileScrollPosition, anchor: .top)
            .background {
                PinnedTabScrollOffsetFixer(
                    resetToken: profileScrollResetToken,
                    clampRevision: scrollClampRevision,
                    headerHeight: headerHeight
                )
            }
            .coordinateSpace(name: "profileScroll")
            .onAppear {
                reportedTabsPinned = false
                headerHeight = 0
                showBriefBar = false
                showSectionTitle = false
                lastScrollOffset = 0
            }
            .onPreferenceChange(ProfileScrollOffsetKey.self) { offset in
                applyScrollOffset(offset)
            }
            .onPreferenceChange(ProfileHeaderBoundsKey.self) { frame in
                guard frame.height > 10 else { return }
                let nextHeight = frame.height
                guard abs(nextHeight - headerHeight) > 0.5 else { return }
                headerHeight = nextHeight
                applyScrollOffset(frame.minY)
            }
            .onChange(of: resolvedTabIndices) { _, indices in
                guard !indices.contains(selectedTab) else { return }
                selectedTab = indices.first ?? 0
            }
            .onChange(of: selectedTab) { oldTab, newTab in
                guard oldTab != newTab else { return }
                pinnedScrollTaskGeneration += 1
                profileScrollPosition = nil
                pendingPinnedGridScroll = true
                applyPinnedGridScroll(using: scrollProxy)
            }
            .onChange(of: items.count) { _, _ in
                scrollClampRevision += 1
                guard pendingPinnedGridScroll else { return }
                applyPinnedGridScroll(using: scrollProxy)
                pendingPinnedGridScroll = false
            }
            .onChange(of: scrollToGridToken) { _, token in
                guard token > 0 else { return }
                applyPinnedGridScroll(using: scrollProxy)
            }
        }
    }

    private func applyPinnedGridScroll(using scrollProxy: ScrollViewProxy) {
        synchronizePinnedChromeForTabSwitch()
        let generation = pinnedScrollTaskGeneration
        PinnedTabScrollReset.scrollToPinnedContent(
            scrollPosition: $profileScrollPosition,
            proxy: scrollProxy,
            resetToken: $profileScrollResetToken,
            contentId: listingGridScrollId,
            followUpDelaysMs: [120]
        )
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(280))
            guard generation == pinnedScrollTaskGeneration, pendingPinnedGridScroll else { return }
            pendingPinnedGridScroll = false
            PinnedTabScrollReset.scrollToPinnedContent(
                scrollPosition: $profileScrollPosition,
                proxy: scrollProxy,
                resetToken: $profileScrollResetToken,
                contentId: listingGridScrollId,
                followUpDelaysMs: []
            )
        }
    }

    /// Keep compact chrome + section title visible while grid relayouts after tab swap.
    private func synchronizePinnedChromeForTabSwitch() {
        guard headerHeight > 24 else { return }
        showBriefBar = true
        showSectionTitle = true
        lastScrollOffset = -(headerHeight - 12)
        emitTabsPinnedIfNeeded(pinned: true)
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
        if headerHeight > 24 {
            return offset <= -(headerHeight - 12)
        }
        return offset <= -ProfileCollapseMetrics.scrollDistance * 0.92
    }

    private func emitTabsPinnedIfNeeded(pinned: Bool) {
        guard pinned != reportedTabsPinned else { return }
        reportedTabsPinned = pinned
        onTabsPinnedAtTopChange?(pinned)
    }

    private func refreshBriefBarVisibility(collapseProgress: CGFloat, tabsPinned: Bool) {
        // Android ProfileStickyProfileChrome hysteresis — avoid elastic-scroll flicker.
        if tabsPinned || collapseProgress > 0.52 {
            if !showBriefBar { showBriefBar = true }
        } else if collapseProgress < 0.36, !tabsPinned {
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
                        withAnimation(.easeInOut(duration: 0.28)) {
                            scrollProxy.scrollTo(ProfileScrollIds.expandedHeader, anchor: .top)
                        }
                    }
                Divider().opacity(0.45)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
            ProfileTabSwitcher(
                tabSet: tabSet,
                orderedTabIndices: resolvedTabIndices,
                selectedTab: $selectedTab
            )
            if showSectionTitle {
                Divider().opacity(0.58)
                Text(tabSet.title(for: selectedTab))
                    .font(FashTypography.titleSmall.weight(.semibold))
                    .foregroundStyle(FashColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, spacing.editorialStart)
                    .padding(.vertical, 8)
                    .transition(.opacity)
            }
        }
        .background(FashColors.screen)
        .shadow(
            color: .black.opacity(showBriefBar || reportedTabsPinned ? 0.08 : 0.04),
            radius: 3,
            y: 1
        )
        .animation(.easeInOut(duration: 0.24), value: showBriefBar)
        .animation(.easeInOut(duration: 0.2), value: showSectionTitle)
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

    static func listingGrid(tab: Int) -> String {
        "profile_listing_grid_\(tab)"
    }
}

/// Scrollable tab row with primary underline — Android [ProfileTabSwitcher].
struct ProfileTabSwitcher: View {
    @Environment(\.fashSpacing) private var spacing
    let tabSet: ProfileListingTabSet
    let orderedTabIndices: [Int]
    @Binding var selectedTab: Int

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(orderedTabIndices, id: \.self) { logicalIndex in
                        let selected = selectedTab == logicalIndex
                        Button {
                            selectedTab = logicalIndex
                        } label: {
                            VStack(spacing: 6) {
                                Text(tabSet.title(for: logicalIndex))
                                    .font(FashTypography.labelLarge.weight(selected ? .bold : .regular))
                                    .foregroundStyle(selected ? FashColors.textPrimary : FashColors.textSecondary.opacity(0.75))
                                    .lineLimit(1)
                                    .minimumScaleFactor(0.85)
                                Rectangle()
                                    .fill(selected ? FashColors.brandPrimary : Color.clear)
                                    .frame(height: 2)
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
            .onChange(of: selectedTab) { _, tab in
                withAnimation(.easeInOut(duration: 0.2)) {
                    proxy.scrollTo(tab, anchor: .center)
                }
            }
            .onAppear {
                proxy.scrollTo(selectedTab, anchor: .center)
            }
            .onChange(of: orderedTabIndices) { _, _ in
                proxy.scrollTo(selectedTab, anchor: .center)
            }
        }
    }

    private var tabMinWidth: CGFloat {
        let screen = UIScreen.main.bounds.width
        let edge = spacing.editorialStart * 2
        let slots = min(3, CGFloat(max(orderedTabIndices.count, 1)))
        return max((screen - edge) / slots, 96)
    }
}
