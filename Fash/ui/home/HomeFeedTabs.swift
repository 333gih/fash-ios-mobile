import SwiftUI

/// Home discovery tabs — Android [HomeFeedTab].
enum HomeFeedTab: String, CaseIterable, Identifiable {
    case huntToday = "hunt_today"
    case forYou = "for_you"
    case following = "following"
    case stylePicks = "style_picks"
    case similarSaved = "similar_saved"

    var id: String { rawValue }

    var title: String {
        switch self {
        case .huntToday: return L10n.homeHuntTodayTitle
        case .forYou: return L10n.homeSectionForYouTitle
        case .following: return L10n.homeTopSectionTitle
        case .stylePicks: return L10n.homeStylePicksTitle
        case .similarSaved: return L10n.homeSectionSimilarToSavedTitle
        }
    }

    var requiresAuth: Bool {
        switch self {
        case .huntToday: return false
        default: return true
        }
    }

    var analyticsSurface: String {
        switch self {
        case .huntToday: return "hunt_today"
        case .forYou: return "recommendation_for_you"
        case .following: return "home"
        case .stylePicks: return "style_picks"
        case .similarSaved: return "similar_to_saved"
        }
    }

    static var recommendationSectionTabs: Set<HomeFeedTab> {
        [.forYou, .stylePicks, .similarSaved]
    }

    var guestTitle: String {
        switch self {
        case .forYou: return L10n.homeGuestTabForYouTitle
        case .following: return L10n.homeGuestTabFollowingTitle
        case .stylePicks: return L10n.homeGuestTabStyleTitle
        case .similarSaved: return L10n.homeGuestTabSimilarTitle
        default: return L10n.guestLoginSheetTitle
        }
    }

    var guestBody: String {
        switch self {
        case .forYou: return L10n.homeGuestTabForYouBody
        case .following: return L10n.homeGuestTabFollowingBody
        case .stylePicks: return L10n.homeGuestTabStyleBody
        case .similarSaved: return L10n.homeGuestTabSimilarBody
        default: return L10n.guestLoginSheetPrivacyNote
        }
    }

    static func tabsFor(isGuestBrowse: Bool) -> [HomeFeedTab] {
        isGuestBrowse ? [.huntToday, .forYou, .following] : allCases
    }

    var emptyTitle: String {
        switch self {
        case .huntToday: return L10n.homeTabEmptyHuntTitle
        case .forYou: return L10n.homeTabEmptyForYouTitle
        case .stylePicks: return L10n.homeTabEmptyStyleTitle
        case .similarSaved: return L10n.homeTabEmptySimilarTitle
        case .following: return L10n.homeTabEmptyFollowingTitle
        }
    }

    var emptySubtitle: String {
        switch self {
        case .huntToday: return L10n.homeTabEmptyHuntSubtitle
        case .forYou: return L10n.homeTabEmptyForYouSubtitle
        case .stylePicks: return L10n.homeTabEmptyStyleSubtitle
        case .similarSaved: return L10n.homeTabEmptySimilarSubtitle
        case .following: return L10n.homeTabEmptyFollowingSubtitle
        }
    }
}

struct HomeFeedTabSwitcher: View {
    @Environment(\.fashSpacing) private var spacing
    @Namespace private var tabIndicator
    let tabs: [HomeFeedTab]
    let selectedTab: HomeFeedTab
    var isGuestBrowse: Bool = false
    let onSelect: (HomeFeedTab) -> Void

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 4) {
                    ForEach(tabs) { tab in
                        let selected = tab == selectedTab
                        Button {
                            onSelect(tab)
                        } label: {
                            HStack(spacing: 4) {
                                if isGuestBrowse && tab.requiresAuth {
                                    Image(systemName: "lock")
                                        .font(.system(size: 14))
                                        .foregroundStyle(selected ? FashColors.textPrimary : FashColors.textSecondary.opacity(0.75))
                                }
                                Text(tab.title)
                                    .font(FashTypography.labelLarge)
                                    .fontWeight(selected ? .bold : .regular)
                                    .foregroundStyle(selected ? FashColors.textPrimary : FashColors.textSecondary.opacity(0.75))
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 12)
                            .background(alignment: .bottom) {
                                if selected {
                                    Capsule()
                                        .fill(FashColors.brandPrimary)
                                        .frame(height: 2)
                                        .padding(.horizontal, 6)
                                        .matchedGeometryEffect(id: "home_tab_indicator", in: tabIndicator)
                                }
                            }
                        }
                        .buttonStyle(.plain)
                        .id(tab.id)
                    }
                }
                .padding(.horizontal, spacing.editorialStart)
            }
            .background(FashColors.screen)
            .animation(.spring(response: 0.34, dampingFraction: 0.86), value: selectedTab.id)
            .onChange(of: selectedTab.id) { _, _ in
                withAnimation(.spring(response: 0.34, dampingFraction: 0.86)) {
                    proxy.scrollTo(selectedTab.id, anchor: .center)
                }
            }
            .onAppear {
                proxy.scrollTo(selectedTab.id, anchor: .center)
            }
        }
    }
}

struct HomeFeedTabGuestGate: View {
    let tab: HomeFeedTab
    var onSignIn: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            FashEmptyStateView(
                title: tab.guestTitle,
                subtitle: tab.guestBody
            )
            FashPrimaryButton(title: L10n.homeGuestTabSignIn, action: onSignIn)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 24)
    }
}

struct HomeFeedTabGenericEmpty: View {
    let tab: HomeFeedTab

    var body: some View {
        FashEmptyStateView(title: tab.emptyTitle, subtitle: tab.emptySubtitle)
            .padding(.vertical, 32)
    }
}

