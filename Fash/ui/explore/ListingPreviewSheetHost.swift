import SwiftUI

/// Legacy wrapper — prefer `ListingPreviewOverlay` (in-tab overlay, parallel navigation).
struct ListingPreviewSheetHost: View {
    @Environment(AppDependencies.self) private var deps
    @Bindable var listingPreview: ListingPreviewStore
    @Bindable var router: AppRouter
    var isGuestMode: Bool
    var onRequestLogin: (() -> Void)?

    var body: some View {
        ListingPreviewOverlay(
            listingPreview: listingPreview,
            router: router,
            isGuestMode: isGuestMode,
            onRequestLogin: onRequestLogin
        )
    }
}
