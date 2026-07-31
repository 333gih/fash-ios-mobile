import Foundation
import Observation

@Observable
class UnifiedHomeViewModel {
    // State
    var rails: [HomeRail] = []
    var heroCard: HeroCard?
    var promoSlides: [AdvertisingBanner] = []
    var isLoading = false
    var isLoadingMore = false
    var isRefreshing = false
    var hasMore = true
    var showOnlyMySize = false
    var error: Error?
    
    // Dependencies
    private let recommendationRepository: RecommendationRepository
    private let advertisingRepository: AdvertisingRepository
    private let feedEventReporter: FeedEventReporter
    
    // Configuration
    private let railLimit = 8
    private let itemsPerRail = 6
    
    init(
        recommendationRepository: RecommendationRepository,
        advertisingRepository: AdvertisingRepository,
        feedEventReporter: FeedEventReporter
    ) {
        self.recommendationRepository = recommendationRepository
        self.advertisingRepository = advertisingRepository
        self.feedEventReporter = feedEventReporter
    }
    
    // MARK: - Public Methods
    
    func loadInitialFeed() {
        guard !isLoading && rails.isEmpty else { return }
        
        Task { @MainActor in
            isLoading = true
            error = nil
            
            // Load unified feed and promo slides in parallel
            async let feedResult = loadUnifiedFeed()
            async let promoResult = loadPromoSlides()
            
            let (feed, promos) = await (feedResult, promoResult)
            
            if let feed = feed {
                self.rails = feed.rails
                self.heroCard = feed.hero
            }
            
            if let promos = promos {
                self.promoSlides = promos
            }
            
            isLoading = false
            
            // Track rail impressions
            trackRailImpressions()
        }
    }
    
    @MainActor
    func refresh() async {
        isRefreshing = true
        
        // Reset state
        rails.removeAll()
        heroCard = nil
        hasMore = true
        
        // Load fresh feed
        if let feed = await loadUnifiedFeed() {
            self.rails = feed.rails
            self.heroCard = feed.hero
        }
        
        // Refresh promo slides
        if let promos = await loadPromoSlides() {
            self.promoSlides = promos
        }
        
        isRefreshing = false
        
        // Track rail impressions
        trackRailImpressions()
    }
    
    func loadMore() {
        guard !isLoadingMore && hasMore else { return }
        
        Task { @MainActor in
            isLoadingMore = true
            
            // For now, load more is not implemented (would need pagination support)
            // TODO: Implement pagination when backend supports it
            hasMore = false
            
            isLoadingMore = false
        }
    }
    
    func toggleSizeFilter() {
        showOnlyMySize.toggle()
        
        // Reload feed with size filter
        Task { @MainActor in
            isLoading = true
            
            if let feed = await loadUnifiedFeed() {
                self.rails = feed.rails
                self.heroCard = feed.hero
            }
            
            isLoading = false
            trackRailImpressions()
        }
    }
    
    // MARK: - Private Methods
    
    private func loadUnifiedFeed() async -> UnifiedHomeFeedResponse? {
        let sizingMode = showOnlyMySize ? "match_profile" : "all"
        
        let result = await recommendationRepository.getUnifiedHomeFeed(
            railLimit: railLimit,
            itemsPerRail: itemsPerRail,
            sizingMode: sizingMode
        )
        
        switch result {
        case .success(let feed):
            return feed
        case .failure(let error):
            self.error = error
            print("Failed to load unified home feed: \(error)")
            return nil
        }
    }
    
    private func loadPromoSlides() async -> [AdvertisingBanner]? {
        let result = await advertisingRepository.getPromoSlides()
        
        switch result {
        case .success(let slides):
            return slides
        case .failure(let error):
            print("Failed to load promo slides: \(error)")
            return nil
        }
    }
    
    private func trackRailImpressions() {
        // Track impressions for all visible rails
        for rail in rails {
            for item in rail.items.prefix(6) {
                feedEventReporter.trackImpression(
                    listingID: item.listing.id,
                    surface: rail.railID,
                    position: nil
                )
            }
        }
    }
    
    func trackRailClick(rail: HomeRail, item: ListingWithMatch, position: Int) {
        feedEventReporter.trackClick(
            listingID: item.listing.id,
            surface: rail.railID,
            position: position
        )
    }
    
    func trackSizeMatchBadgeClick(item: ListingWithMatch) {
        // Track size badge interaction
        feedEventReporter.trackCustomEvent(
            eventType: "size_badge_click",
            listingID: item.listing.id,
            metadata: [
                "badge": item.sizeMatch?.badge ?? "none",
                "confidence": item.sizeMatch?.confidence ?? 0.0
            ]
        )
    }
}

// MARK: - Repository Extension

extension RecommendationRepository {
    func getUnifiedHomeFeed(
        railLimit: Int,
        itemsPerRail: Int,
        sizingMode: String
    ) async -> Result<UnifiedHomeFeedResponse, Error> {
        return await withCheckedContinuation { continuation in
            Task {
                do {
                    let url = "\(baseURL)/recommendations/unified-home-feed"
                    var components = URLComponents(string: url)
                    components?.queryItems = [
                        URLQueryItem(name: "rail_limit", value: "\(railLimit)"),
                        URLQueryItem(name: "items_per_rail", value: "\(itemsPerRail)"),
                        URLQueryItem(name: "sizing_mode", value: sizingMode)
                    ]
                    
                    guard let finalURL = components?.url else {
                        continuation.resume(returning: .failure(URLError(.badURL)))
                        return
                    }
                    
                    var request = URLRequest(url: finalURL)
                    request.httpMethod = "GET"
                    if let token = authToken {
                        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
                    }
                    
                    let (data, response) = try await URLSession.shared.data(for: request)
                    
                    guard let httpResponse = response as? HTTPURLResponse,
                          httpResponse.statusCode == 200 else {
                        continuation.resume(returning: .failure(URLError(.badServerResponse)))
                        return
                    }
                    
                    let decoder = JSONDecoder()
                    decoder.keyDecodingStrategy = .convertFromSnakeCase
                    let feed = try decoder.decode(UnifiedHomeFeedResponse.self, from: data)
                    
                    continuation.resume(returning: .success(feed))
                } catch {
                    continuation.resume(returning: .failure(error))
                }
            }
        }
    }
}
