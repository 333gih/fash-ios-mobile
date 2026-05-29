import SwiftUI
import UIKit

struct SettingsScreen: View {
    @Environment(AppDependencies.self) private var deps
    var onBack: () -> Void
    var onLogout: () -> Void
    var onLogoutAll: () -> Void = {}
    var isLoggingOut: Bool = false
    var onOpenOrders: () -> Void
    var onOpenAddresses: () -> Void
    var onOpenEditProfile: () -> Void
    var onOpenChangePassword: () -> Void

    var body: some View {
        NavigationStack {
            List {
                Section(L10n.settingsSectionLanguage) {
                    Text(L10n.settingsLanguageHint)
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(FashColors.textSecondary)
                    LoginLanguageToggle()
                }
                Section(L10n.settingsSectionDisplay) {
                    Picker(L10n.settingsSectionDisplay, selection: Binding(
                        get: { deps.themePreference.mode },
                        set: { deps.themePreference.mode = $0; deps.themePreference.persist() }
                    )) {
                        Text(L10n.settingsThemeSystem).tag(AppThemeMode.system)
                        Text(L10n.settingsThemeLight).tag(AppThemeMode.light)
                        Text(L10n.settingsThemeDark).tag(AppThemeMode.dark)
                    }
                }
                Section(L10n.settingsSectionShopping) {
                    Button(L10n.settingsRowShippingAddresses, action: onOpenAddresses)
                    Button(L10n.settingsRowOrders, action: onOpenOrders)
                }
                Section(L10n.settingsSectionProfile) {
                    Button(L10n.settingsRowEditProfile, action: onOpenEditProfile)
                    Button(L10n.settingsRowChangePassword, action: onOpenChangePassword)
                }
                Section(L10n.settingsSectionNotifications) {
                    Button {
                        openAppNotificationSettings()
                    } label: {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(L10n.settingsRowNotificationSettings)
                            Text(L10n.settingsRowNotificationSettingsSub)
                                .font(FashTypography.bodySmall)
                                .foregroundStyle(FashColors.textSecondary)
                        }
                    }
                }
                Section(L10n.settingsSectionAccount) {
                    Button(L10n.homeLogout, role: .destructive, action: onLogout)
                        .disabled(isLoggingOut)
                    Button(L10n.homeLogoutAll, role: .destructive, action: onLogoutAll)
                        .disabled(isLoggingOut)
                }
                Section(L10n.settingsSectionAbout) {
                    Link(L10n.loginTerms, destination: URL(string: AppEnvironment.legalTermsURL(languageTag: AppLocale.currentTag))!)
                    Link(L10n.loginPrivacy, destination: URL(string: AppEnvironment.legalPrivacyURL(languageTag: AppLocale.currentTag))!)
                    Text(L10n.settingsAboutVersionValue(
                        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.9",
                        BuildConfig.flavor
                    ))
                    .font(FashTypography.bodyMedium)
                    .foregroundStyle(FashColors.textSecondary)
                }
            }
            .navigationTitle(L10n.settingsTitle)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button(action: onBack) {
                        FashBackButton.toolbarLabel()
                    }
                    .accessibilityLabel(L10n.cdBack)
                }
            }
        }
    }

    private func openAppNotificationSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
