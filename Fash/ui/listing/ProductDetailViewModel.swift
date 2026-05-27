import Foundation
import Observation

@Observable
@MainActor
final class ProductDetailViewModel {
    var item: ListingFeedItem?
    var isLoading = false
    var isOpeningChat = false
    var isLiked = false
    var isSaved = false
    var errorMessage: String?
    var galleryIndex = 0

    func load(listingId: String, deps: AppDependencies) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        let publicBrowse = deps.isGuestBrowseActive
        let result = await deps.listingRepository.getListingDetail(listingId: listingId, publicBrowse: publicBrowse)
        switch result {
        case .success(let detail):
            item = detail
            isLiked = detail.isLiked
            isSaved = detail.isSaved
            galleryIndex = 0
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }

    var imageUrls: [String] {
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
            errorMessage = error.localizedDescription
            return nil
        }
    }
}
