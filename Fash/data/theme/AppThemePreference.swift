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
}
