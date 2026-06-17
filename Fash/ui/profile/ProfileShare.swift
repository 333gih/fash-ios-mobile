import Foundation

enum ProfileShare {
    static func sharePayload(username: String, displayName: String?) -> FashSharePayload? {
        let handle = ProfileDeepLinks.normalizeUsername(username)
        guard !handle.isEmpty else { return nil }
        let web = AppEnvironment.profileShareURL(username: handle)
        guard !web.isEmpty else { return nil }
        let fashUri = ProfileDeepLinks.fashProfileURL(username: handle)?.absoluteString ?? ""
        let trimmedName = displayName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let name = trimmedName.isEmpty ? "@\(handle)" : trimmedName
        let text = L10n.shareProfileText(name, web, fashUri)
        let subject = L10n.shareProfileSubject(name)
        return FashSharePayload(items: [subject, text])
    }

    @available(*, deprecated, message: "Use sharePayload + ActivityShareSheet sheet(item:)")
    static func launch(
        username: String,
        displayName: String?,
        onCompleted: ((Bool) -> Void)? = nil
    ) {
        guard let payload = sharePayload(username: username, displayName: displayName) else { return }
        FashActivityShare.present(activityItems: payload.items) { onCompleted?($0) }
    }
}
