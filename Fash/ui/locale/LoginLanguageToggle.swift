import SwiftUI

/// Pill segmented control (VN | EN) — mirrors Android `LoginLanguageToggle.kt`.
struct LoginLanguageToggle: View {
    @Bindable private var localeController = AppLocaleController.shared

    var body: some View {
        let isEnglish = localeController.currentTag == AppLocale.tagEN
        ZStack {
            Capsule()
                .fill(FashColors.surfaceContainer.opacity(0.9))
            Capsule()
                .stroke(FashColors.outlineMuted.opacity(0.55), lineWidth: 1)
            HStack(spacing: 0) {
                localeSegment(title: "VI", selected: !isEnglish) {
                    localeController.setLocale(AppLocale.tagVI)
                }
                localeSegment(title: "EN", selected: isEnglish) {
                    localeController.setLocale(AppLocale.tagEN)
                }
            }
            .background(alignment: isEnglish ? .trailing : .leading) {
                Capsule()
                    .fill(FashColors.brandPrimary)
                    .frame(width: 58, height: 30)
                    .padding(2)
                    .animation(.easeInOut(duration: 0.22), value: isEnglish)
            }
        }
        .frame(width: 120, height: 34)
    }

    private func localeSegment(title: String, selected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(title)
                .font(FashTypography.labelLarge.weight(.bold))
                .foregroundStyle(selected ? FashColors.readableOnBrandPrimary : FashColors.textSecondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .buttonStyle(.plain)
        .zIndex(selected ? 1 : 0)
    }
}
