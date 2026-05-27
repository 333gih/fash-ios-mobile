import Foundation
import Observation

private let loginSliderPlacement = "login_slider"

/// Loads login-screen hero slides from CMS (pre-auth public browse).
@Observable
@MainActor
final class LoginHeroSlidesViewModel {
    private let repository: AdvertisingRepository

    var remoteSlides: [AppAdvertisingSlideItem] = []
    var isLoading = false

    init(repository: AdvertisingRepository) {
        self.repository = repository
    }

    convenience init() {
        self.init(repository: AppDependencies.shared.advertisingRepository)
    }

    func refresh() async {
        isLoading = true
        defer { isLoading = false }
        let result = await repository.getSlides(placement: loginSliderPlacement, publicBrowse: true)
        switch result {
        case .success(let res):
            remoteSlides = res.items
        case .failure:
            remoteSlides = []
        }
    }
}
