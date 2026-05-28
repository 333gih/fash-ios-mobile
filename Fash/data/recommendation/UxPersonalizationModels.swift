import Foundation

struct HomeExploreShortcut: Equatable {
    var labelKey: String = ""
    var aestheticTagId: String?
    var aestheticTagName: String?
    var categoryId: String?
    var brandId: String?
}

struct HomeUxPersonalization: Equatable {
    var defaultTabKey: String = HomeFeedTabKeys.huntToday
    var tabOrder: [String] = []
    var prefetchTabs: [String] = []
    var sectionLimits: [String: Int] = [:]
    var exploreShortcut: HomeExploreShortcut?
}

struct ProfileUxPersonalization: Equatable {
    var defaultTabKey: String = ProfileTabKeys.selling
    var tabOrderKeys: [String] = []
    var primaryMode: String = "balanced"
}

struct UxPersonalizationBundle: Equatable {
    var home: HomeUxPersonalization = HomeUxPersonalization()
    var profile: ProfileUxPersonalization = ProfileUxPersonalization()
}

struct UxEventPayload: Equatable {
    let scope: String
    let tabKey: String
    let clientHour: Int?
    let dwellMs: Int?
}

enum HomeFeedTabKeys {
    static let huntToday = "hunt_today"
    static let forYou = "for_you"
    static let following = "following"
    static let stylePicks = "style_picks"
    static let similarSaved = "similar_saved"
}

enum ProfileTabKeys {
    static let selling = "selling"
    static let inReview = "in_review"
    static let rejected = "rejected"
    static let sold = "sold"
    static let wishlist = "wishlist"
}
