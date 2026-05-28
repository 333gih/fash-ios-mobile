import Foundation
import Observation

@Observable
@MainActor
final class ProductDetailViewModel {
    var item: ListingFeedItem?
    var preview: ListingPreviewDetail?
    var isLoading = false
    var isOpeningChat = false
    var isLiked = false
    var isSaved = false
    var errorMessage: String?
    var galleryIndex = 0

    var resolvedImageUrls: [String] {
        if let preview, !preview.imageURLs.isEmpty {
            return preview.imageURLs.compactMap { FeedImageUrl.resolveListingImageUrlOrNil($0) }
        }
        return imageUrls.compactMap { FeedImageUrl.resolveListingImageUrlOrNil($0) }
    }

    var sellerDisplayName: String {
        if let name = preview?.sellerDisplayName?.trimmingCharacters(in: .whitespaces), !name.isEmpty {
            return name
        }
        if let u = item?.sellerUsername, !u.isEmpty { return "@\(u)" }
        return L10n.navProfile
    }

    var sellerAvatarUrl: String? {
        let raw = preview?.sellerAvatarURL ?? ""
        return raw.isEmpty ? nil : FeedImageUrl.resolveListingImageUrlOrNil(raw)
    }

    var isSold: Bool {
        let status = (preview?.status ?? item?.listingStatus ?? "").lowercased()
        return status == "sold"
    }

    func load(listingId: String, deps: AppDependencies) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        let publicBrowse = deps.isGuestBrowseActive
        async let detailResult = deps.listingRepository.getListingDetail(listingId: listingId, publicBrowse: publicBrowse)
        async let previewResult = deps.listingRepository.getListingPreviewDetail(listingId: listingId, publicBrowse: publicBrowse)
        switch await detailResult {
        case .success(let detail):
            item = detail
            isLiked = detail.isLiked
            isSaved = detail.isSaved
            galleryIndex = 0
        case .failure(let error):
            errorMessage = FashErrorPresentation.userMessage(for: error)
        }
        if case .success(let p) = await previewResult {
            preview = p
            if let p {
                isLiked = p.isLiked
                isSaved = p.isSaved
            }
        }
    }

    var imageUrls: [String] {
        if let preview, !preview.imageURLs.isEmpty { return preview.imageURLs }
        guard let item else { return [] }
        if !item.imageUrls.isEmpty { return item.imageUrls }
        if !item.coverImageUrl.isEmpty { return [item.coverImageUrl] }
        return []
    }

    func toggleLike(deps: AppDependencies) async {
        guard let item else { return }
        guard case .success(let liked) = await deps.listingRepository.toggleLike(listingId: item.id) else { return }
        isLiked = liked
    }

    func toggleSave(deps: AppDependencies) async {
        guard let item else { return }
        guard case .success(let saved) = await deps.listingRepository.toggleSave(listingId: item.id, currentlySaved: isSaved) else { return }
        isSaved = saved
    }

    func openChat(deps: AppDependencies) async -> String? {
        guard let item else { return nil }
        isOpeningChat = true
        defer { isOpeningChat = false }
        switch await deps.chatRepository.startConversation(listingId: item.id) {
        case .success(let convId):
            return convId
        case .failure(let error):
            errorMessage = FashErrorPresentation.userMessage(for: error)
            return nil
        }
    }
}

private extension String {
    func ifEmpty(_ fallback: String) -> String {
        trimmingCharacters(in: .whitespaces).isEmpty ? fallback : self
    }
}
