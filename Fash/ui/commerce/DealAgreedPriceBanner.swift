import SwiftUI

struct DealAgreedPriceBannerView: View {
    let amountVnd: Int64
    let fromBuyNow: Bool

    var body: some View {
        if amountVnd < 1000 { EmptyView() }
        else {
            HStack(spacing: 10) {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(FashColors.brandPrimary)
                Text(fromBuyNow
                    ? L10n.dealAgreedPriceBuyNow(FeedPriceFormat.format(amountVnd))
                    : L10n.dealAgreedPriceNegotiated(FeedPriceFormat.format(amountVnd)))
                    .font(FashTypography.bodySmall.weight(.semibold))
                    .foregroundStyle(FashColors.textPrimary)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(FashColors.brandPrimary.opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }
}
