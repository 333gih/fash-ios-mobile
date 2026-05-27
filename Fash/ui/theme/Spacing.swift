import SwiftUI

/// Layout rhythm — Android [FashSpacing] (1 dp ≈ 1 pt).
struct FashSpacing {
    let spacing1: CGFloat = 4
    let spacing2: CGFloat = 8
    let spacing3: CGFloat = 12
    let spacing4: CGFloat = 16
    let spacing5: CGFloat = 27
    let spacing6: CGFloat = 32
    let spacing7: CGFloat = 40
    let spacing8: CGFloat = 48
    let buttonHeight: CGFloat = 48
    let editorialStart: CGFloat = 24
    let editorialEnd: CGFloat = 16
    let radiusSoftMin: CGFloat = 12
    let radiusCard: CGFloat = 16
    let radiusPill: CGFloat = 20

    // Legacy aliases used in older iOS code
    var xxs: CGFloat { spacing1 }
    var xs: CGFloat { spacing2 }
    var sm: CGFloat { spacing3 }
    var md: CGFloat { spacing4 }
    var lg: CGFloat { editorialStart }
    var xl: CGFloat { spacing6 }
    var xxl: CGFloat { spacing8 }
    var editorialHorizontal: CGFloat { editorialStart }

    func editorialHorizontalPadding() -> EdgeInsets {
        EdgeInsets(top: 0, leading: editorialStart, bottom: 0, trailing: editorialEnd)
    }
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
