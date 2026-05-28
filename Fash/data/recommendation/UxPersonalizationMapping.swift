import Foundation

enum UxPersonalizationMapping {
    static func homeFeedTab(from key: String) -> HomeFeedTab? {
        switch key.trimmingCharacters(in: .whitespaces).lowercased() {
        case HomeFeedTabKeys.huntToday: return .huntToday
        case HomeFeedTabKeys.forYou: return .forYou
        case HomeFeedTabKeys.following: return .following
        case HomeFeedTabKeys.stylePicks: return .stylePicks
        case HomeFeedTabKeys.similarSaved: return .similarSaved
        default: return nil
        }
    }

    static func uxTabKey(for tab: HomeFeedTab) -> String {
        switch tab {
        case .huntToday: return HomeFeedTabKeys.huntToday
        case .forYou: return HomeFeedTabKeys.forYou
        case .following: return HomeFeedTabKeys.following
        case .stylePicks: return HomeFeedTabKeys.stylePicks
        case .similarSaved: return HomeFeedTabKeys.similarSaved
        }
    }

    static func orderedHomeFeedTabs(isGuestBrowse: Bool, tabOrderKeys: [String]) -> [HomeFeedTab] {
        let allowed = HomeFeedTab.tabsFor(isGuestBrowse: isGuestBrowse)
        guard !tabOrderKeys.isEmpty else { return allowed }
        let ordered = tabOrderKeys.compactMap { homeFeedTab(from: $0) }.filter { allowed.contains($0) }
        let remainder = allowed.filter { !ordered.contains($0) }
        return ordered + remainder
    }

    static func recommendationSectionTabs: Set<HomeFeedTab> {
        [.forYou, .stylePicks, .similarSaved]
    }

    static func profileTabIndex(from key: String) -> Int? {
        switch key.trimmingCharacters(in: .whitespaces).lowercased() {
        case ProfileTabKeys.selling: return ProfileListingTab.active.rawValue
        case ProfileTabKeys.inReview: return ProfileListingTab.inReview.rawValue
        case ProfileTabKeys.rejected: return ProfileListingTab.rejected.rawValue
        case ProfileTabKeys.sold: return ProfileListingTab.sold.rawValue
        case ProfileTabKeys.wishlist: return ProfileListingTab.wishlist.rawValue
        default: return nil
        }
    }

    static func profileTabKey(from index: Int) -> String {
        switch ProfileListingTab(rawValue: index) ?? .active {
        case .active: return ProfileTabKeys.selling
        case .inReview: return ProfileTabKeys.inReview
        case .rejected: return ProfileTabKeys.rejected
        case .sold: return ProfileTabKeys.sold
        case .wishlist: return ProfileTabKeys.wishlist
        }
    }

    static func orderedProfileTabIndices(tabOrderKeys: [String]) -> [Int] {
        let defaultOrder = ProfileListingTab.allCases.map(\.rawValue)
        guard !tabOrderKeys.isEmpty else { return defaultOrder }
        let ordered = tabOrderKeys.compactMap { profileTabIndex(from: $0) }
        let remainder = defaultOrder.filter { !ordered.contains($0) }
        return ordered + remainder
    }
}
