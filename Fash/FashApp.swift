import SwiftUI

@main
struct FashApp: App {
    @State private var deps = AppDependencies.shared

    init() {
        AppLocale.applyPersistedOrDefault()
        AppThemePreference.shared.loadPersisted()
    }

    var body: some Scene {
        WindowGroup {
            ProvideAppLocale {
                RootView()
                    .environment(deps)
                    .preferredColorScheme(deps.themePreference.preferredColorScheme)
            }
        }
    }
}
