import SwiftUI

struct ProfileScreen: View {
    @Bindable var viewModel: ProfileViewModel
    var onEditProfile: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(viewModel.displayName.isEmpty ? L10n.navProfile : viewModel.displayName)
                    .font(FashTypography.headlineMedium)
                Button(L10n.profileEdit, action: onEditProfile)
            }
            .padding(20)
        }
        .task { await viewModel.refresh() }
    }
}
