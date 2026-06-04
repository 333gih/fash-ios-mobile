import Foundation

/// Anchors for the feature tour overlay — Android [FeatureTourAnchor].
enum FeatureTourAnchor: Hashable {
    case bottomHome
    case bottomOrders
    case bottomPostFab
    case bottomChat
    case bottomProfile
    case topActionsRow
}

/// Guided tour steps — Android [AppTourStep].
enum AppTourStep: Int, CaseIterable {
    case intro
    case navHome
    case navOrders
    case navPost
    case navChat
    case navProfile
    case topBarActions

    var anchor: FeatureTourAnchor? {
        switch self {
        case .intro: return nil
        case .navHome: return .bottomHome
        case .navOrders: return .bottomOrders
        case .navPost: return .bottomPostFab
        case .navChat: return .bottomChat
        case .navProfile: return .bottomProfile
        case .topBarActions: return .topActionsRow
        }
    }

    var prepareTab: MainTab? {
        switch self {
        case .intro, .navHome, .navPost, .topBarActions: return .home
        case .navOrders: return .orders
        case .navChat: return .chat
        case .navProfile: return .profile
        }
    }

    /// Steps that spotlight a bottom-tab anchor — tour card stays above the tab bar.
    var isBottomNavAnchor: Bool {
        switch self {
        case .navHome, .navOrders, .navPost, .navChat, .navProfile: return true
        case .intro, .topBarActions: return false
        }
    }

    var title: String {
        switch self {
        case .intro: return L10n.appTourIntroTitle
        case .navHome: return L10n.appTourNavHomeTitle
        case .navOrders: return L10n.appTourNavOrdersTitle
        case .navPost: return L10n.appTourNavPostTitle
        case .navChat: return L10n.appTourNavChatTitle
        case .navProfile: return L10n.appTourNavProfileTitle
        case .topBarActions: return L10n.appTourTopBarTitle
        }
    }

    var body: String {
        switch self {
        case .intro: return L10n.appTourIntroBody
        case .navHome: return L10n.appTourNavHomeBody
        case .navOrders: return L10n.appTourNavOrdersBody
        case .navPost: return L10n.appTourNavPostBody
        case .navChat: return L10n.appTourNavChatBody
        case .navProfile: return L10n.appTourNavProfileBody
        case .topBarActions: return L10n.appTourTopBarBody
        }
    }
}
