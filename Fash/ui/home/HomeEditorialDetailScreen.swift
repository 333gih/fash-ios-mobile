import SwiftUI

struct HomeEditorialDetailScreen: View {
    var slug: String = ""
    var onDismiss: () -> Void = {}

    var body: some View {
        OverlayScreenHost(title: slug.isEmpty ? L10n.appName : slug, onDismiss: onDismiss) {
            Text(slug).padding()
        }
    }
}
