import SwiftUI

/// Branded fox mascot used on maintenance + return flows.
struct MaintenanceMascotImage: View {
    var maxWidth: CGFloat = 220

    var body: some View {
        Image("MaintenanceMascot")
            .resizable()
            .scaledToFit()
            .frame(maxWidth: maxWidth)
            .accessibilityHidden(true)
    }
}
