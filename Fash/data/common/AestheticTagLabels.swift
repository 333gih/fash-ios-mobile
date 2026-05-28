import Foundation

extension CommonAestheticTagDto {
    /// Locale-aware label: Vietnamese when [preferVi] and [displayNameVi] is set, else English [displayName].
    func displayLabel(preferVi: Bool) -> String {
        let vi = displayNameVi.trimmingCharacters(in: .whitespacesAndNewlines)
        let en = displayName.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let enResolved = en.isEmpty ? fallback : en
        if preferVi, !vi.isEmpty { return vi }
        return enResolved.isEmpty ? (vi.isEmpty ? fallback : vi) : enResolved
    }

    func displayLabel() -> String {
        displayLabel(preferVi: AppLocale.currentTag != AppLocale.tagEN)
    }
}

enum AestheticTagLabels {
    /// Resolve a stored snapshot (id + canonical name) against the common-service catalog.
    static func resolveLabel(
        catalog: [CommonAestheticTagDto],
        id: String?,
        rawName: String,
        preferVi: Bool
    ) -> String {
        if let tagId = id?.trimmingCharacters(in: .whitespacesAndNewlines), !tagId.isEmpty,
           let hit = catalog.first(where: { $0.id.caseInsensitiveCompare(tagId) == .orderedSame }) {
            return hit.displayLabel(preferVi: preferVi)
        }
        let raw = rawName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !raw.isEmpty else { return raw }
        if let hit = catalog.first(where: {
            $0.name.caseInsensitiveCompare(raw) == .orderedSame
                || $0.displayName.caseInsensitiveCompare(raw) == .orderedSame
                || $0.displayNameVi.caseInsensitiveCompare(raw) == .orderedSame
        }) {
            return hit.displayLabel(preferVi: preferVi)
        }
        return raw
    }

    static func resolveLabel(
        catalog: [CommonAestheticTagDto],
        id: String?,
        rawName: String
    ) -> String {
        resolveLabel(catalog: catalog, id: id, rawName: rawName, preferVi: AppLocale.currentTag != AppLocale.tagEN)
    }
}
