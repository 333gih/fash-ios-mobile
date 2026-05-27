import SwiftUI

struct ProfileScreen: View {
    @Environment(AppDependencies.self) private var deps
    @Bindable var viewModel: ProfileViewModel
    var onEditProfile: () -> Void
    var onOpenFollowConnections: (Int) -> Void = { _ in }
    var onShippingAddressesClick: () -> Void = {}
    var onInviteFriendsClick: () -> Void = {}
    var onListingClick: (String, String?) -> Void = { _, _ in }

    @State private var selectedTab: ProfileListingTab = .active

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
                            title: L10n.profileLoadError,
                            actionTitle: L10n.feedRetry
                        ) {
                            Task { await viewModel.refresh(deps: deps) }
                        }
                    } else {
                        identityBlock
                        metricsCard
                        quickActionsCard
                        ProfileListingTabBar(selectedTab: $selectedTab)
                        ProfileListingGrid(
                            items: viewModel.listings(for: selectedTab),
                            tab: selectedTab,
                            showQuickActions: true,
                            onListingClick: { item in onListingClick(item.id, item.sellerId) },
                            onLike: { item in Task { await viewModel.toggleLike(item, deps: deps) } },
                            onSave: { item in Task { await viewModel.toggleSave(item, deps: deps) } }
                        )
                    }
                }
                .padding(.horizontal, 0)
                .padding(.bottom, 24)
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

    private var identityBlock: some View {
        VStack(alignment: .leading, spacing: 8) {
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
            Button(L10n.profileEdit, action: onEditProfile)
                .font(FashTypography.labelLarge)
                .foregroundStyle(FashColors.brandPrimary)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(FashColors.surfaceContainer)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .padding(.horizontal, 24)
    }

    private var metricsCard: some View {
        HStack(spacing: 0) {
            profileStat(value: formatCount(viewModel.followerCount), label: L10n.profileFollowers) {
                onOpenFollowConnections(1)
            }
            divider
            profileStat(value: "\(viewModel.followingCount)", label: L10n.profileFollowing) {
                onOpenFollowConnections(0)
            }
            divider
            profileStat(value: "\(viewModel.productCount)", label: L10n.profileProducts)
            divider
            profileStat(value: "\(viewModel.soldCount)", label: L10n.profileSold)
        }
        .padding(.vertical, 8)
        .background(FashColors.surfaceContainer)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .padding(.horizontal, 24)
    }

    private var quickActionsCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.profileQuickActionsTitle)
                .font(FashTypography.labelMedium)
                .foregroundStyle(FashColors.textSecondary)
                .padding(.horizontal, 4)
            VStack(spacing: 0) {
                if !viewModel.username.isEmpty {
                    quickActionRow(icon: "square.and.arrow.up", title: L10n.profileShareShopTitle, subtitle: L10n.profileShareShopSubtitle) {
                        ProfileShare.launch(username: viewModel.username, displayName: viewModel.displayName)
                    }
                    Divider().padding(.horizontal, 14)
                }
                quickActionRow(icon: "mappin.and.ellipse", title: L10n.profileShippingAddresses, subtitle: L10n.addressListSubtitleManage, action: onShippingAddressesClick)
                Divider().padding(.horizontal, 14)
                quickActionRow(icon: "person.badge.plus", title: L10n.profileInviteFriendsTitle, subtitle: L10n.profileInviteFriendsSubtitle, action: onInviteFriendsClick)
            }
            .background(FashColors.surfaceContainer)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .padding(.horizontal, 24)
    }

    private func quickActionRow(icon: String, title: String, subtitle: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundStyle(FashColors.brandPrimary)
                    .frame(width: 40, height: 40)
                    .background(FashColors.brandPrimary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(FashTypography.titleSmall)
                        .foregroundStyle(FashColors.textPrimary)
                    Text(subtitle)
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(FashColors.textSecondary)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(FashColors.textSecondary)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
        }
        .buttonStyle(.plain)
    }

    private var divider: some View {
        Rectangle()
            .fill(FashColors.outlineMuted.opacity(0.35))
            .frame(width: 1, height: 40)
    }

    private func profileStat(value: String, label: String, action: (() -> Void)? = nil) -> some View {
        Button(action: { action?() }) {
            VStack(spacing: 2) {
                Text(value)
                    .font(FashTypography.titleSmall)
                    .fontWeight(.bold)
                    .foregroundStyle(FashColors.textPrimary)
                Text(label)
                    .font(FashTypography.labelSmall)
                    .foregroundStyle(FashColors.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .disabled(action == nil)
    }

    private func formatCount(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000)
        }
        if count >= 1_000 {
            return String(format: "%.1fk", Double(count) / 1_000)
        }
        return "\(count)"
    }
}
