import SwiftUI

private struct L10nRevisionKey: EnvironmentKey {
    static let defaultValue = 0
}

extension EnvironmentValues {
    /// Bumps when in-app language changes so views re-resolve `L10n.*` strings.
    var l10nRevision: Int {
        get { self[L10nRevisionKey.self] }
        set { self[L10nRevisionKey.self] = newValue }
    }
}

/// Port of Android `ProvideAppLocale` — re-applies SwiftUI locale when the user toggles VN/EN.
struct ProvideAppLocale<Content: View>: View {
    @Bindable private var localeController = AppLocaleController.shared
    @ViewBuilder private var content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .environment(\.locale, localeController.locale)
            .environment(\.l10nRevision, localeController.revision)
            .id(localeController.revision)
    }
}
