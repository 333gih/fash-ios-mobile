import SwiftUI

struct MainNavScreen: View {
    @Bindable var router: AppRouter
    @State private var homeVM = HomeViewModel()
    @State private var exploreVM = ExploreViewModel()
    @State private var profileVM = ProfileViewModel()
    @State private var chatVM = ChatViewModel()

    var body: some View {
        VStack(spacing: 0) {
            topBar
            tabContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            bottomBar
        }
        .background(FashColors.screen)
        .sheet(isPresented: $router.showNotificationScreen) {
            NotificationScreen()
        }
        .sheet(isPresented: $router.showSettingsScreen) {
            SettingsScreen()
        }
    }

    private var topBar: some View {
        HStack {
            tabTitle
            Spacer()
            Button { router.showNotificationScreen = true } label: {
                Image(systemName: "bell")
            }
            Button { router.showOrdersScreen = true } label: {
                Image(systemName: "bag")
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 10)
    }

    @ViewBuilder
    private var tabTitle: some View {
        HStack(spacing: 8) {
            FashBrandMarkText()
            Text(headerSuffix)
                .font(FashTypography.titleMedium)
        }
    }

    private var headerSuffix: String {
        switch router.selectedTab {
        case .home: return L10n.brandHeaderSuffixHome
        case .explore: return L10n.brandHeaderSuffixExplore
        case .post: return L10n.brandHeaderSuffixPost
        case .chat: return L10n.brandHeaderSuffixChat
        case .profile: return L10n.brandHeaderSuffixProfile
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch router.selectedTab {
        case .home:
            HomeFeedContent(viewModel: homeVM, onListingTap: { router.selectedListingId = $0 })
        case .explore:
            ExploreScreen(viewModel: exploreVM, onListingTap: { router.selectedListingId = $0 })
        case .post:
            CreateListingFlowScreen()
        case .chat:
            ChatScreen(viewModel: chatVM, onConversationTap: { router.selectedConversationId = $0 })
        case .profile:
            ProfileScreen(viewModel: profileVM, onEditProfile: { router.showEditProfile = true })
        }
    }

    private var bottomBar: some View {
        HStack {
            ForEach(MainTab.allCases, id: \.rawValue) { tab in
                Button {
                    router.selectedTab = tab
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: icon(for: tab))
                        Text(label(for: tab))
                            .font(.caption2)
                    }
                    .foregroundStyle(router.selectedTab == tab ? FashColors.brandPrimary : FashColors.textSecondary)
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding(.vertical, 8)
        .background(FashColors.surfaceContainer)
    }

    private func icon(for tab: MainTab) -> String {
        switch tab {
        case .home: return "house.fill"
        case .explore: return "safari.fill"
        case .post: return "plus.circle.fill"
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .profile: return "person.fill"
        }
    }

    private func label(for tab: MainTab) -> String {
        switch tab {
        case .home: return L10n.navHome
        case .explore: return L10n.navExplore
        case .post: return L10n.navPost
        case .chat: return L10n.navChat
        case .profile: return L10n.navProfile
        }
    }
}
