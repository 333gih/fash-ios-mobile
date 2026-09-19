import Observation
import PhotosUI
import SwiftUI

enum PersonalizationStep: CaseIterable {
    case photo, tags, sizing, bio, following

    var title: String {
        switch self {
        case .photo: return L10n.personalizationStepPhoto
        case .tags: return L10n.personalizationStepTags
        case .sizing: return L10n.personalizationStepSizing
        case .bio: return L10n.personalizationStepBio
        case .following: return L10n.personalizationStepFollowing
        }
    }

    var subtitle: String {
        switch self {
        case .photo: return L10n.profileCompletionStepPhoto
        case .tags: return L10n.profileCompletionStepTags
        case .sizing: return L10n.profileCompletionStepSizing
        case .bio: return L10n.profileCompletionStepBio
        case .following: return L10n.profileCompletionStepFollow
        }
    }

    var icon: String {
        switch self {
        case .photo: return "camera"
        case .tags: return "tag"
        case .sizing: return "ruler"
        case .bio: return "text.alignleft"
        case .following: return "person.2"
        }
    }
}

@Observable
@MainActor
final class PersonalizationViewModel {
    var profile: ProfileInfo?
    var isLoading = false
    var showPhotoPicker = false
    var isUploadingPhoto = false
    var photoError: String?

    var completionState: ProfileCompletionState {
        ProfileCompletionState.from(profile)
    }

    func reload(deps: AppDependencies) async {
        isLoading = true
        let result = await deps.userRepository.getMeProfile()
        isLoading = false
        if case .success(let p) = result {
            profile = p
        }
    }

    func handlePhotoSelection(_ item: PhotosPickerItem?, deps: AppDependencies) async {
        guard let item else { return }
        isUploadingPhoto = true
        photoError = nil
        guard let data = try? await item.loadTransferable(type: Data.self), !data.isEmpty else {
            isUploadingPhoto = false
            photoError = L10n.personalizationUploadError
            return
        }
        let mimeType = item.supportedContentTypes.first?.preferredMIMEType ?? "image/jpeg"
        let ext = mimeType.contains("png") ? "png" : "jpg"
        let uploadResult = await deps.userRepository.uploadProfileImage(
            bytes: data, filename: "avatar.\(ext)", type: "avatar", mimeType: mimeType
        )
        guard case .success(let url) = uploadResult else {
            isUploadingPhoto = false
            photoError = L10n.personalizationUploadError
            return
        }
        let patch = ProfilePatch(avatarUrl: url)
        _ = await deps.userRepository.updateProfile(patch)
        await reload(deps: deps)
        isUploadingPhoto = false
    }

    func isStepCompleted(_ step: PersonalizationStep) -> Bool {
        switch step {
        case .photo: return completionState.hasPhoto
        case .tags: return completionState.hasAestheticTags
        case .sizing: return completionState.hasSizing
        case .bio: return completionState.hasBio
        case .following: return completionState.hasFollowing
        }
    }
}
