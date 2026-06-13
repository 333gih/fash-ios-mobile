import SwiftUI

/// Blocking app-open promo — content-adaptive card (hero only when image/icon warranted).
struct FashAppPromoOverlayDialog: View {
    let campaign: AppPromoCampaign
    var onDismiss: () -> Void
    var onPrimaryClick: (AppPromoCampaign) -> Void
    var onSecondaryClick: ((AppPromoCampaign) -> Void)?

    private let cardMaxWidth: CGFloat = 340
    private let cardWidthFraction: CGFloat = 0.84
    private let cardMaxHeightFraction: CGFloat = 0.68
    private let cardAbsoluteMaxHeight: CGFloat = 460

    var body: some View {
        if let layout = AppPromoDialogLayout.resolve(campaign: campaign) {
            ZStack {
                Color.black.opacity(0.52)
                    .ignoresSafeArea()
                promoCard(layout: layout)
            }
        }
    }

    private func promoCard(layout: AppPromoDialogLayout) -> some View {
        GeometryReader { geo in
            let cardWidth = min(geo.size.width * cardWidthFraction, cardMaxWidth)
            let maxCardHeight = min(geo.size.height * cardMaxHeightFraction, cardAbsoluteMaxHeight)
            let heroHeight = layout.heroHeight(cardWidth: cardWidth)

            Group {
                if layout.prefersScrollableBody {
                    ScrollView(showsIndicators: true) {
                        promoCardBody(layout: layout, cardWidth: cardWidth)
                    }
                    .scrollBounceBehavior(.basedOnSize, axes: .vertical)
                    .frame(maxHeight: maxCardHeight)
                } else {
                    promoCardBody(layout: layout, cardWidth: cardWidth)
                }
            }
            .frame(width: cardWidth)
            .background(FashColors.surface, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(alignment: .topTrailing) {
                Button(action: onDismiss) {
                    Image(systemName: "xmark")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundStyle(heroHeight != nil ? .white : FashColors.textPrimary)
                        .frame(width: 32, height: 32)
                        .background(
                            (heroHeight != nil ? Color.black.opacity(0.42) : FashColors.surfaceContainerHigh),
                            in: Circle()
                        )
                }
                .padding(8)
            }
            .shadow(color: .black.opacity(0.22), radius: 20, y: 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        }
    }

    private func promoCardBody(layout: AppPromoDialogLayout, cardWidth: CGFloat) -> some View {
        let heroHeight = layout.heroHeight(cardWidth: cardWidth)
        let bodyTop = heroHeight != nil ? 14.0 : 12.0
        let ctaTop = heroHeight != nil ? 14.0 : (layout.showMessage ? 12.0 : 10.0)

        return VStack(spacing: 0) {
            if let heroHeight {
                promoHero(layout: layout, width: cardWidth, height: heroHeight)
            }
            if layout.showBadgeInline || layout.showTitle || layout.showMessage {
                VStack(alignment: .leading, spacing: 0) {
                    if layout.showBadgeInline, let badge = layout.badge {
                        promoInlineBadge(badge)
                            .padding(.bottom, 8)
                    }
                    if layout.showTitle {
                        Text(layout.title)
                            .font(FashTypography.titleMedium.weight(.bold))
                            .foregroundStyle(FashColors.textPrimary)
                            .lineLimit(3)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    if layout.showMessage, let message = layout.message {
                        if layout.showTitle {
                            Spacer().frame(height: 4)
                        }
                        Text(message)
                            .font(FashTypography.bodyMedium)
                            .foregroundStyle(FashColors.textSecondary)
                            .fixedSize(horizontal: false, vertical: true)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .padding(.horizontal, 18)
                .padding(.top, bodyTop)
            }
            VStack(spacing: 2) {
                Button(action: { onPrimaryClick(campaign) }) {
                    Text(layout.primaryLabel)
                        .font(FashTypography.labelLarge.weight(.semibold))
                        .foregroundStyle(FashColors.readableOnBrandPrimary)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .frame(minHeight: 44)
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
                if layout.showSecondary, let secondary = layout.secondaryLabel {
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
                            .lineLimit(1)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 4)
                    }
                }
            }
            .padding(.horizontal, 18)
            .padding(.top, ctaTop)
            .padding(.bottom, 16)
        }
    }

    @ViewBuilder
    private func promoHero(layout: AppPromoDialogLayout, width: CGFloat, height: CGFloat) -> some View {
        if layout.showImageHero {
            ZStack(alignment: .topLeading) {
                TabView {
                    ForEach(layout.imageUrls, id: \.self) { urlString in
                        FashAsyncImage(
                            url: FeedImageUrl.resolveListingImageUrlOrNil(urlString) ?? urlString,
                            contentMode: .fill
                        )
                        .frame(width: width, height: height)
                        .clipped()
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: layout.imageUrls.count > 1 ? .automatic : .never))
                .frame(width: width, height: height)
                LinearGradient(
                    colors: [.clear, Color.black.opacity(0.16)],
                    startPoint: .center,
                    endPoint: .bottom
                )
                .frame(width: width, height: height)
                .allowsHitTesting(false)
                if layout.showBadgeOnHero, let badge = layout.badge {
                    promoHeroBadge(badge, onBrand: true)
                }
            }
        } else if layout.showIconHero {
            ZStack(alignment: .topLeading) {
                LinearGradient(
                    colors: [FashColors.brandPrimary.opacity(0.18), FashColors.surfaceContainerHigh],
                    startPoint: .top,
                    endPoint: .bottom
                )
                heroIcon(for: layout.iconHeroKind)
                    .frame(width: width, height: height)
                if layout.showBadgeOnHero, let badge = layout.badge {
                    promoHeroBadge(badge, onBrand: false)
                }
            }
            .frame(width: width, height: height)
        }
    }

    @ViewBuilder
    private func heroIcon(for kind: AppPromoCampaignKind) -> some View {
        let symbol: String = switch kind {
        case .appRating: "star.fill"
        case .sellerPackage: "storefront"
        case .kycVerification: "checkmark.shield"
        default: "hand.wave"
        }
        Image(systemName: symbol)
            .font(.system(size: 28, weight: .semibold))
            .foregroundStyle(FashColors.brandPrimary)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func promoInlineBadge(_ text: String) -> some View {
        Text(text)
            .font(FashTypography.labelSmall.weight(.bold))
            .foregroundStyle(FashColors.brandPrimary)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(FashColors.brandPrimary.opacity(0.12), in: Capsule())
    }

    private func promoHeroBadge(_ text: String, onBrand: Bool) -> some View {
        Text(text)
            .font(FashTypography.labelSmall.weight(.bold))
            .foregroundStyle(onBrand ? FashColors.readableOnBrandPrimary : .white)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(onBrand ? FashColors.brandPrimary : FashColors.brandPrimary, in: Capsule())
            .padding(12)
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
