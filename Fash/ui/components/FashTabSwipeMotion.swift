import SwiftUI

/// Shared tab body motion — crossfade avoids white gaps from slide + height mismatch.
enum FashTabSwipeMotion {
    static let contentAnimation: Animation = .easeInOut(duration: 0.18)
    static let tabBarAnimation: Animation = .easeInOut(duration: 0.25)

    static var contentTransition: AnyTransition {
        .opacity
    }

    static func slideDirection(oldIndex: Int, newIndex: Int) -> Int {
        newIndex > oldIndex ? 1 : -1
    }
}

/// Touch targets for horizontally scrollable tab chips — Material Tab parity (~48pt).
enum FashScrollableTabMetrics {
    static let minChipHeight: CGFloat = 48
    static let horizontalPadding: CGFloat = 16
    static let verticalPadding: CGFloat = 12
    static let interTabSpacing: CGFloat = 6
}

extension View {
    /// Expands the tappable rect beyond label glyphs — Home / Profile / Seller tab rows.
    func fashScrollableTabChipStyle(minWidth: CGFloat = 0) -> some View {
        padding(.horizontal, FashScrollableTabMetrics.horizontalPadding)
            .padding(.vertical, FashScrollableTabMetrics.verticalPadding)
            .frame(minWidth: minWidth > 0 ? minWidth : nil, minHeight: FashScrollableTabMetrics.minChipHeight)
            .contentShape(Rectangle())
    }
}
