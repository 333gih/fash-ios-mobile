import SwiftUI

/// Layout rhythm (Android [FashSpacing]).
struct FashSpacing {
    let xxs: CGFloat = 4
    let xs: CGFloat = 8
    let sm: CGFloat = 12
    let md: CGFloat = 16
    let lg: CGFloat = 24
    let xl: CGFloat = 32
    let xxl: CGFloat = 48
    let editorialHorizontal: CGFloat = 20
}

private struct FashSpacingKey: EnvironmentKey {
    static let defaultValue = FashSpacing()
}

extension EnvironmentValues {
    var fashSpacing: FashSpacing {
        get { self[FashSpacingKey.self] }
        set { self[FashSpacingKey.self] = newValue }
    }
}
