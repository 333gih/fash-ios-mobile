import SwiftUI

/// Named shape tokens matching Android `FashShapes` (ui.theme).
enum FashShapes {
    static let extraSmall = RoundedRectangle(cornerRadius: 12, style: .continuous)
    static let small = RoundedRectangle(cornerRadius: 12, style: .continuous)
    static let medium = RoundedRectangle(cornerRadius: 16, style: .continuous)
    static let large = RoundedRectangle(cornerRadius: 20, style: .continuous)
    static let pill = Capsule()

    static func card(_ spacing: FashSpacing) -> RoundedRectangle {
        RoundedRectangle(cornerRadius: spacing.radiusCard, style: .continuous)
    }

    static func softMin(_ spacing: FashSpacing) -> RoundedRectangle {
        RoundedRectangle(cornerRadius: spacing.radiusSoftMin, style: .continuous)
    }
}
