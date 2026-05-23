import SwiftUI

struct ListingGridCard: View {
    let item: ListingFeedItem
    var onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 8) {
                FashAsyncImage(url: item.imageURL)
                    .frame(height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                Text(item.title)
                    .font(FashTypography.bodyMedium)
                    .foregroundStyle(FashColors.textPrimary)
                    .lineLimit(2)
                Text(FeedPriceFormat.format(item.price))
                    .font(FashTypography.labelLarge)
                    .foregroundStyle(FashColors.brandPrimary)
            }
        }
        .buttonStyle(.plain)
    }
}

enum FeedPriceFormat {
    static func format(_ price: Int64) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = "."
        let n = formatter.string(from: NSNumber(value: price)) ?? "\(price)"
        return "₫\(n)"
    }
}
