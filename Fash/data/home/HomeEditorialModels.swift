import Foundation

/// Carousel/list stub — Android `HomeEditorialPostStub`.
struct HomeEditorialPostStub: Identifiable, Equatable, Hashable {
    let id: String
    let slug: String
    let title: String
    let summary: String
    let coverImageUrl: String?
    let exploreCategoryId: String?
    let exploreSearchQuery: String?

    var listId: String { id.isEmpty ? slug : id }
}

struct EditorialGuideListPage: Equatable {
    let items: [HomeEditorialPostStub]
    let hasMore: Bool
}

struct EditorialGuideDetail: Equatable {
    let id: String
    let slug: String
    let title: String
    let summary: String
    let bodyMarkdown: String
    let coverImageUrl: String
    let exploreCategoryId: String?
    let exploreSearchQuery: String?
}

enum EditorialGuideDefaults {
    static let defaultCoverURL =
        "https://images.unsplash.com/photo-1523381210434-271e8be1f52b?w=1200&q=80"
}
