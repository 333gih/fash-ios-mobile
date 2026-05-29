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

    /// Encodes query the same way as the admin portal BFF / Android [apiV1UrlWithQuery].
    private func apiV1UrlWithQuery(_ pathAfterApiV1: String, queryParams: [(String, String)]) -> String {
        guard var components = URLComponents(string: apiV1(pathAfterApiV1)) else {
            return apiV1(pathAfterApiV1)
        }
        if !queryParams.isEmpty {
            components.queryItems = queryParams.map { URLQueryItem(name: $0.0, value: $0.1) }
        }
        return components.url?.absoluteString ?? apiV1(pathAfterApiV1)
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

    // MARK: - Addresses

    private func getAddressTree() async -> Result<[AddressTreeNodeInternal], Error> {
        do {
            let data = try await executeGet(apiV1("addresses/tree"))
            let obj = try RepositoryHttp.jsonObject(data)
            let tree = (obj["tree"] as? [[String: Any]] ?? []).map(parseAddressTreeNode)
            return .success(tree)
        } catch {
            return .failure(error)
        }
    }

    func getAddresses(level: Int? = nil, parentId: String? = nil, current: Bool = true) async -> Result<[CommonAddressDto], Error> {
        var params: [(String, String)] = [("current", current ? "true" : "false")]
        if let level { params.append(("level", String(level))) }
        if let pid = parentId?.trimmingCharacters(in: .whitespaces), !pid.isEmpty {
            params.append(("parent_id", pid))
        }
        do {
            let data = try await executeGet(apiV1UrlWithQuery("addresses", queryParams: params))
            let obj = try RepositoryHttp.jsonObject(data)
            return .success(parseAddressList(obj))
        } catch {
            return .failure(error)
        }
    }

    /// Level-1 provinces: list API first, then tree fallback (Android `getProvincesCatalog`).
    func getProvincesCatalog() async -> Result<[CommonAddressDto], Error> {
        let listAttempt = await getAddresses(level: 1, current: true)
        if case .success(let list) = listAttempt, !list.isEmpty {
            return .success(list)
        }
        switch await getAddressTree() {
        case .success(let tree):
            return .success(flattenAddressesAtLevel(tree, targetLevel: 1))
        case .failure(let treeErr):
            if case .failure(let listErr) = listAttempt { return .failure(listErr) }
            return .failure(treeErr)
        }
    }

    /// Direct children at level 2 (district) or 3 (ward) — Android `getAdministrativeChildren`.
    func getAdministrativeChildren(parentId: String, childLevel: Int) async -> Result<[CommonAddressDto], Error> {
        let pid = parentId.trimmingCharacters(in: .whitespaces)
        guard !pid.isEmpty, (2...3).contains(childLevel) else { return .success([]) }

        let listTry = await getAddresses(level: childLevel, parentId: pid, current: true)
        if case .success(let list) = listTry, !list.isEmpty {
            return .success(list)
        }

        let treeResult = await getAddressTree()
        let fromTree: [CommonAddressDto]
        switch treeResult {
        case .success(let tree):
            let node = findTreeNodeById(tree, id: pid)
            fromTree = (node?.children ?? [])
                .filter { $0.level == childLevel }
                .map { n in
                    CommonAddressDto(id: n.id, name: n.name, code: n.code, parentId: n.parentId, level: n.level, status: "")
                }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
        case .failure:
            fromTree = []
        }

        let looseList: [CommonAddressDto]?
        switch await getAddresses(level: nil, parentId: pid, current: true) {
        case .success(let loose):
            let filtered = loose.filter { $0.level == childLevel }
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
            looseList = filtered.isEmpty ? nil : filtered
        case .failure:
            looseList = nil
        }

        if !fromTree.isEmpty { return .success(fromTree) }
        if let looseList { return .success(looseList) }
        if case .success(let empty) = listTry { return .success(empty) }
        if case .failure(let listErr) = listTry {
            if case .failure(let treeErr) = treeResult { return .failure(listErr) }
            return .failure(listErr)
        }
        if case .failure(let treeErr) = treeResult { return .failure(treeErr) }
        return .success([])
    }

    // MARK: - Public catalog delegates

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

// MARK: - Address parsing

private struct AddressTreeNodeInternal {
    var id: String
    var name: String
    var code: String
    var parentId: String
    var level: Int
    var children: [AddressTreeNodeInternal]
}

/// Matches Android `parseAddressList` — API returns `items`, not `addresses`.
private func parseAddressList(_ obj: [String: Any]) -> [CommonAddressDto] {
    let rows = obj["items"] as? [[String: Any]]
        ?? obj["addresses"] as? [[String: Any]]
        ?? []
    return rows.map(parseAddressDto)
}

private func parseAddressDto(_ o: [String: Any]) -> CommonAddressDto {
    CommonAddressDto(
        id: RepositoryHttp.optString(o, "id", "ID"),
        name: RepositoryHttp.optString(o, "name", "Name"),
        code: RepositoryHttp.optString(o, "code", "Code"),
        parentId: RepositoryHttp.optString(o, "parent_id", "parentId", "ParentID"),
        level: RepositoryHttp.optInt(o, "level", "Level", default: 1),
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
        level: RepositoryHttp.optInt(o, "level", "Level", default: 1),
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
    guard !target.isEmpty else { return nil }
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
