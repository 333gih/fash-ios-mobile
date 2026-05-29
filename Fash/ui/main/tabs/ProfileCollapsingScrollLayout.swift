import SwiftUI
import UIKit

enum ProfileListingTabSet {
    case ownProfile
    case sellerStorefront

    var tabCount: Int {
        switch self {
        case .ownProfile: return ProfileListingTab.allCases.count
        case .sellerStorefront: return 2
        }
    }

    func title(for index: Int) -> String {
        switch self {
        case .ownProfile:
            return ProfileListingTab(rawValue: index)?.title ?? ""
        case .sellerStorefront:
            return index == 0 ? L10n.profileTabSelling : L10n.profileTabSold
        }
    }

    func emptyTitle(for index: Int) -> String {
        switch self {
        case .ownProfile:
            return ProfileListingTab(rawValue: index)?.emptyTitle ?? L10n.feedEmptyTitle
        case .sellerStorefront:
            return index == 0 ? L10n.profileEmptySellingTitle : L10n.profileEmptySoldTitle
        }
    }

    func emptySubtitle(for index: Int) -> String {
        switch self {
        case .ownProfile:
            return ProfileListingTab(rawValue: index)?.emptySubtitle ?? L10n.feedEmptySubtitle
        case .sellerStorefront:
            return index == 0 ? L10n.profileEmptySellingSubtitle : L10n.profileEmptySoldSubtitle
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
            return index == 0 ? L10n.profileEmptyPinnedFooterSelling : L10n.profileEmptyPinnedFooterSold
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
    let items: [ListingFeedItem]
    var showQuickActions: Bool = false
    var showStatusOverlay: Bool = false
    var additionalBottomInset: CGFloat = 0
    /// Hero scrolled off + tabs pinned — Android `rememberProfilePromoFooterVisible` (index > 0).
    var onTabsPinnedAtTopChange: ((Bool) -> Void)? = nil
    var onListingClick: (ListingFeedItem) -> Void
    var onLike: ((ListingFeedItem) -> Void)?
    var onSave: ((ListingFeedItem) -> Void)?
    @ViewBuilder var expandedHeader: () -> ExpandedHeader
    @ViewBuilder var compactHeader: () -> CompactHeader

    @State private var headerMinY: CGFloat = 0
    @State private var headerMaxY: CGFloat = 10_000
    @State private var showBriefBar = false

    private var collapseProgress: CGFloat {
        min(max(-headerMinY / ProfileCollapseMetrics.scrollDistance, 0), 1)
    }

    /// Expanded hero fully above the viewport — sticky tab row is pinned (Android `firstVisibleItemIndex > 0`).
    private var tabsPinnedAtTop: Bool {
        headerMaxY <= 0
    }

    private var showSectionTitle: Bool {
        tabsPinnedAtTop || collapseProgress > 0.55
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
                                ListingMasonryGridView(items: items) { item, _ in
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
                        .animation(.easeInOut(duration: 0.2), value: selectedTab)

                        Color.clear.frame(height: max(120, additionalBottomInset + 80))
                    } header: {
                        stickyChrome(scrollProxy: scrollProxy)
                    }
                }
                .fashScrollViewTabSwipe(
                    currentIndex: selectedTab,
                    tabCount: tabSet.tabCount
                ) { index in
                    selectedTab = index
                }
            }
            .coordinateSpace(name: "profileScroll")
            .onPreferenceChange(ProfileScrollOffsetKey.self) { offset in
                headerMinY = offset
                refreshBriefBarVisibility()
            }
            .onPreferenceChange(ProfileHeaderBoundsKey.self) { frame in
                guard frame.height > 10 else { return }
                headerMaxY = frame.maxY
                onTabsPinnedAtTopChange?(tabsPinnedAtTop)
                refreshBriefBarVisibility()
            }
        }
    }

    private func refreshBriefBarVisibility() {
        // Android ProfileStickyProfileChrome hysteresis — avoid elastic-scroll flicker.
        if tabsPinnedAtTop || collapseProgress > 0.52 {
            if !showBriefBar { showBriefBar = true }
        } else if collapseProgress < 0.36, !tabsPinnedAtTop {
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
            color: .black.opacity(showBriefBar || tabsPinnedAtTop ? 0.08 : 0.04),
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
            if showSectionTitle, let footer = tabSet.pinnedFooter(for: selectedTab) {
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
}

/// Scrollable tab row with primary underline — Android [ProfileTabSwitcher].
struct ProfileTabSwitcher: View {
    @Environment(\.fashSpacing) private var spacing
    let tabSet: ProfileListingTabSet
    @Binding var selectedTab: Int

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 0) {
                    ForEach(0..<tabSet.tabCount, id: \.self) { index in
                        let selected = selectedTab == index
                        Button {
                            selectedTab = index
                        } label: {
                            VStack(spacing: 6) {
                                Text(tabSet.title(for: index))
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
                        .id(index)
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
        }
    }

    private var tabMinWidth: CGFloat {
        let screen = UIScreen.main.bounds.width
        let edge = spacing.editorialStart * 2
        let slots = min(3, CGFloat(tabSet.tabCount))
        return max((screen - edge) / slots, 96)
    }
}
