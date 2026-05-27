import SwiftUI

struct ProfileScreen: View {
    @Environment(AppDependencies.self) private var deps
    @Bindable var viewModel: ProfileViewModel
    var onEditProfile: () -> Void
    var onOpenSettings: () -> Void = {}

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                profileHero
                VStack(alignment: .leading, spacing: 16) {
                    if viewModel.isLoading && viewModel.displayName.isEmpty {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                            .padding(.top, 24)
                    } else if viewModel.loadError && viewModel.displayName.isEmpty {
                        FashEmptyStateView(
                            title: L10n.feedLoadError,
                            actionTitle: L10n.feedRetry
                        ) {
                            Task { await viewModel.refresh(deps: deps) }
                        }
                    } else {
                        Text(viewModel.displayName.isEmpty ? L10n.navProfile : viewModel.displayName)
                            .font(FashTypography.headlineMedium)
                            .foregroundStyle(FashColors.textPrimary)
                        if !viewModel.username.isEmpty {
                            Text("@\(viewModel.username)")
                                .font(FashTypography.bodyMedium)
                                .foregroundStyle(FashColors.textSecondary)
                        }
                        if !viewModel.bio.isEmpty {
                            Text(viewModel.bio)
                                .font(FashTypography.bodyMedium)
                                .foregroundStyle(FashColors.textSecondary)
                        }
                        HStack(spacing: 20) {
                            profileStat(value: viewModel.followerCount, label: L10n.profileFollowers)
                            profileStat(value: viewModel.followingCount, label: L10n.profileFollowing)
                            profileStat(value: viewModel.productCount, label: L10n.profileProducts)
                        }
                        HStack(spacing: 12) {
                            Button(L10n.profileEdit, action: onEditProfile)
                                .font(FashTypography.labelLarge)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(FashColors.surfaceContainer)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                            Button(L10n.settingsTitle, action: onOpenSettings)
                                .font(FashTypography.labelLarge)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(FashColors.surfaceContainer)
                                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                        }
                    }
                }
                .padding(24)
            }
        }
        .refreshable { await viewModel.refresh(deps: deps) }
        .task { await viewModel.refresh(deps: deps) }
    }

    private var profileHero: some View {
        ZStack(alignment: .bottomLeading) {
            FashAsyncImage(url: viewModel.coverImageUrl)
                .frame(height: 168)
                .frame(maxWidth: .infinity)
                .clipped()
                .background(FashColors.surfaceContainerHigh)
            FashAvatarCircle(url: viewModel.avatarUrl, size: 80)
                .overlay(Circle().stroke(FashColors.screen, lineWidth: 3))
                .padding(.leading, 24)
                .offset(y: 40)
        }
        .padding(.bottom, 40)
    }

    private func profileStat(value: Int, label: String) -> some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(FashTypography.titleSmall)
                .foregroundStyle(FashColors.textPrimary)
            Text(label)
                .font(FashTypography.labelSmall)
                .foregroundStyle(FashColors.textSecondary)
        }
    }
}
