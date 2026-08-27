import SwiftUI

struct SellerPackageToolsScreen: View {
    @Environment(AppDependencies.self) private var deps
    var onDismiss: () -> Void

    @State private var listingId = ""
    @State private var caption = ""
    @State private var message: String?

    var body: some View {
        FashScreenScaffold(title: L10n.sellerPackagesToolsTitle, showBack: true, onBack: onDismiss) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    TextField(L10n.sellerPackagesToolsListingId, text: $listingId)
                        .textFieldStyle(.roundedBorder)
                    TextField(L10n.sellerPackagesToolsCaption, text: $caption)
                        .textFieldStyle(.roundedBorder)
                    if let message {
                        Text(message).font(FashTypography.bodySmall).foregroundStyle(FashColors.brandPrimary)
                    }
                    Button(L10n.sellerPackagesToolsVerify) { run { await deps.userEntitlementRepository.requestAuthenticity(listingId: listingId) } }
                        .buttonStyle(FashFilledButtonStyle())
                        .disabled(listingId.trimmingCharacters(in: .whitespaces).isEmpty)
                    Button(L10n.sellerPackagesToolsBoost) { run { await deps.userEntitlementRepository.applyExploreBoost(listingId: listingId) } }
                        .buttonStyle(FashFilledButtonStyle())
                        .disabled(listingId.trimmingCharacters(in: .whitespaces).isEmpty)
                    Button(L10n.sellerPackagesToolsFanpage) { run { await deps.userEntitlementRepository.requestFanpage(listingId: listingId, caption: caption) } }
                        .buttonStyle(FashFilledButtonStyle())
                    Button(L10n.sellerPackagesToolsSocial) { run { await deps.userEntitlementRepository.requestSocialPromo(listingId: listingId, caption: caption) } }
                        .buttonStyle(FashFilledButtonStyle())
                }
                .padding()
            }
        }
    }

    private func run(_ action: @escaping () async -> Result<Void, Error>) {
        Task {
            let result = await action()
            await MainActor.run {
                message = switch result {
                case .success: "OK"
                case .failure(let e): e.localizedDescription
                }
            }
        }
    }
}
