import Foundation

final class ListingRepository {
    private let client: SecuredApiClient

    init(client: SecuredApiClient) {
        self.client = client
    }

    func getHomeFeed(limit: Int = 20, offset: Int = 0) async -> Result<[ListingFeedItem], Error> {
        let path = "api/v1/listings/home?limit=\(limit)&offset=\(offset)"
        let urls = AppEnvironment.coreApiCandidateURLs(path)
        for urlString in urls {
            guard let url = URL(string: urlString) else { continue }
            var req = URLRequest(url: url)
            req.httpMethod = "GET"
            do {
                let (data, http) = try await client.data(for: req)
                guard (200..<300).contains(http.statusCode) else { continue }
                return .success(try ListingFeedJsonParser.parseFeed(data))
            } catch {
                continue
            }
        }
        return .failure(URLError(.cannotConnectToHost))
    }

    func getListingDetail(listingId: String, publicBrowse: Bool = false) async -> Result<ListingFeedItem, Error> {
        let urlString: String
        if publicBrowse {
            urlString = PublicBrowseHttp.publicApiPath("listings/\(listingId)")
        } else {
            urlString = AppEnvironment.apiPath("api/v1/listings/\(listingId)")
        }
        guard let url = URL(string: urlString) else { return .failure(URLError(.badURL)) }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        if publicBrowse {
            PublicBrowseHttp.applyGuestHeaders(&req)
        }
        do {
            let (data, http): (Data, HTTPURLResponse)
            if publicBrowse {
                let (d, r) = try await URLSession.shared.data(for: req)
                guard let h = r as? HTTPURLResponse else { throw URLError(.badServerResponse) }
                data = d; http = h
            } else {
                (data, http) = try await client.data(for: req)
            }
            guard (200..<300).contains(http.statusCode) else {
                throw CoreServiceHttpException(statusCode: http.statusCode, message: CoreServiceErrors.parseMessage(data: data, statusCode: http.statusCode))
            }
            let items = try ListingFeedJsonParser.parseFeed(data)
            if let first = items.first { return .success(first) }
            let obj = try HttpJson.dictionary(data)
            if let id = obj["id"] as? String {
                return .success(ListingFeedItem(
                    id: id,
                    title: obj["title"] as? String ?? "",
                    price: (obj["price"] as? NSNumber)?.int64Value ?? 0,
                    imageURL: nil,
                    sellerUsername: nil
                ))
            }
            return .failure(URLError(.cannotParseResponse))
        } catch {
            return .failure(error)
        }
    }

    func getListingPreviewDetail(listingId: String, publicBrowse: Bool = false) async -> Result<ListingPreviewDetail?, Error> {
        let urlString: String
        if publicBrowse {
            urlString = PublicBrowseHttp.publicApiPath("listings/\(listingId)")
        } else {
            urlString = AppEnvironment.apiPath("api/v1/listings/\(listingId)")
        }
        guard let url = URL(string: urlString) else { return .failure(URLError(.badURL)) }
        var req = URLRequest(url: url)
        req.httpMethod = "GET"
        if publicBrowse {
            PublicBrowseHttp.applyGuestHeaders(&req)
        }
        do {
            let (data, http): (Data, HTTPURLResponse)
            if publicBrowse {
                let (d, r) = try await URLSession.shared.data(for: req)
                guard let h = r as? HTTPURLResponse else { throw URLError(.badServerResponse) }
                data = d; http = h
            } else {
                (data, http) = try await client.data(for: req)
            }
            guard (200..<300).contains(http.statusCode) else {
                throw CoreServiceHttpException(statusCode: http.statusCode, message: CoreServiceErrors.parseMessage(data: data, statusCode: http.statusCode))
            }
            let obj = try HttpJson.dictionary(data)
            return .success(ListingPreviewDetail.parse(obj))
        } catch {
            return .failure(error)
        }
    }

    func getMyListings(limit: Int = 50, offset: Int = 0) async -> Result<[ListingFeedItem], Error> {
        do {
            let data = try await RepositoryHttp.executeCoreGet(
                relativePath: "api/v1/users/me/listings?limit=\(limit)&offset=\(offset)",
                client: client
            )
            return .success(try ListingFeedJsonParser.parseFeed(data))
        } catch {
            return .failure(error)
        }
    }

