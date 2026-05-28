import SwiftUI

@main
struct FashApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var deps = AppDependencies.shared

    init() {
        AppLocale.applyPersistedOrDefault()
        AppThemePreference.shared.loadPersisted()
        GoogleSignInClients.configureIfNeeded()
        #if DEBUG
        L10nDiagnostics.verifyBundleOnLaunch()
        #endif
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
