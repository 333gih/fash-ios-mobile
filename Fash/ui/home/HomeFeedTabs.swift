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
        case .following: return L10n.feedEmptyTitle
        }
    }

    var emptySubtitle: String {
        switch self {
        case .huntToday: return L10n.homeTabEmptyHuntSubtitle
        case .forYou: return L10n.homeTabEmptyForYouSubtitle
        case .stylePicks: return L10n.homeTabEmptyStyleSubtitle
        case .similarSaved: return L10n.homeTabEmptySimilarSubtitle
        case .following: return L10n.feedEmptySubtitle
        }
    }
}

struct HomeFeedTabSwitcher: View {
    @Environment(\.fashSpacing) private var spacing
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
                            .overlay(alignment: .bottom) {
                                if selected {
                                    Capsule()
                                        .fill(FashColors.brandPrimary)
                                        .frame(height: 2)
                                        .padding(.horizontal, 6)
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
            .onChange(of: selectedTab.id) { _, _ in
                withAnimation(.easeInOut(duration: 0.2)) {
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

/// Rich empty state for the Following tab — Android [HomePersonalizedFeedEmptyCard].
struct HomePersonalizedFeedEmptyCard: View {
    @Environment(\.fashSpacing) private var spacing
    var onExploreClick: () -> Void
    var onFeaturedSellersClick: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: spacing.spacing2) {
            VStack(alignment: .leading, spacing: 4) {
                Text(L10n.homeTopSectionTitle)
                    .font(FashTypography.titleMedium.weight(.bold))
                    .foregroundStyle(FashColors.textPrimary)
                Text(L10n.homeTopSectionSubtitle)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
            }
            .padding(.horizontal, spacing.editorialStart)

            VStack(spacing: spacing.spacing2) {
                Image(systemName: "heart")
                    .font(.system(size: 28))
                    .foregroundStyle(FashColors.brandPrimary)
                    .frame(width: 56, height: 56)
                    .background(FashColors.brandPrimary.opacity(0.12))
                    .clipShape(Circle())
                Text(L10n.homeFeedEmptyTitle)
                    .font(FashTypography.titleSmall.weight(.bold))
                    .foregroundStyle(FashColors.textPrimary)
                    .multilineTextAlignment(.center)
                Text(L10n.homeFeedEmptySubtitle)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
                    .multilineTextAlignment(.center)
                FashPrimaryButton(title: L10n.homeEmptyCtaExplore, action: onExploreClick)
                Button(L10n.homeFeedEmptyCtaFeatured, action: onFeaturedSellersClick)
                    .buttonStyle(.bordered)
                    .tint(FashColors.brandPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, spacing.spacing3)
            .padding(.vertical, spacing.spacing4)
            .background(FashColors.surfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: spacing.radiusCard, style: .continuous))
            .padding(.horizontal, spacing.editorialStart)
        }
        .padding(.top, spacing.spacing2)
        .padding(.bottom, spacing.spacing4)
    }
}
