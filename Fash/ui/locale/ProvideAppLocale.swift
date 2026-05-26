import SwiftUI

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
            .id(localeController.revision)
    }
}
