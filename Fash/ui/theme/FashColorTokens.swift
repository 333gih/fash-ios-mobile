import SwiftUI

/// Single source of truth for brand colors (Android [FashColorTokens]).
enum FashColorTokens {
    enum LightEditorial {
        static let brandPrimary = Color(hex: 0xFF4B64)
        static let brandPrimaryDeep = Color(hex: 0xE03E56)
        static let brandPrimaryContainer = Color(hex: 0xFF7A8C)
        static let onBrandPrimary = Color(hex: 0xFFEFEC)
        static let screen = Color(hex: 0xF3F0EB)
        static let surfaceVariant = Color(hex: 0xE8E3DD)
        static let surfaceContainerLow = Color(hex: 0xF6F3EF)
        static let surfaceContainer = Color(hex: 0xF9F7F4)
        static let surfaceContainerHigh = Color(hex: 0xFBFAF8)
        static let surfaceContainerHighest = Color.white
        static let textPrimary = Color(hex: 0x1C1917)
        static let textSecondary = Color(hex: 0x52443F)
        static let outlineStrong = Color(hex: 0x5C534E)
        static let outlineMuted = Color(hex: 0xA89890)
        static let error = Color(hex: 0xBA1A1A)
        static let success = Color(hex: 0x2E7D32)
    }

    enum LightPureWhite {
        static let screen = Color.white
        static let surfaceVariant = Color(hex: 0xF0F0EE)
        static let surfaceContainerLow = Color(hex: 0xFAFAFA)
        static let surfaceContainer = Color(hex: 0xF5F5F5)
        static let surfaceContainerHigh = Color.white
        static let surfaceContainerHighest = Color.white
        static let outlineStrong = Color(hex: 0x5C534E)
        static let outlineMuted = Color(hex: 0xA09088)
    }

    enum Dark {
        static let brandPrimary = Color(hex: 0xFF6B7D)
        static let brandPrimaryContainer = Color(hex: 0xB02140)
        static let screen = Color(hex: 0x141210)
        static let surfaceContainerLow = Color(hex: 0x1C1916)
        static let surfaceContainer = Color(hex: 0x231F1C)
        static let surfaceContainerHigh = Color(hex: 0x2B2623)
        static let surfaceContainerHighest = Color(hex: 0x342E2A)
        static let textPrimary = Color(hex: 0xF5EFEA)
        static let textSecondary = Color(hex: 0xD0C4BC)
        static let outlineStrong = Color(hex: 0x9D8B83)
        static let outlineMuted = Color(hex: 0x4A4340)
        static let error = Color(hex: 0xFFB4AB)
    }
}

extension Color {
    init(hex: UInt32, alpha: Double = 1) {
        let r = Double((hex >> 16) & 0xFF) / 255
        let g = Double((hex >> 8) & 0xFF) / 255
        let b = Double(hex & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: alpha)
    }
}
