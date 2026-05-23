import SwiftUI

struct GuestMainShell: View {
    @Bindable var router: AppRouter
    @State private var showLoginSheet = false

    var body: some View {
        MainNavScreen(router: router)
            .onChange(of: router.selectedTab) { _, tab in
                if tab == .post || tab == .chat || tab == .profile {
                    showLoginSheet = true
                }
            }
            .sheet(isPresented: $showLoginSheet) {
                Text(L10n.guestLoginSheetTitle)
                    .padding()
            }
    }
}
