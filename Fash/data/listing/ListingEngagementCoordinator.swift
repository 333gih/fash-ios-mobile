import Foundation

/// Prevents overlapping like/save API calls for the same listing (rapid taps).
@MainActor
final class ListingEngagementCoordinator {
    private var saveInFlight = Set<String>()
    private var likeInFlight = Set<String>()

    func beginSaveToggle(listingId: String) -> Bool {
        saveInFlight.insert(listingId).inserted
    }

    func endSaveToggle(listingId: String) {
        saveInFlight.remove(listingId)
    }

    func beginLikeToggle(listingId: String) -> Bool {
        likeInFlight.insert(listingId).inserted
    }

    func endLikeToggle(listingId: String) {
        likeInFlight.remove(listingId)
    }

    func toggleSave(
        listingId: String,
        currentlySaved: Bool,
        repository: ListingRepository
    ) async -> Result<Bool, Error> {
        guard beginSaveToggle(listingId: listingId) else {
            return .failure(ListingEngagementCoordinatorError.alreadyInFlight)
        }
        defer { endSaveToggle(listingId: listingId) }
        return await repository.toggleSave(listingId: listingId, currentlySaved: currentlySaved)
    }

    func toggleLike(
        listingId: String,
        repository: ListingRepository
    ) async -> Result<Bool, Error> {
        guard beginLikeToggle(listingId: listingId) else {
            return .failure(ListingEngagementCoordinatorError.alreadyInFlight)
        }
        defer { endLikeToggle(listingId: listingId) }
        return await repository.toggleLike(listingId: listingId)
    }
}

enum ListingEngagementCoordinatorError: Error {
    case alreadyInFlight
}
