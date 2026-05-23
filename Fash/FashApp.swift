import SwiftUI

@main
struct FashApp: App {
    @State private var deps = AppDependencies.shared

    init() {
        AppLocale.applyPersistedOrDefault()
    }

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(deps)
                .environment(\.locale, AppLocale.locale)
                .preferredColorScheme(deps.themePreference.preferredColorScheme)
        }
    }
}
