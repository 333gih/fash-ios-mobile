import SwiftUI

struct SettingsScreen: View {
    @Environment(AppDependencies.self) private var deps
    var onBack: () -> Void
    var onLogout: () -> Void
    var onOpenOrders: () -> Void
    var onOpenAddresses: () -> Void
    var onOpenEditProfile: () -> Void
    var onOpenChangePassword: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section(L10n.settingsSectionLanguage) {
                    LoginLanguageToggle()
                }
                Section(L10n.settingsSectionDisplay) {
                    Picker(L10n.settingsSectionDisplay, selection: Binding(
                        get: { deps.themePreference.mode },
                        set: { deps.themePreference.mode = $0; deps.themePreference.persist() },
                    )) {
                        Text(L10n.settingsThemeSystem).tag(AppThemeMode.system)
                        Text(L10n.settingsThemeLight).tag(AppThemeMode.light)
                        Text(L10n.settingsThemeDark).tag(AppThemeMode.dark)
                    }
                }
                Section(L10n.settingsSectionAccount) {
                    Button(L10n.settingsRowEditProfile, action: onOpenEditProfile)
                    Button(L10n.settingsRowChangePassword, action: onOpenChangePassword)
                    Button(L10n.settingsRowShippingAddresses, action: onOpenAddresses)
                    Button(L10n.settingsRowOrders, action: onOpenOrders)
                }
                Section {
                    Button(L10n.homeLogout, role: .destructive, action: onLogout)
                }
                Section(L10n.settingsSectionAbout) {
                    Link(L10n.loginTerms, destination: URL(string: AppEnvironment.legalTermsURL(languageTag: AppLocale.currentTag))!)
                    Link(L10n.loginPrivacy, destination: URL(string: AppEnvironment.legalPrivacyURL(languageTag: AppLocale.currentTag))!)
                    Text("\(L10n.settingsAboutVersionLabel) 1.0.3 · \(BuildConfig.flavor)")
                        .font(FashTypography.bodyMedium)
                        .foregroundStyle(FashColors.textSecondary)
                }
            }
            .navigationTitle(L10n.settingsTitle)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onBack) { Image(systemName: "chevron.left") }
                }
            }
        }
    }
}
