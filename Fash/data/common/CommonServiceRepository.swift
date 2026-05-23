import Foundation

final class CommonServiceRepository {
    private let client: SecuredApiClient
    private let publicCatalog: PublicCommonCatalogRepository

    init(client: SecuredApiClient, publicCatalog: PublicCommonCatalogRepository) {
        self.client = client
        self.publicCatalog = publicCatalog
    }
}
