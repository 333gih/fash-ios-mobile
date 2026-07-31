import Foundation

// MARK: - Unified Home Feed Models

struct UnifiedHomeFeedResponse: Codable {
    let rails: [HomeRail]
    let hero: HeroCard?
    let meta: RecommendationMeta?
    
    enum CodingKeys: String, CodingKey {
        case rails
        case hero
        case meta = "recommendation_meta"
    }
}

struct HomeRail: Codable, Identifiable {
    let railID: String
    let railType: String
    let title: String
    let subtitle: String?
    let items: [ListingWithMatch]
    let seeAllURL: String?
    let reasonLabel: String?
    
    var id: String { railID }
    
    enum CodingKeys: String, CodingKey {
        case railID = "rail_id"
        case railType = "rail_type"
        case title
        case subtitle
        case items
        case seeAllURL = "see_all_url"
        case reasonLabel = "reason_label"
    }
}

struct ListingWithMatch: Codable, Identifiable {
    let listing: ListingFeedItem
    let sizeMatch: SizeMatchInfo?
    let measurements: [String: Double]?
    let recommendReason: String?
    let imageAspectRatio: String?
    
    var id: String { listing.id }
    
    enum CodingKeys: String, CodingKey {
        case listing
        case sizeMatch = "size_match"
        case measurements
        case recommendReason = "recommend_reason"
        case imageAspectRatio = "image_aspect_ratio"
    }
}

struct SizeMatchInfo: Codable {
    let badge: String
    let confidence: Double
    let reason: String
}

struct HeroCard: Codable {
    let type: String
    let imageURL: String?
    let title: String
    let subtitle: String?
    let ctaURL: String?
    let aspectRatio: String
    
    enum CodingKeys: String, CodingKey {
        case type
        case imageURL = "image_url"
        case title
        case subtitle
        case ctaURL = "cta_url"
        case aspectRatio = "aspect_ratio"
    }
}

// MARK: - Rail Types

enum RailType: String {
    case grid = "grid"
    case horizontalScroll = "horizontal_scroll"
    case hero = "hero"
}

enum SizeMatchBadge: String {
    case yourSize = "your_size"
    case closeFit = "close_fit"
    case sizeUp = "size_up"
    case sizeDown = "size_down"
    
    var displayText: String {
        switch self {
        case .yourSize: return "Your Size"
        case .closeFit: return "Close Fit"
        case .sizeUp: return "Size Up"
        case .sizeDown: return "Size Down"
        }
    }
    
    var badgeColor: String {
        switch self {
        case .yourSize: return "green"
        case .closeFit: return "blue"
        case .sizeUp, .sizeDown: return "orange"
        }
    }
}
