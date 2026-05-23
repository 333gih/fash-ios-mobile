import SwiftUI

enum AppThemeMode: String {
    case system
    case light
    case dark
}

enum AppLightAppearance: String {
    case editorial
    case pureWhite
}

@Observable
final class AppThemePreference {
    static let shared = AppThemePreference()

    var mode: AppThemeMode = .system
    var lightAppearance: AppLightAppearance = .editorial

    func resolvedIsDark(systemDark: Bool) -> Bool {
        switch mode {
        case .system: return systemDark
        case .light: return false
        case .dark: return true
        }
    }

    var preferredColorScheme: ColorScheme? {
        switch mode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }

    func persist() {
        UserDefaults.standard.set(mode.rawValue, forKey: "fash_theme_mode")
        UserDefaults.standard.set(lightAppearance.rawValue, forKey: "fash_light_appearance")
    }

    func loadPersisted() {
        if let raw = UserDefaults.standard.string(forKey: "fash_theme_mode"),
           let m = AppThemeMode(rawValue: raw) {
            mode = m
        }
        if let raw = UserDefaults.standard.string(forKey: "fash_light_appearance"),
           let a = AppLightAppearance(rawValue: raw) {
            lightAppearance = a
        }
    }
}
