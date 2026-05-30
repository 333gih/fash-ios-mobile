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
        return !displayName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func toggleTag(_ id: String) {
        if selectedTagIds.contains(id) { selectedTagIds.remove(id) }
        else { selectedTagIds.insert(id) }
    }

    func save(deps: AppDependencies) async -> Bool {
        guard canSave else { return false }
        isSubmitting = true
        defer { isSubmitting = false }
        let tagItems = tags
            .filter { selectedTagIds.contains($0.id) }
            .map { AestheticTagPutItem(id: $0.id, name: $0.name) }
        let profileGender = profile?.gender.trimmingCharacters(in: .whitespaces).lowercased() ?? ""
        let genderNorm = genderPreference.trimmingCharacters(in: .whitespaces).lowercased()
        let patch = ProfilePatch(
            displayName: displayName.trimmingCharacters(in: .whitespaces),
            username: username.trimmingCharacters(in: .whitespaces).nilIfEmpty,
            bio: bio.trimmingCharacters(in: .whitespaces),
            aestheticTags: tagItems,
            gender: genderNorm != profileGender ? genderNorm.nilIfEmpty : nil,
            referenceSize: SizingReferenceGuide.normalizedReferenceSizeForStorage(
                referenceSize,
                genderPreference: genderPreference
            )
        )
        switch await deps.userRepository.updateProfile(patch) {
        case .success:
            return true
        case .failure(let err):
            errorMessage = FashErrorPresentation.userMessage(for: err)
            return false
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
