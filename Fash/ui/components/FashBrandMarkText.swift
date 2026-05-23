import SwiftUI

struct FashBrandMarkText: View {
    var text: String = L10n.brandWordmark

    var body: some View {
        Text(text)
            .font(FashTypography.displayLarge)
            .italic()
            .foregroundStyle(FashColors.brandPrimary)
    }
}
