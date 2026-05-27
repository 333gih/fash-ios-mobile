import SwiftUI

enum ProfileShare {
    static func launch(username: String, displayName: String?) {
        let handle = username.trimmingCharacters(in: .whitespacesAndNewlines).removePrefix("@")
        guard !handle.isEmpty else { return }
        let base = BuildConfig.listingShareBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let url = "\(base)/@\(handle)"
        let name = displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? handle
        let text = "\(name) — \(url)"
        let activity = UIActivityViewController(activityItems: [text, URL(string: url) as Any].compactMap { $0 }, applicationActivities: nil)
        guard let scene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let root = scene.windows.first?.rootViewController else { return }
        root.present(activity, animated: true)
    }
}

private extension String {
    func removePrefix(_ prefix: String) -> String {
        hasPrefix(prefix) ? String(dropFirst(prefix.count)) : self
    }
}
