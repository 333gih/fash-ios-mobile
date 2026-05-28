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

private struct ProfileScrollOffsetKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) { value = nextValue() }
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
    var onListingClick: (ListingFeedItem) -> Void
    var onLike: ((ListingFeedItem) -> Void)?
    var onSave: ((ListingFeedItem) -> Void)?
    @ViewBuilder var expandedHeader: () -> ExpandedHeader
    @ViewBuilder var compactHeader: () -> CompactHeader

    @State private var showCompactHeader = false
    @State private var showSectionTitle = false
    @State private var dragOffset: CGFloat = 0

    private let columns = [
        GridItem(.flexible(), spacing: 8),
        GridItem(.flexible(), spacing: 8),
    ]

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                Section {
                    expandedHeader()
                        .background(
                            GeometryReader { geo in
                                Color.clear.preference(
                                    key: ProfileScrollOffsetKey.self,
                                    value: geo.frame(in: .named("profileScroll")).minY
                                )
                            }
                        )
                }
                Section {
                    if items.isEmpty {
                        emptyBlock
                    } else {
                        LazyVGrid(columns: columns, spacing: 8) {
                            ForEach(items) { item in
                                ListingGridCard(
                                    item: item,
                                    onTap: { onListingClick(item) },
                                    showQuickActions: showQuickActions,
                                    onLike: onLike.map { h in { h(item) } },
                                    onSave: onSave.map { h in { h(item) } }
                                )
                            }
                        }
                        .padding(.horizontal, spacing.editorialStart)
                        .padding(.top, 4)
                    }
                    Color.clear.frame(height: max(120, additionalBottomInset + 80))
                } header: {
                    stickyChrome
                }
            }
        }
        .coordinateSpace(name: "profileScroll")
        .onPreferenceChange(ProfileScrollOffsetKey.self) { offset in
            let progress = min(max(-offset / 280, 0), 1)
            showCompactHeader = progress > 0.52
            showSectionTitle = progress > 0.55
        }
        .simultaneousGesture(horizontalSwipeGesture)
    }

    private var stickyChrome: some View {
        VStack(spacing: 0) {
            if showCompactHeader {
                compactHeader()
                Divider().opacity(0.45)
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
            }
        }
        .background(FashColors.screen)
        .shadow(color: .black.opacity(showCompactHeader ? 0.08 : 0.04), radius: 3, y: 1)
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

    private var horizontalSwipeGesture: some Gesture {
        DragGesture(minimumDistance: 24, coordinateSpace: .local)
            .onChanged { value in
                if abs(value.translation.width) > abs(value.translation.height) {
                    dragOffset = value.translation.width
                }
            }
            .onEnded { value in
                let threshold: CGFloat = 72
                let maxTab = tabSet.tabCount - 1
                if value.translation.width <= -threshold, selectedTab < maxTab {
                    selectedTab += 1
                } else if value.translation.width >= threshold, selectedTab > 0 {
                    selectedTab -= 1
                }
                dragOffset = 0
            }
    }
}

/// Scrollable tab row with primary underline — Android [ProfileTabSwitcher].
struct ProfileTabSwitcher: View {
    @Environment(\.fashSpacing) private var spacing
    let tabSet: ProfileListingTabSet
    @Binding var selectedTab: Int

    var body: some View {
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
                }
            }
            .padding(.horizontal, spacing.editorialStart)
        }
        .background(FashColors.screen)
    }

    private var tabMinWidth: CGFloat {
        let screen = UIScreen.main.bounds.width
        let edge = spacing.editorialStart * 2
        let slots = min(3, CGFloat(tabSet.tabCount))
        return max((screen - edge) / slots, 96)
    }
}
