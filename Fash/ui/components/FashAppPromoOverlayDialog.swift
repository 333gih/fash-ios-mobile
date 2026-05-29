import SwiftUI

/// Blocking app-open promo — Android `FashAppPromoOverlayDialog`.
struct FashAppPromoOverlayDialog: View {
    let campaign: AppPromoCampaign
    var onDismiss: () -> Void
    var onPrimaryClick: (AppPromoCampaign) -> Void
    var onSecondaryClick: ((AppPromoCampaign) -> Void)?

    @State private var isExpanded = false

    var body: some View {
        ZStack {
            Color.black.opacity(0.62)
                .ignoresSafeArea()
            promoCard
        }
        .onChange(of: campaign.campaignId) { _, _ in isExpanded = false }
        .onChange(of: campaign.version) { _, _ in isExpanded = false }
    }

    private var promoCard: some View {
        let maxWidth = isExpanded ? 520.0 : 400.0
        let widthFraction = isExpanded ? 0.94 : 0.86
        return GeometryReader { geo in
            let cardWidth = min(geo.size.width * widthFraction, maxWidth)
            ScrollView {
                VStack(spacing: 0) {
                    HStack {
                        Spacer()
                        Button {
                            isExpanded.toggle()
                        } label: {
                            Image(systemName: isExpanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(FashColors.textPrimary)
                                .frame(width: 40, height: 40)
                        }
                        Button(action: onDismiss) {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(FashColors.textPrimary)
                                .frame(width: 40, height: 40)
                        }
                    }
                    .padding(.horizontal, 4)
                    promoHero
                    VStack(alignment: .leading, spacing: isExpanded ? 10 : 8) {
                        Text(titleText)
                            .font(isExpanded ? FashTypography.headlineSmall.weight(.bold) : FashTypography.titleLarge.weight(.bold))
                            .foregroundStyle(FashColors.textPrimary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        Text(messageText)
                            .font(isExpanded ? FashTypography.bodyLarge : FashTypography.bodyMedium)
                            .foregroundStyle(FashColors.textSecondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(.horizontal, isExpanded ? 26 : 22)
                    .padding(.top, isExpanded ? 20 : 16)
                    VStack(spacing: 6) {
                        Button(action: { onPrimaryClick(campaign) }) {
                            Text(primaryLabel)
                                .font(FashTypography.labelLarge.weight(.semibold))
                                .foregroundStyle(FashColors.readableOnBrandPrimary)
                                .frame(maxWidth: .infinity)
                                .frame(minHeight: isExpanded ? 52 : 48)
                        }
                        .background(FashColors.brandPrimary, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
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
                            }
                        }
                    }
                    .padding(.horizontal, isExpanded ? 26 : 22)
                    .padding(.vertical, isExpanded ? 22 : 18)
                }
            }
            .frame(width: cardWidth)
            .frame(maxHeight: geo.size.height * (isExpanded ? 0.88 : 0.72))
            .background(FashColors.surfaceContainerHigh, in: RoundedRectangle(cornerRadius: isExpanded ? 24 : 22, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: isExpanded ? 24 : 22, style: .continuous)
                    .stroke(FashColors.textSecondary.opacity(0.25), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.2), radius: 12, y: 4)
            .position(x: geo.size.width / 2, y: geo.size.height / 2)
        }
    }

    @ViewBuilder
    private var promoHero: some View {
        let heroHeight: CGFloat = isExpanded ? 160 : 112
        if campaign.kind == .remote, !campaign.remoteImageUrls.isEmpty {
            TabView {
                ForEach(campaign.remoteImageUrls, id: \.self) { urlString in
                    AsyncImage(url: URL(string: urlString)) { phase in
                        switch phase {
                        case .success(let image):
                            image.resizable().scaledToFill()
                        default:
                            FashColors.surfaceContainer
                        }
                    }
                    .frame(height: heroHeight)
                    .clipped()
                }
            }
            .tabViewStyle(.page(indexDisplayMode: campaign.remoteImageUrls.count > 1 ? .automatic : .never))
            .frame(height: heroHeight)
        } else {
            ZStack {
                LinearGradient(
                    colors: [FashColors.brandPrimary.opacity(0.16), FashColors.surfaceContainerHigh],
                    startPoint: .top,
                    endPoint: .bottom
                )
                Image(systemName: heroSymbol)
                    .font(.system(size: isExpanded ? 36 : 28, weight: .semibold))
                    .foregroundStyle(FashColors.brandPrimary)
            }
            .frame(height: heroHeight)
        }
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
