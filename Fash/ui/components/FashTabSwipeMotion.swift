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
