import Foundation
import Observation

@Observable
@MainActor
final class EditProfileViewModel {
    var profile: ProfileInfo?
    var displayName = ""
    var username = ""
    var bio = ""
    var selectedTagIds: Set<String> = []
    var tags: [CommonAestheticTagDto] = []
    var referenceSize = ""
    var measurementUnit = "cm"
    var measurementHem = ""
    var measurementChest = ""
    var measurementLength = ""
    var measurementShoulders = ""
    var measurementSleeve = ""
    var genderPreference = "women"
    var isLoading = true
    var isSubmitting = false
    var errorMessage: String?

    func load(deps: AppDependencies) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        if case .success(let catalog) = await deps.commonCatalogRepository.getAestheticTags(all: true) {
            tags = catalog
        }
        switch await deps.userRepository.getMeProfile() {
        case .success(let p):
            profile = p
            displayName = p.displayName
            username = p.username
            bio = p.bio
            referenceSize = p.referenceSize ?? ""
            measurementUnit = Self.normalizeUnit(p.referenceMeasurementUnit)
            measurementChest = Self.formatMeasurement(p.referenceMeasurementChest)
            measurementHem = Self.formatMeasurement(p.referenceMeasurementHem)
            measurementLength = Self.formatMeasurement(p.referenceMeasurementLength)
            measurementShoulders = Self.formatMeasurement(p.referenceMeasurementShoulders)
            measurementSleeve = Self.formatMeasurement(p.referenceMeasurementSleeveLength)
            if !p.gender.isEmpty {
                genderPreference = p.gender
            }
            selectedTagIds = Set(p.aestheticTagSnapshots.map(\.id).filter { !$0.isEmpty })
            if selectedTagIds.isEmpty {
                selectedTagIds = Set(
                    p.aestheticTags.compactMap { name in
                        tags.first(where: {
                            $0.name.caseInsensitiveCompare(name) == .orderedSame
                                || $0.displayName.caseInsensitiveCompare(name) == .orderedSame
                        })?.id
                    }
                )
            }
        case .failure(let err):
            errorMessage = FashErrorPresentation.userMessage(for: err)
        }
    }

    var canSave: Bool {
        guard profile != nil, !isSubmitting else { return false }
        guard !displayName.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        return hasChanges()
    }

    func toggleTag(_ id: String) {
        if selectedTagIds.contains(id) { selectedTagIds.remove(id) }
        else { selectedTagIds.insert(id) }
    }

    func save(deps: AppDependencies) async -> Bool {
        guard canSave, let patch = buildPatch() else { return false }
        isSubmitting = true
        defer { isSubmitting = false }
        switch await deps.userRepository.updateProfile(patch) {
        case .success:
            return true
        case .failure(let err):
            errorMessage = FashErrorPresentation.userMessage(for: err)
            return false
        }
    }

    private func hasChanges() -> Bool {
        guard let p = profile else { return false }
        if displayName.trimmingCharacters(in: .whitespaces) != p.displayName { return true }
        if username.trimmingCharacters(in: .whitespaces) != p.username { return true }
        if bio != p.bio { return true }
        if tagsChanged(from: p) { return true }
        let genderNorm = genderPreference.trimmingCharacters(in: .whitespaces).lowercased()
        let profileGender = p.gender.trimmingCharacters(in: .whitespaces).lowercased()
        if genderNorm != profileGender { return true }
        if sizingChanged(from: p) { return true }
        return false
    }

    private func tagsChanged(from p: ProfileInfo) -> Bool {
        let current = tags
            .filter { selectedTagIds.contains($0.id) }
            .map { AestheticTagPutItem(id: $0.id, name: $0.name) }
            .sorted { $0.id < $1.id }
        let original = canonicalOriginalTags(p).sorted { $0.id < $1.id }
        return current != original
    }

    private func canonicalOriginalTags(_ p: ProfileInfo) -> [AestheticTagPutItem] {
        if !p.aestheticTagSnapshots.isEmpty { return p.aestheticTagSnapshots }
        return p.aestheticTags.compactMap { name in
            tags.first(where: {
                $0.name.caseInsensitiveCompare(name) == .orderedSame
                    || $0.displayName.caseInsensitiveCompare(name) == .orderedSame
            }).map { AestheticTagPutItem(id: $0.id, name: $0.name) }
        }
    }

    private func sizingChanged(from p: ProfileInfo) -> Bool {
        let storedSize = p.referenceSize ?? ""
        if referenceSize.trimmingCharacters(in: .whitespaces) != storedSize { return true }
        if Self.normalizeUnit(measurementUnit) != Self.normalizeUnit(p.referenceMeasurementUnit) { return true }
        if !Self.doubleEq(Self.parseMeasurement(measurementChest), p.referenceMeasurementChest) { return true }
        if !Self.doubleEq(Self.parseMeasurement(measurementHem), p.referenceMeasurementHem) { return true }
        if !Self.doubleEq(Self.parseMeasurement(measurementLength), p.referenceMeasurementLength) { return true }
        if !Self.doubleEq(Self.parseMeasurement(measurementShoulders), p.referenceMeasurementShoulders) { return true }
        if !Self.doubleEq(Self.parseMeasurement(measurementSleeve), p.referenceMeasurementSleeveLength) { return true }
        return false
    }

    private func buildPatch() -> ProfilePatch? {
        guard let p = profile else { return nil }
        let profileGender = p.gender.trimmingCharacters(in: .whitespaces).lowercased()
        let genderNorm = genderPreference.trimmingCharacters(in: .whitespaces).lowercased()
        let sizingDirty = sizingChanged(from: p)
        let patch = ProfilePatch(
            displayName: displayName.trimmingCharacters(in: .whitespaces) != p.displayName
                ? displayName.trimmingCharacters(in: .whitespaces) : nil,
            username: username.trimmingCharacters(in: .whitespaces) != p.username
                ? username.trimmingCharacters(in: .whitespaces).nilIfEmpty : nil,
            bio: bio != p.bio ? bio : nil,
            aestheticTags: tagsChanged(from: p) ? buildPutItems() : nil,
            gender: genderNorm != profileGender ? genderNorm.nilIfEmpty : nil,
            referenceSize: sizingDirty
                ? SizingReferenceGuide.normalizedReferenceSizeForStorage(referenceSize, genderPreference: genderPreference)
                : nil,
            referenceMeasurementUnit: sizingDirty ? Self.normalizeUnit(measurementUnit) : nil,
            referenceMeasurementChest: sizingDirty ? Self.parseMeasurement(measurementChest) : nil,
            referenceMeasurementHem: sizingDirty ? Self.parseMeasurement(measurementHem) : nil,
            referenceMeasurementLength: sizingDirty ? Self.parseMeasurement(measurementLength) : nil,
            referenceMeasurementShoulders: sizingDirty ? Self.parseMeasurement(measurementShoulders) : nil,
            referenceMeasurementSleeveLength: sizingDirty ? Self.parseMeasurement(measurementSleeve) : nil
        )
        let hasField = patch.displayName != nil || patch.username != nil || patch.bio != nil
            || patch.aestheticTags != nil || patch.gender != nil || patch.referenceSize != nil
            || patch.referenceMeasurementUnit != nil || patch.referenceMeasurementChest != nil
            || patch.referenceMeasurementHem != nil || patch.referenceMeasurementLength != nil
            || patch.referenceMeasurementShoulders != nil || patch.referenceMeasurementSleeveLength != nil
        return hasField ? patch : nil
    }

    private func buildPutItems() -> [AestheticTagPutItem] {
        tags
            .filter { selectedTagIds.contains($0.id) }
            .map { AestheticTagPutItem(id: $0.id, name: $0.name) }
    }

    private static func normalizeUnit(_ raw: String?) -> String {
        let t = raw?.trimmingCharacters(in: .whitespaces).lowercased() ?? ""
        if t == "in" || t == "inch" || t == "inches" { return "in" }
        return t.isEmpty ? "cm" : t
    }

    private static func formatMeasurement(_ value: Double?) -> String {
        guard let value else { return "" }
        let rounded = (value * 10).rounded() / 10
        if rounded.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(rounded))
        }
        return String(rounded)
    }

    private static func parseMeasurement(_ s: String) -> Double {
        let t = s.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        guard !t.isEmpty, let v = Double(t) else { return 0 }
        return max(v, 0)
    }

    private static func doubleEq(_ a: Double, _ b: Double?) -> Bool {
        guard let b else { return abs(a) < 1e-9 }
        return abs(a - b) < 1e-3
    }
}

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
