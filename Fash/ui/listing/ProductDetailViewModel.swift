import Foundation
import Observation

@Observable
@MainActor
final class ProductDetailViewModel {
    var item: ListingFeedItem?
    var isLoading = false
    var errorMessage: String?

    func load(listingId: String, deps: AppDependencies) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        let publicBrowse = deps.isGuestBrowseActive
        let result = await deps.listingRepository.getListingDetail(listingId: listingId, publicBrowse: publicBrowse)
        switch result {
        case .success(let detail):
            item = detail
        case .failure(let error):
            errorMessage = error.localizedDescription
        }
    }
}
