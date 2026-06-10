import SwiftUI

/// Blocking app-open promo — Android `FashAppPromoOverlayDialog`.
struct FashAppPromoOverlayDialog: View {
    let campaign: AppPromoCampaign
    var onDismiss: () -> Void
    var onPrimaryClick: (AppPromoCampaign) -> Void
    var onSecondaryClick: ((AppPromoCampaign) -> Void)?

    private let cardMaxWidth: CGFloat = 380
    private let cardWidthFraction: CGFloat = 0.88
    private let cardMaxHeightFraction: CGFloat = 0.78
    private let heroHeight: CGFloat = 148

    var body: some View {
        ZStack {
            Color.black.opacity(0.52)
                .ignoresSafeArea()
            promoCard
        }
    }

    private var promoCard: some View {
        GeometryReader { geo in
            let cardWidth = min(geo.size.width * cardWidthFraction, cardMaxWidth)
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    ZStack(alignment: .topTrailing) {
                        promoHero
                        Button(action: onDismiss) {
                            Image(systemName: "xmark")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundStyle(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.black.opacity(0.42), in: Circle())
                        }
                        .padding(10)
                    }
                    VStack(alignment: .leading, spacing: 8) {
                        Text(titleText)
                            .font(FashTypography.titleLarge.weight(.bold))
                            .foregroundStyle(FashColors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(messageText)
                            .font(FashTypography.bodyMedium)
                            .foregroundStyle(FashColors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    VStack(spacing: 4) {
                        Button(action: { onPrimaryClick(campaign) }) {
                            Text(primaryLabel)
                                .font(FashTypography.labelLarge.weight(.semibold))
                                .foregroundStyle(FashColors.readableOnBrandPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: 50)
                                .background(
                                    LinearGradient(
                                        colors: [
                                            FashColors.brandPrimary,
                                            FashColors.brandPrimary.opacity(0.82),
                                        ],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    ),
                                    in: RoundedRectangle(cornerRadius: 12, style: .continuous)
                                )
                        }
                        if let secondary = secondaryLabel {
                            Button {
                                if let onSecondaryClick {
                                    onSecondaryClick(campaign)
                                } else {
                                    onDismiss()
                                }
                            } label: {
                                Text(secondary)
                                    .font(FashTypography.labelLarge)
                                    .foregroundStyle(FashColors.textSecondary)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 8)
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 22)
                }
            }
            .frame(width: cardWidth)
            .frame(maxHeight: geo.size.height * cardMaxHeightFraction)
            .background(FashColors.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .shadow(color: .black.opacity(0.22), radius: 20, y: 8)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }

    @ViewBuilder
    private var promoHero: some View {
        if campaign.kind == .remote, !campaign.remoteImageUrls.isEmpty {
            ZStack(alignment: .topLeading) {
                TabView {
                    ForEach(campaign.remoteImageUrls, id: \.self) { urlString in
                        FashAsyncImage(
                            url: FeedImageUrl.resolveListingImageUrlOrNil(urlString) ?? urlString,
                            contentMode: .fill
                        )
                        .frame(height: heroHeight)
                        .clipped()
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: campaign.remoteImageUrls.count > 1 ? .automatic : .never))
                .frame(height: heroHeight)
                LinearGradient(
                    colors: [.clear, Color.black.opacity(0.18)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .frame(height: heroHeight)
                .allowsHitTesting(false)
                if let badge = badgeLabel {
                    Text(badge)
                        .font(FashTypography.labelSmall.weight(.bold))
                        .foregroundStyle(FashColors.readableOnBrandPrimary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(FashColors.brandPrimary, in: Capsule())
                        .padding(12)
                }
            }
        } else {
            ZStack(alignment: .topLeading) {
                LinearGradient(
                    colors: [FashColors.brandPrimary.opacity(0.2), FashColors.surfaceContainerHigh],
                    startPoint: .top,
                    endPoint: .bottom
                )
                Image(systemName: heroSymbol)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(FashColors.brandPrimary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                if let badge = badgeLabel {
                    Text(badge)
                        .font(FashTypography.labelSmall.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(FashColors.brandPrimary, in: Capsule())
                        .padding(12)
                }
            }
            .frame(height: heroHeight)
        }
    }

    private var badgeLabel: String? {
        RemoteAppPromoModels.sanitizePromoDisplayString(campaign.remoteBadge)
    }

    private var titleText: String {
        RemoteAppPromoModels.sanitizePromoDisplayString(campaign.remoteTitle) ?? ""
    }

    private var messageText: String {
        RemoteAppPromoModels.sanitizePromoDisplayString(campaign.remoteMessage) ?? ""
    }

    private var primaryLabel: String {
        RemoteAppPromoModels.sanitizePromoDisplayString(campaign.remotePrimaryLabel) ?? L10n.appPromoRatingPrimary
    }

    private var secondaryLabel: String? {
        RemoteAppPromoModels.sanitizePromoDisplayString(campaign.remoteSecondaryLabel)
            ?? (campaign.kind == .remote ? nil : L10n.appPromoSecondaryLater)
    }

    private var heroSymbol: String {
        switch campaign.kind {
        case .appRating: return "star.fill"
        case .sellerPackage: return "storefront"
        case .kycVerification: return "checkmark.shield"
        default: return "hand.wave"
        }
    }
}

/// Host that shows the overlay when a campaign is set.
struct FashAppPromoOverlayHost: View {
    let campaign: AppPromoCampaign?
    var onDismiss: () -> Void
    var onPrimaryClick: (AppPromoCampaign) -> Void
    var onSecondaryClick: ((AppPromoCampaign) -> Void)?

    var body: some View {
        if let campaign {
            FashAppPromoOverlayDialog(
                campaign: campaign,
                onDismiss: onDismiss,
                onPrimaryClick: onPrimaryClick,
                onSecondaryClick: onSecondaryClick
            )
            .zIndex(200)
            .transition(.opacity)
        }
    }
}
