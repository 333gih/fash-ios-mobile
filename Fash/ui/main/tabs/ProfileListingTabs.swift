import SwiftUI

enum ProfileListingTab: Int, CaseIterable {
    case active = 0
    case inReview = 1
    case rejected = 2
    case sold = 3
    case wishlist = 4

    var title: String {
        switch self {
        case .active: return L10n.profileTabSelling
        case .inReview: return L10n.profileTabInReview
        case .rejected: return L10n.profileTabRejected
        case .sold: return L10n.profileTabSold
        case .wishlist: return L10n.profileTabWishlist
        }
    }

    var emptyTitle: String {
        switch self {
        case .active: return L10n.profileEmptySellingTitle
        case .inReview: return L10n.profileEmptyInReviewTitle
        case .rejected: return L10n.profileEmptyRejectedTitle
        case .sold: return L10n.profileEmptySoldTitle
        case .wishlist: return L10n.profileEmptyWishlistTitle
        }
    }

    var emptySubtitle: String {
        switch self {
        case .active: return L10n.profileEmptySellingSubtitle
        case .inReview: return L10n.profileEmptyInReviewSubtitle
        case .rejected: return L10n.profileEmptyRejectedSubtitle
        case .sold: return L10n.profileEmptySoldSubtitle
        case .wishlist: return L10n.profileEmptyWishlistSubtitle
        }
    }
}

extension ListingFeedItem {
    func listingStatusNorm() -> String {
        let raw = listingStatus?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
        return raw.isEmpty ? "active" : raw
    }

    func isActiveListing() -> Bool { listingStatusNorm() == "active" }
    func isInReviewListing() -> Bool { listingStatusNorm() == "in_review" }
    func isRejectedListing() -> Bool { listingStatusNorm() == "rejected" }
    func isSoldListingStatus() -> Bool { listingStatusNorm() == "sold" }
}

struct ProfileListingTabBar: View {
    @Binding var selectedTab: ProfileListingTab

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(ProfileListingTab.allCases, id: \.rawValue) { tab in
                    Button {
                        selectedTab = tab
                    } label: {
                        Text(tab.title)
                            .font(FashTypography.labelLarge)
                            .foregroundStyle(selectedTab == tab ? Color.white : FashColors.textPrimary)
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(selectedTab == tab ? FashColors.brandPrimary : FashColors.surfaceContainer)
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal, 24)
        }
        .padding(.vertical, 8)
    }
}

struct ProfileListingGrid: View {
    let items: [ListingFeedItem]
    let tab: ProfileListingTab
    var showQuickActions: Bool = false
    var onListingClick: (ListingFeedItem) -> Void
    var onLike: ((ListingFeedItem) -> Void)? = nil
    var onSave: ((ListingFeedItem) -> Void)? = nil

    private let columns = [GridItem(.flexible(), spacing: 8), GridItem(.flexible(), spacing: 8)]

    var body: some View {
        if items.isEmpty {
            FashEmptyStateView(title: tab.emptyTitle, subtitle: tab.emptySubtitle)
                .padding(.vertical, 32)
        } else {
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(items) { item in
                    ListingGridCard(
                        item: item,
                        onTap: { onListingClick(item) },
                        showQuickActions: showQuickActions,
                        statusOverlayLabel: ListingStatusUi.overlayLabel(for: item.listingStatus, suppressActive: false),
                        onLike: onLike.map { handler in { handler(item) } },
                        onSave: onSave.map { handler in { handler(item) } }
                    )
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
    }
}
