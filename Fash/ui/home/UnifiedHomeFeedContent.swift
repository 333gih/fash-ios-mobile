import SwiftUI

/// New unified home feed - single scroll with mixed rails (replaces tabbed UI)
struct UnifiedHomeFeedContent: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps
    @Bindable var viewModel: UnifiedHomeViewModel
    @Bindable var router: AppRouter
    var isGuestMode: Bool
    
    @State private var scrollPosition: CGPoint = .zero
    @State private var quickActionsSticky = false
    
    var body: some View {
        ZStack(alignment: .top) {
            ScrollView {
                LazyVStack(spacing: 0, pinnedViews: [.sectionHeaders]) {
                    // Hero Card (Daily Style Story)
                    if let hero = viewModel.heroCard {
                        HeroCardView(hero: hero)
                            .padding(.horizontal, spacing.spacing3)
                            .padding(.bottom, spacing.spacing4)
                    }
                    
                    // Quick Actions Bar (becomes sticky)
                    Section {
                        EmptyView()
                    } header: {
                        QuickActionsBar(
                            onSizeFilterTap: { viewModel.toggleSizeFilter() },
                            onSearchTap: { router.openSearch() },
                            onSavedTap: { router.openSaved() },
                            isSizeFilterActive: viewModel.showOnlyMySize
                        )
                        .background(Color.fashBackground)
                    }
                    
                    // Rails (mixed content sections)
                    ForEach(viewModel.rails) { rail in
                        RailSection(
                            rail: rail,
                            columnWidth: masonryColumnWidth,
                            spacing: spacing,
                            onListingTap: { listing in
                                router.openListingDetail(listingID: listing.id)
                            },
                            onSeeAllTap: {
                                if let url = rail.seeAllURL {
                                    // Navigate to explore with surface
                                    router.openExploreWithSurface(url)
                                }
                            }
                        )
                        .padding(.bottom, spacing.spacing5)
                    }
                    
                    // Loading more indicator
                    if viewModel.isLoadingMore {
                        ProgressView()
                            .padding(.vertical, spacing.spacing4)
                    }
                    
                    // Brand footer
                    if !viewModel.rails.isEmpty && !viewModel.hasMore {
                        HomeBrandFooter()
                            .padding(.vertical, spacing.spacing6)
                    }
                }
                .padding(.bottom, 100) // Bottom safe area for promo dock
            }
            .refreshable {
                await viewModel.refresh()
            }
            .onAppear {
                viewModel.loadInitialFeed()
            }
            
            // Sticky promo dock at bottom (if exists)
            if !viewModel.promoSlides.isEmpty {
                VStack {
                    Spacer()
                    StickyPromoDock(slides: viewModel.promoSlides)
                }
            }
        }
    }
    
    private var masonryColumnWidth: CGFloat {
        ListingMasonryGrid.feedGridColumnWidth(
            containerWidth: UIScreen.main.bounds.width,
            spacing: spacing
        )
    }
}

// MARK: - Hero Card

struct HeroCardView: View {
    let hero: HeroCard
    @Environment(\.fashSpacing) private var spacing
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            // Hero image (3:4 portrait)
            if let imageURL = hero.imageURL {
                AsyncImage(url: URL(string: imageURL)) { image in
                    image
                        .resizable()
                        .aspectRatio(3/4, contentMode: .fill)
                } placeholder: {
                    Color.gray.opacity(0.2)
                        .aspectRatio(3/4, contentMode: .fill)
                }
                .clipped()
            } else {
                // Fallback gradient
                LinearGradient(
                    colors: [.fashPrimary.opacity(0.8), .fashPrimary],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .aspectRatio(3/4, contentMode: .fill)
            }
            
            // Overlay gradient
            LinearGradient(
                colors: [.clear, .black.opacity(0.7)],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Text overlay
            VStack(alignment: .leading, spacing: spacing.spacing2) {
                Text(hero.title)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                if let subtitle = hero.subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .padding(spacing.spacing4)
        }
        .cornerRadius(12)
        .onTapGesture {
            if let ctaURL = hero.ctaURL {
                // Handle hero CTA tap
                print("Hero tapped: \(ctaURL)")
            }
        }
    }
}

// MARK: - Quick Actions Bar

struct QuickActionsBar: View {
    let onSizeFilterTap: () -> Void
    let onSearchTap: () -> Void
    let onSavedTap: () -> Void
    let isSizeFilterActive: Bool
    
    @Environment(\.fashSpacing) private var spacing
    
    var body: some View {
        HStack(spacing: spacing.spacing3) {
            // Size filter toggle
            Button(action: onSizeFilterTap) {
                HStack(spacing: spacing.spacing2) {
                    Image(systemName: "ruler")
                        .font(.system(size: 16))
                    Text("My Size")
                        .font(.subheadline)
                }
                .padding(.horizontal, spacing.spacing3)
                .padding(.vertical, spacing.spacing2)
                .background(isSizeFilterActive ? Color.fashPrimary : Color.gray.opacity(0.1))
                .foregroundColor(isSizeFilterActive ? .white : .primary)
                .cornerRadius(20)
            }
            
            Spacer()
            
            // Search
            Button(action: onSearchTap) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 18))
                    .foregroundColor(.primary)
            }
            
            // Saved
            Button(action: onSavedTap) {
                Image(systemName: "heart")
                    .font(.system(size: 18))
                    .foregroundColor(.primary)
            }
        }
        .padding(.horizontal, spacing.spacing4)
        .padding(.vertical, spacing.spacing3)
    }
}

// MARK: - Rail Section

