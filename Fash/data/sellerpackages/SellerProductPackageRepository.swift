import Foundation

final class SellerProductPackageRepository {
    private let client: SecuredApiClient

    init(client: SecuredApiClient) {
        self.client = client
    }

    func listPackages(activeOnly: Bool = true) async -> Result<SellerProductPackagesResponse, Error> {
        let qs = activeOnly ? "active_only=true" : "active_only=false"
        let relative = "api/v1/app/advertising/product-packages?\(qs)"
        var lastError: Error = URLError(.cannotConnectToHost)
        for urlString in AppEnvironment.coreApiCandidateURLs(relative) {
            do {
                let data = try await RepositoryHttp.executeGet(urlString: urlString, client: client)
                let parsed = try SellerProductPackagesApiModels.parseResponse(data)
                let visible = activeOnly ? parsed.packages.filter(\.active) : parsed.packages
                return .success(SellerProductPackagesResponse(packages: visible, serverNowUtc: parsed.serverNowUtc))
            } catch {
                lastError = error
            }
        }
        return .failure(lastError)
    }

    func getPackage(code: String) async -> Result<SellerProductPackage, Error> {
        let trimmed = code.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return .failure(URLError(.badURL)) }
        do {
            let list = try await listPackages(activeOnly: false).get()
            if let found = list.packages.first(where: { $0.code.caseInsensitiveCompare(trimmed) == .orderedSame }) {
                return .success(found)
            }
            return .failure(URLError(.fileDoesNotExist))
        } catch {
            return .failure(error)
        }
    }
}
