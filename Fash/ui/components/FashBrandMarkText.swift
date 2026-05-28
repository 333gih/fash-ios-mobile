import SwiftUI

/// Brand wordmark — Android [FashBrandMarkText].
struct FashBrandMarkText: View {
    var text: String = L10n.brandWordmark
    var style: FashBrandTypography.MarkStyle = FashBrandTypography.markBoldItalicMedium
    var color: Color = FashColors.brandPrimary
    var textAlign: TextAlignment = .center

    var body: some View {
        Text(text)
            .fashBrandMarkStyle(style)
            .foregroundStyle(color)
            .multilineTextAlignment(textAlign)
            .fixedSize(horizontal: false, vertical: true)
            .padding(.trailing, style.size * 0.06)
    }
}

/// `FASH.` + screen suffix — Android [FashScreenTitle].
struct FashScreenTitle: View {
    let suffix: String

    var body: some View {
        HStack(spacing: 10) {
            FashBrandMarkText(
                style: FashBrandTypography.markBoldItalicMedium,
                textAlign: .leading
            )
            Text(suffix)
                .font(FashTypography.titleLarge)
                .fontWeight(.bold)
                .foregroundStyle(FashColors.textPrimary)
                .lineLimit(1)
        }
    }
}