    func getWishlistListings(limit: Int = 50, offset: Int = 0) async -> Result<[ListingFeedItem], Error> {
        do {
            let data = try await RepositoryHttp.executeCoreGet(
                relativePath: "api/v1/listings/wishlist?limit=\(limit)&offset=\(offset)",
                client: client
            )
            return .success(try ListingFeedJsonParser.parseFeed(data))
        } catch {
            return .failure(error)
        }
    }

    func toggleLike(listingId: String) async -> Result<Bool, Error> {
        await toggleListingAction(listingId: listingId, path: "api/v1/listings/\(listingId)/like", likedKey: "liked")
    }

    func toggleSave(listingId: String, currentlySaved: Bool) async -> Result<Bool, Error> {
        if currentlySaved {
            return await toggleListingAction(listingId: listingId, path: "api/v1/listings/\(listingId)/save", likedKey: "saved", method: "DELETE")
        }
        return await toggleListingAction(listingId: listingId, path: "api/v1/listings/\(listingId)/save", likedKey: "saved", method: "POST")
    }

    private func toggleListingAction(
        listingId: String,
        path: String,
        likedKey: String,
        method: String = "POST"
    ) async -> Result<Bool, Error> {
        let encoded = listingId.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? listingId
        let urls = AppEnvironment.coreApiCandidateURLs(path.replacingOccurrences(of: listingId, with: encoded))
        var lastError: Error = URLError(.cannotConnectToHost)
        for urlString in urls {
            guard let url = URL(string: urlString) else { continue }
            var req = URLRequest(url: url)
            req.httpMethod = method
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            if method == "POST" { req.httpBody = Data("{}".utf8) }
            do {
                let (data, http) = try await client.data(for: req)
                guard (200..<300).contains(http.statusCode) else { continue }
                let obj = try RepositoryHttp.jsonObject(data)
                let payload = (obj["data"] as? [String: Any]) ?? obj
                let flag = RepositoryHttp.optBool(payload, likedKey, "is_\(likedKey)", default: true)
                return .success(flag)
            } catch {
                lastError = error
            }
        }
        return .failure(lastError)
    }

    func uploadListingImage(bytes: Data, filename: String = "image.jpg", mimeType: String = "image/jpeg") async -> Result<String, Error> {
        guard let url = URL(string: AppEnvironment.apiPath("api/v1/listings/images")) else {
            return .failure(URLError(.badURL))
        }
        let boundary = "Boundary-\(UUID().uuidString)"
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        let safeMime = mimeType.contains("/") && !mimeType.contains("*") ? mimeType : "image/jpeg"
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(safeMime)\r\n\r\n".data(using: .utf8)!)
        body.append(bytes)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        req.httpBody = body
        do {
            let (data, http) = try await client.data(for: req)
            guard (200..<300).contains(http.statusCode) else {
                throw CoreServiceHttpException(
                    statusCode: http.statusCode,
                    message: CoreServiceErrors.parseMessage(data: data, statusCode: http.statusCode)
                )
            }
            let obj = try RepositoryHttp.jsonObject(data)
            let imageUrl = RepositoryHttp.optString(obj, "image_url", "imageUrl", "ImageURL")
            guard !imageUrl.isEmpty else { return .failure(URLError(.cannotParseResponse)) }
            return .success(imageUrl)
        } catch {
            return .failure(error)
        }
    }

    func createListing(_ request: CreateListingRequest) async -> Result<CreateListingResponse, Error> {
        guard let url = URL(string: AppEnvironment.apiPath("api/v1/listings")) else {
            return .failure(URLError(.badURL))
        }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        do {
            req.httpBody = try JSONSerialization.data(withJSONObject: buildCreateListingJSON(request))
            let (data, http) = try await client.data(for: req)
            guard (200..<300).contains(http.statusCode) else {
                throw CoreServiceHttpException(
                    statusCode: http.statusCode,
                    message: CoreServiceErrors.parseMessage(data: data, statusCode: http.statusCode)
                )
            }
            let obj = try RepositoryHttp.jsonObject(data)
            let dataObj = (obj["data"] as? [String: Any]) ?? obj
            let id = RepositoryHttp.optString(dataObj, "ID", "id")
            guard !id.isEmpty else { return .failure(URLError(.cannotParseResponse)) }
            return .success(CreateListingResponse(id: id))
        } catch {
            return .failure(error)
        }
    }

