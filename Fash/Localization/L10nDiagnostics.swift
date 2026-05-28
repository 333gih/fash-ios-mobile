import Foundation

#if DEBUG
enum L10nDiagnostics {
    /// Call once at launch; logs when Localizable.strings cannot be read from the app bundle.
    static func verifyBundleOnLaunch() {
        for tag in [AppLocale.tagVI, AppLocale.tagEN] {
            let sample = L10n.t("nav_home")
            if sample == "nav_home" {
                print(
                    "[L10n] FAIL tag=\(tag): Localizable.strings not loaded. " +
                    "Check Copy Bundle Resources for vi.lproj/en.lproj in target Fash."
                )
            } else {
                print("[L10n] OK tag=\(tag) nav_home=\(sample)")
            }
        }
    }
}
#endif
