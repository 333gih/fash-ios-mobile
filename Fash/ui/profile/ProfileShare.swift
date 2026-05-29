import Foundation

enum ProfileShare {
    static func launch(
        username: String,
        displayName: String?,
        onCompleted: ((Bool) -> Void)? = nil
    ) {
        let handle = ProfileDeepLinks.normalizeUsername(username)
        guard !handle.isEmpty else { return }
        let web = AppEnvironment.profileShareURL(username: handle)
        guard !web.isEmpty else { return }
        let fashUri = ProfileDeepLinks.fashProfileURL(username: handle)?.absoluteString ?? ""
        let trimmedName = displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let name = trimmedName.isEmpty ? "@\(handle)" : trimmedName
        let text = L10n.shareProfileText(name, web, fashUri)
        let subject = L10n.shareProfileSubject(name)
        FashActivityShare.present(activityItems: [subject, text]) { onCompleted?($0) }
    }
}