    private func buildCreateListingJSON(_ request: CreateListingRequest) -> [String: Any] {
        var json: [String: Any] = [
            "title": request.title,
            "image_urls": listingImageStepsToJSONArray(request.imageUrlSteps),
            "price": request.priceVnd,
            "condition": request.condition,
            "category": namedRefJSON(request.category, maxNameLen: 100),
        ]
        if let parent = request.parentCategory { json["parent_category"] = namedRefJSON(parent, maxNameLen: 100) }
        if !request.description.isEmpty { json["description"] = request.description }
        if !request.size.isEmpty { json["size"] = request.size }
        if let color = request.color?.trimmingCharacters(in: .whitespaces), !color.isEmpty {
            json["color"] = color.lowercased()
        }
        if let gender = request.genderTarget?.trimmingCharacters(in: .whitespaces), !gender.isEmpty {
            json["gender_target"] = gender.lowercased()
        }
        if let brand = request.brand { json["brand"] = namedRefJSON(brand, maxNameLen: 255) }
        if !request.aestheticTags.isEmpty {
            json["aesthetic_tags"] = request.aestheticTags.map { namedRefJSON($0, maxNameLen: 100) }
        }
        if let iso = request.countryOfOrigin?.trimmingCharacters(in: .whitespaces), !iso.isEmpty {
            json["country_of_origin"] = iso
        }
        if let cid = request.countryId?.trimmingCharacters(in: .whitespaces), !cid.isEmpty { json["country_id"] = cid }
        if let cname = request.countryName?.trimmingCharacters(in: .whitespaces), !cname.isEmpty { json["country_name"] = cname }
        if let unit = request.measurementUnit?.trimmingCharacters(in: .whitespaces), !unit.isEmpty { json["measurement_unit"] = unit }
        if let v = request.measurementHem { json["measurement_hem"] = v }
        if let v = request.measurementChest { json["measurement_chest"] = v }
        if let v = request.measurementLength { json["measurement_length"] = v }
        if let v = request.measurementShoulders { json["measurement_shoulders"] = v }
        if let v = request.measurementSleeveLength { json["measurement_sleeve_length"] = v }
        if let v = request.acceptOffers { json["accept_offers"] = v }
        if let v = request.autoPriceDropEnabled { json["auto_price_drop_enabled"] = v }
        if let v = request.floorPriceVnd { json["floor_price"] = v }
        if let v = request.priceDropPercent { json["price_drop_percent"] = v }
        if let sid = request.shippingAddressId?.trimmingCharacters(in: .whitespaces), !sid.isEmpty {
            json["shipping_address_id"] = sid
        }
        if let v = request.onsiteInspectionCommitment { json["onsite_inspection_commitment"] = v }
        if let score = request.conditionScore { json["condition_score"] = min(max(score, 80), 99) }
        if !request.conditionDefects.isEmpty { json["condition_defects"] = request.conditionDefects }
        return json
    }

    private func namedRefJSON(_ ref: NamedRefPayload, maxNameLen: Int) -> [String: Any] {
        [
            "id": ref.id.trimmingCharacters(in: .whitespaces),
            "name": String(ref.name.trimmingCharacters(in: .whitespaces).prefix(maxNameLen)),
        ]
    }

    private func listingImageStepsToJSONArray(_ steps: [ListingImageStepPayload]) -> [[String: Any]] {
        steps.map { s in
            var o: [String: Any] = [
                "step_key": s.stepKey.trimmingCharacters(in: .whitespaces),
                "label": s.label.trimmingCharacters(in: .whitespaces),
                "sort_order": s.sortOrder,
                "required": s.required,
                "image_url": s.imageUrl.trimmingCharacters(in: .whitespaces),
            ]
            if let vi = s.labelVi?.trimmingCharacters(in: .whitespaces), !vi.isEmpty { o["label_vi"] = vi }
            return o
        }
    }
}