struct RailSection: View {
    let rail: HomeRail
    let columnWidth: CGFloat
    let spacing: FashSpacing
    let onListingTap: (ListingFeedItem) -> Void
    let onSeeAllTap: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing.spacing3) {
            // Rail header
            HStack {
                VStack(alignment: .leading, spacing: spacing.spacing1) {
                    Text(rail.title)
                        .font(.title3)
                        .fontWeight(.semibold)
                    
                    if let subtitle = rail.subtitle {
                        Text(subtitle)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Spacer()
                
                if rail.seeAllURL != nil {
                    Button(action: onSeeAllTap) {
                        Text("See All")
                            .font(.subheadline)
                            .foregroundColor(.fashPrimary)
                    }
                }
            }
            .padding(.horizontal, spacing.spacing4)
            
            // Rail content based on type
            if rail.railType == RailType.grid.rawValue {
                RailGridContent(
                    items: rail.items,
                    columnWidth: columnWidth,
                    spacing: spacing,
                    onListingTap: onListingTap
                )
            } else if rail.railType == RailType.horizontalScroll.rawValue {
                RailHorizontalScrollContent(
                    items: rail.items,
                    columnWidth: columnWidth,
                    spacing: spacing,
                    onListingTap: onListingTap
                )
            }
        }
    }
}

// MARK: - Rail Grid Content (2-column masonry)

struct RailGridContent: View {
    let items: [ListingWithMatch]
    let columnWidth: CGFloat
    let spacing: FashSpacing
    let onListingTap: (ListingFeedItem) -> Void
    
    var body: some View {
        LazyVStack(spacing: spacing.spacing3) {
            // Show only first 6 items in rail
            let displayItems = Array(items.prefix(6))
            ForEach(Array(displayItems.enumerated()), id: \.element.id) { index, item in
                PortraitListingCard(
                    item: item,
                    width: columnWidth,
                    onTap: { onListingTap(item.listing) }
                )
            }
        }
        .padding(.horizontal, spacing.spacing4)
    }
}

// MARK: - Rail Horizontal Scroll Content

struct RailHorizontalScrollContent: View {
    let items: [ListingWithMatch]
    let columnWidth: CGFloat
    let spacing: FashSpacing
    let onListingTap: (ListingFeedItem) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: spacing.spacing3) {
                ForEach(items.prefix(10)) { item in
                    PortraitListingCard(
                        item: item,
                        width: columnWidth * 0.85,
                        onTap: { onListingTap(item.listing) }
                    )
                }
            }
            .padding(.horizontal, spacing.spacing4)
        }
    }
}

// MARK: - Portrait Listing Card (3:4 ratio with size badge)

struct PortraitListingCard: View {
    let item: ListingWithMatch
    let width: CGFloat
    let onTap: () -> Void
    
    @Environment(\.fashSpacing) private var spacing
    
    private var imageHeight: CGFloat {
        width * (4.0 / 3.0) // 3:4 portrait ratio
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: spacing.spacing2) {
            // Image (3:4 portrait)
            ZStack(alignment: .topTrailing) {
                FashAsyncImage(
                    url: item.listing.coverImageURL,
                    width: width,
                    height: imageHeight
                )
                .cornerRadius(8)
                
                // Size match badge (top right)
                if let sizeMatch = item.sizeMatch {
                    SizeMatchBadge(badge: sizeMatch.badge)
                        .padding(spacing.spacing2)
                }
            }
            
            // Title
            Text(item.listing.title)
                .font(.subheadline)
                .lineLimit(2)
                .frame(maxWidth: width, alignment: .leading)
            
            // Price & Brand
            HStack {
                Text(formatPrice(item.listing.price))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                
                if let brand = item.listing.brand {
                    Text("·")
                        .foregroundColor(.secondary)
                    Text(brand)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            // Recommendation reason (if available)
            if let reason = item.recommendReason {
                Text(reason)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
        .frame(width: width)
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
    }
    
    private func formatPrice(_ price: Int64) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 0
        let formattedPrice = formatter.string(from: NSNumber(value: price)) ?? "\(price)"
        return "\(formattedPrice)₫"
    }
}

// MARK: - Size Match Badge

struct SizeMatchBadge: View {
    let badge: String
    @Environment(\.fashSpacing) private var spacing
    
    private var badgeInfo: (text: String, color: Color) {
        let matchBadge = SizeMatchBadge(rawValue: badge)
        let text = matchBadge?.displayText ?? badge
        let color: Color = {
            switch matchBadge {
            case .yourSize: return .green
            case .closeFit: return .blue
            case .sizeUp, .sizeDown: return .orange
            case .none: return .gray
            }
        }()
        return (text, color)
    }
    
    var body: some View {
        Text(badgeInfo.text)
            .font(.caption2)
            .fontWeight(.medium)
            .foregroundColor(.white)
            .padding(.horizontal, spacing.spacing2)
            .padding(.vertical, 4)
            .background(badgeInfo.color)
            .cornerRadius(6)
    }
}

// MARK: - Home Brand Footer

struct HomeBrandFooter: View {
    var body: some View {
        VStack(spacing: 8) {
            Text("You've reached the end")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("Pull to refresh for new items")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Sticky Promo Dock

struct StickyPromoDock: View {
    let slides: [AdvertisingBanner]
    
    var body: some View {
        FashPromoSlider(
            slides: slides.map(FashPromoSlideDef.fromAdvertising),
            onSlideClick: { slide in
                print("Promo tapped: \(slide.title ?? "")")
            }
        )
        .frame(height: FashStickyPromoDockHeight)
        .background(Color.fashBackground)
        .shadow(color: .black.opacity(0.1), radius: 8, y: -2)
    }
}
