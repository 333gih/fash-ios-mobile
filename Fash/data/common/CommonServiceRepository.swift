import Foundation

/// Common-service catalog — Android `CommonServiceRepository` (subset used by post/address/explore).
final class CommonServiceRepository {
    private let client: SecuredApiClient
    private let publicCatalog: PublicCommonCatalogRepository

    init(client: SecuredApiClient, publicCatalog: PublicCommonCatalogRepository) {
        self.client = client
        self.publicCatalog = publicCatalog
    }

    private func apiV1(_ path: String) -> String {
        AppEnvironment.commonServicePath("api/v1/\(path.trimmingCharacters(in: CharacterSet(charactersIn: "/")))")
    }

    private func executeGet(_ urlString: String) async throws -> Data {
        guard let url = URL(string: urlString) else { throw URLError(.badURL) }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        let (data, http) = try await client.data(for: req)
        guard (200..<300).contains(http.statusCode) else {
            throw CoreServiceHttpException(statusCode: http.statusCode, message: CoreServiceErrors.parseMessage(data: data, statusCode: http.statusCode))
        }
        return data
    }

    func getProvincesCatalog() async -> Result<[CommonAddressDto], Error> {
        do {
            let listURL = apiV1("addresses?level=1&current=true")
            let data = try await executeGet(listURL)
            let obj = try RepositoryHttp.jsonObject(data)
            let rows = obj["addresses"] as? [[String: Any]] ?? RepositoryHttp.jsonArray(data)
            let list = rows.map(parseAddressDto)
            if !list.isEmpty { return .success(list) }
            let treeData = try await executeGet(apiV1("addresses/tree"))
            let treeObj = try RepositoryHttp.jsonObject(treeData)
            let tree = (treeObj["tree"] as? [[String: Any]] ?? []).map(parseAddressTreeNode)
            return .success(flattenAddressesAtLevel(tree, targetLevel: 1))
        } catch {
            return .failure(error)
        }
    }

    func getAdministrativeChildren(parentId: String, childLevel: Int) async -> Result<[CommonAddressDto], Error> {
        let pid = parentId.trimmingCharacters(in: .whitespaces)
        guard !pid.isEmpty, (2...3).contains(childLevel) else { return .success([]) }
        do {
            let listURL = apiV1("addresses?level=\(childLevel)&parent_id=\(pid)&current=true")
            let data = try await executeGet(listURL)
            let obj = try RepositoryHttp.jsonObject(data)
            let rows = obj["addresses"] as? [[String: Any]] ?? RepositoryHttp.jsonArray(data)
            let list = rows.map(parseAddressDto)
            if !list.isEmpty { return .success(list) }
            let treeData = try await executeGet(apiV1("addresses/tree"))
            let treeObj = try RepositoryHttp.jsonObject(treeData)
            let tree = (treeObj["tree"] as? [[String: Any]] ?? []).map(parseAddressTreeNode)
            if let parent = findTreeNodeById(tree, id: pid) {
                return .success(parent.children.filter { $0.level == childLevel }.map { n in
                    CommonAddressDto(id: n.id, name: n.name, code: n.code, parentId: n.parentId, level: n.level, status: "")
                })
            }
            return .success([])
        } catch {
            return .failure(error)
        }
    }

    func getCategoryTree() async -> Result<[CategoryTreeNode], Error> {
        await publicCatalog.getCategoryTree()
    }

    func getBrands(q: String? = nil, limit: Int = 20, offset: Int = 0) async -> Result<BrandsPage, Error> {
        await publicCatalog.getBrands(q: q, offset: offset, limit: limit)
    }

    func getAestheticTags(all: Bool = false) async -> Result<[CommonAestheticTagDto], Error> {
        await publicCatalog.getAestheticTags(all: all)
    }

    func getCountries(all: Bool = false) async -> Result<[CommonCountryDto], Error> {
        await publicCatalog.getCountries(all: all)
    }

