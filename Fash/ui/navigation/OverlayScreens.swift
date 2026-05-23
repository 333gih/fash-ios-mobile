import SwiftUI

struct OverlayScreenHost<Content: View>: View {
    let title: String
    var onDismiss: () -> Void
    @ViewBuilder let content: () -> Content

    var body: some View {
        FashScreenScaffold(title: title, showBack: true, onBack: onDismiss, content: content)
    }
}

struct EditListingScreen: View {
    var listingId: String = ""
    var onDismiss: () -> Void = {}

    var body: some View {
        OverlayScreenHost(title: L10n.editListingSave, onDismiss: onDismiss) {
            Text(listingId).padding()
        }
    }
}

struct ShippingAddressListScreen: View {
    var onDismiss: () -> Void = {}
    var body: some View {
        OverlayScreenHost(title: L10n.addressListTitle, onDismiss: onDismiss) {
            Text(L10n.addressEmptyAlertBody).padding()
        }
    }
}

struct AddEditAddressScreen: View {
    var onDismiss: () -> Void = {}
    var body: some View {
        OverlayScreenHost(title: L10n.addressAddTitle, onDismiss: onDismiss) {
            Text(L10n.addressConfirm).padding()
        }
    }
}

struct HomeEditorialDetailScreen: View {
    var slug: String = ""
    var onDismiss: () -> Void = {}
    var body: some View {
        OverlayScreenHost(title: slug, onDismiss: onDismiss) {
            Text(slug).padding()
        }
    }
}

struct HomeDeliveringScreen: View {
    var onDismiss: () -> Void = {}
    var body: some View {
        OverlayScreenHost(
            title: AppEnvironment.shippingEnabled ? L10n.homeDeliveringScreenTitle : L10n.homeDeliveringComingSoonTitle,
            onDismiss: onDismiss,
        ) {
            Text(AppEnvironment.shippingEnabled ? L10n.homeDeliveringListIntro : L10n.homeDeliveringComingSoonBody).padding()
        }
    }
}

struct FollowConnectionsScreen: View {
    var onDismiss: () -> Void = {}
    var body: some View {
        OverlayScreenHost(title: L10n.profileFollowers, onDismiss: onDismiss) {
            Text(L10n.profileFollowing).padding()
        }
    }
}

struct FeaturedSellersScreen: View {
    var onDismiss: () -> Void = {}
    var body: some View {
        OverlayScreenHost(title: L10n.exploreFeaturedSellers, onDismiss: onDismiss) {
            Text(L10n.exploreFeaturedSellers).padding()
        }
    }
}

struct ChangePasswordScreen: View {
    var onDismiss: () -> Void = {}
    var body: some View {
        OverlayScreenHost(title: L10n.settingsRowChangePassword, onDismiss: onDismiss) {
            Text(L10n.settingsRowChangePassword).padding()
        }
    }
}

struct SellerProductPackagesScreen: View {
    var onDismiss: () -> Void = {}
    var body: some View {
        OverlayScreenHost(title: L10n.sellerPackagesScreenTitle, onDismiss: onDismiss) {
            Text(L10n.sellerPackagesScreenSubtitle).padding()
        }
    }
}
