import Observation
import PhotosUI
import SwiftUI
import UIKit

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
        // Use canonical profile from deps when available to avoid a redundant network call.
        if let cached = deps.canonicalUserProfile {
            profile = cached
            return
        }
        isLoading = true
        let result = await deps.userRepository.getMeProfile()
        isLoading = false
        if case .success(let p) = result {
            profile = p
            deps.canonicalUserProfile = p
        }
    }

    func handlePhotoSelection(_ item: PhotosPickerItem?, deps: AppDependencies) async {
        guard let item else { return }
        isUploadingPhoto = true
        photoError = nil
        guard let rawData = try? await item.loadTransferable(type: Data.self), !rawData.isEmpty else {
            isUploadingPhoto = false
            photoError = L10n.personalizationUploadError
            return
        }
        // Compress before upload — avoids sending multi-MB camera images.
        let data = compressImageData(rawData, maxDimension: 1200, jpegQuality: 0.82) ?? rawData
        let uploadResult = await deps.userRepository.uploadProfileImage(
            bytes: data, filename: "avatar.jpg", type: "avatar", mimeType: "image/jpeg"
        )
        guard case .success(let url) = uploadResult else {
            isUploadingPhoto = false
            photoError = L10n.personalizationUploadError
            return
        }
        // Optimistic local update — no full reload needed.
        let patch = ProfilePatch(avatarUrl: url)
        if let p = profile {
            let updated = ProfileInfo(
                userId: p.userId, username: p.username, displayName: p.displayName,
                avatarUrl: url, coverImageUrl: p.coverImageUrl,
                followerCount: p.followerCount, followingCount: p.followingCount,
                productCount: p.productCount, bio: p.bio, isFollowing: p.isFollowing,
                aestheticTags: p.aestheticTags, aestheticTagSnapshots: p.aestheticTagSnapshots,
                referenceSize: p.referenceSize, referenceMeasurementUnit: p.referenceMeasurementUnit,
                referenceMeasurementChest: p.referenceMeasurementChest,
                referenceMeasurementHem: p.referenceMeasurementHem,
                referenceMeasurementLength: p.referenceMeasurementLength,
                referenceMeasurementShoulders: p.referenceMeasurementShoulders,
                referenceMeasurementSleeveLength: p.referenceMeasurementSleeveLength,
                gender: p.gender, soldCount: p.soldCount, rating: p.rating,
                reviewCount: p.reviewCount, verified: p.verified,
                hasFastDelivery: p.hasFastDelivery, reputationPoints: p.reputationPoints,
                meetingNoShowWarning: p.meetingNoShowWarning,
                sizingReferenceCompleted: p.sizingReferenceCompleted,
                heightCm: p.heightCm, weightKg: p.weightKg,
                accountEmail: p.accountEmail, accountPhone: p.accountPhone,
                topBadges: p.topBadges
            )
            profile = updated
            deps.canonicalUserProfile = updated
        }
        // Persist to server; no full getMeProfile reload needed.
        Task { _ = await deps.userRepository.updateProfile(patch) }
        isUploadingPhoto = false
    }

    private func compressImageData(_ data: Data, maxDimension: CGFloat, jpegQuality: CGFloat) -> Data? {
        guard let image = UIImage(data: data) else { return nil }
        let size = image.size
        guard max(size.width, size.height) > maxDimension || data.count > 400_000 else { return data }
        let scale = min(maxDimension / max(size.width, size.height), 1.0)
        let newSize = CGSize(width: (size.width * scale).rounded(), height: (size.height * scale).rounded())
        let renderer = UIGraphicsImageRenderer(size: newSize)
        let resized = renderer.image { _ in image.draw(in: CGRect(origin: .zero, size: newSize)) }
        return resized.jpegData(compressionQuality: jpegQuality)
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