    func getListingImageSetup(categoryId: String) async -> Result<ListingImageSetupDto, Error> {
        let cat = categoryId.trimmingCharacters(in: .whitespaces)
        guard !cat.isEmpty else { return .failure(URLError(.badURL)) }
        do {
            let data = try await executeGet(apiV1("categories/\(cat)/listing-image-setup"))
            let obj = try RepositoryHttp.jsonObject(data)
            let setup = obj["listing_image_setup"] as? [String: Any] ?? obj
            let templates = setup["listing_image_setups"] as? [[String: Any]]
                ?? setup["templates"] as? [[String: Any]] ?? []
            var steps: [ListingImageStepCatalog] = []
            for template in templates {
                let stepRows = template["steps"] as? [[String: Any]] ?? []
                if stepRows.isEmpty { continue }
                steps = stepRows.map(parseListingImageCatalogStep).sorted { $0.sortOrder < $1.sortOrder }
                break
            }
            if steps.isEmpty { steps = defaultListingImageCatalogSteps() }
            return .success(ListingImageSetupDto(categoryId: cat, steps: Array(steps.prefix(20))))
        } catch {
            return .failure(error)
        }
    }
}

private struct AddressTreeNodeInternal {
    var id: String
    var name: String
    var code: String
    var parentId: String
    var level: Int
    var children: [AddressTreeNodeInternal]
}

private func parseAddressDto(_ o: [String: Any]) -> CommonAddressDto {
    CommonAddressDto(
        id: RepositoryHttp.optString(o, "id", "ID"),
        name: RepositoryHttp.optString(o, "name", "Name"),
        code: RepositoryHttp.optString(o, "code", "Code"),
        parentId: RepositoryHttp.optString(o, "parent_id", "parentId", "ParentID"),
        level: RepositoryHttp.optInt(o, "level", "Level"),
        status: RepositoryHttp.optString(o, "status", "Status")
    )
}

private func parseAddressTreeNode(_ o: [String: Any]) -> AddressTreeNodeInternal {
    let children = (o["children"] as? [[String: Any]] ?? []).map(parseAddressTreeNode)
    return AddressTreeNodeInternal(
        id: RepositoryHttp.optString(o, "id", "ID"),
        name: RepositoryHttp.optString(o, "name", "Name"),
        code: RepositoryHttp.optString(o, "code", "Code"),
        parentId: RepositoryHttp.optString(o, "parent_id", "parentId", "ParentID"),
        level: RepositoryHttp.optInt(o, "level", "Level"),
        children: children
    )
}

private func flattenAddressesAtLevel(_ nodes: [AddressTreeNodeInternal], targetLevel: Int) -> [CommonAddressDto] {
    var out: [CommonAddressDto] = []
    func walk(_ list: [AddressTreeNodeInternal]) {
        for n in list {
            if n.level == targetLevel {
                out.append(CommonAddressDto(id: n.id, name: n.name, code: n.code, parentId: n.parentId, level: n.level, status: ""))
            }
            if !n.children.isEmpty { walk(n.children) }
        }
    }
    walk(nodes)
    return out.sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
}

private func findTreeNodeById(_ nodes: [AddressTreeNodeInternal], id: String) -> AddressTreeNodeInternal? {
    let target = id.trimmingCharacters(in: .whitespaces)
    for n in nodes {
        if n.id.caseInsensitiveCompare(target) == .orderedSame { return n }
        if let found = findTreeNodeById(n.children, id: target) { return found }
    }
    return nil
}

private func parseListingImageCatalogStep(_ s: [String: Any]) -> ListingImageStepCatalog {
    ListingImageStepCatalog(
        stepKey: RepositoryHttp.optString(s, "step_key", "stepKey"),
        label: RepositoryHttp.optString(s, "label", "Label"),
        labelVi: RepositoryHttp.optString(s, "label_vi", "labelVi"),
        sortOrder: RepositoryHttp.optInt(s, "sort_order", "sortOrder"),
        required: RepositoryHttp.optBool(s, "required", "Required", default: true)
    )
}
