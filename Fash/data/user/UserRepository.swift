import Foundation

struct SetupStatusGate: Decodable {
    var canAccessHome: Bool
    var nextStep: String?

    enum CodingKeys: String, CodingKey {
        case canAccessHome = "can_access_home"
        case nextStep = "next_step"
    }
}

final class UserRepository {
    let client: SecuredApiClient

    init(client: SecuredApiClient) {
        self.client = client
    }

    func fetchSetupStatus() async -> Result<SetupStatusGate, Error> {
        let urls = AppEnvironment.coreApiCandidateURLs(AppEnvironment.userAccessStatusPath)
        for urlString in urls {
            guard let url = URL(string: urlString) else { continue }
            var req = URLRequest(url: url)
            req.httpMethod = "GET"
            do {
                let (data, http) = try await client.data(for: req)
                guard (200..<300).contains(http.statusCode) else { continue }
                let gate = try JSONDecoder().decode(SetupStatusGate.self, from: data)
                return .success(gate)
            } catch {
                continue
            }
        }
        return .failure(URLError(.cannotConnectToHost))
    }

    /// `PUT /users/me/locale` — syncs push/in-app notification language (`en` or `vi`).
    func syncPreferredLocale(_ locale: String) async -> Result<Void, Error> {
        let tag = locale.lowercased().hasPrefix(AppLocale.tagEN) ? AppLocale.tagEN : AppLocale.tagVI
        let urls = AppEnvironment.coreApiCandidateURLs("api/v1/users/me/locale")
        for urlString in urls {
            guard let url = URL(string: urlString) else { continue }
            var req = URLRequest(url: url)
            req.httpMethod = "PUT"
            req.setValue("application/json", forHTTPHeaderField: "Content-Type")
            do {
                req.httpBody = try JSONSerialization.data(withJSONObject: ["locale": tag])
                let (_, http) = try await client.data(for: req)
                if (200..<300).contains(http.statusCode) {
                    return .success(())
                }
            } catch {
                continue
            }
        }
        return .failure(URLError(.cannotConnectToHost))
    }

    func updateProfile(_ patch: ProfilePatch) async -> Result<Void, Error> {
        var json: [String: Any] = [:]
        if let v = patch.displayName { json["display_name"] = v }
        if let v = patch.username { json["username"] = v }
        if let v = patch.bio { json["bio"] = v }
        if let v = patch.avatarUrl { json["avatar_url"] = v }
        if let v = patch.coverImageUrl {
            json["cover_image_url"] = v
            json["cover_url"] = v
        }
        if let tags = patch.aestheticTags {
            json["aesthetic_tags"] = tags.map { ["id": $0.id, "name": $0.name] }
        }
        if let v = patch.gender { json["gender"] = v }
        if let v = patch.referenceSize { json["reference_size"] = v }
        if let v = patch.referenceMeasurementUnit {
            json["reference_measurement_unit"] = v.trimmingCharacters(in: .whitespaces).lowercased()
        }
        if let v = patch.referenceMeasurementChest { json["reference_measurement_chest"] = v }
        if let v = patch.referenceMeasurementHem { json["reference_measurement_hem"] = v }
        if let v = patch.referenceMeasurementLength { json["reference_measurement_length"] = v }
        if let v = patch.referenceMeasurementShoulders { json["reference_measurement_shoulders"] = v }
        if let v = patch.referenceMeasurementSleeveLength { json["reference_measurement_sleeve_length"] = v }
        guard !json.isEmpty else { return .success(()) }
        guard let body = try? JSONSerialization.data(withJSONObject: json) else {
            return .failure(URLError(.cannotParseResponse))
        }
        let urlString = AppEnvironment.apiPath("api/v1/users/me")
        guard let url = URL(string: urlString) else { return .failure(URLError(.badURL)) }
        var req = URLRequest(url: url)
        req.httpMethod = "PATCH"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = body
        do {
            let (data, http) = try await client.data(for: req)
            guard (200..<300).contains(http.statusCode) else {
                throw CoreServiceHttpException(
                    statusCode: http.statusCode,
                    message: CoreServiceErrors.parseMessage(data: data, statusCode: http.statusCode)
                )
            }
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    func ackMeetingIdentityReverify() async -> Result<Void, Error> {
        do {
            _ = try await RepositoryHttp.executeCorePost(
                relativePath: "api/v1/users/me/meeting-trust/ack-identity-reverify",
                client: client,
                body: Data("{}".utf8)
            )
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    func getMeProfile() async -> Result<ProfileInfo, Error> {
        async let authMe = fetchAuthMeData()
        do {
            let data = try await RepositoryHttp.executeCoreGet(relativePath: "api/v1/users/me", client: client)
            let profile = try parseProfileInfo(data)
            return .success(mergeAuthMeIntoProfile(profile, authData: await authMe))
        } catch {
            do {
                let data = try await RepositoryHttp.executeCoreGet(relativePath: "v1/users/me", client: client)
                let profile = try parseProfileInfo(data)
                return .success(mergeAuthMeIntoProfile(profile, authData: await authMe))
            } catch {
                return .failure(error)
            }
        }
    }

    private func parseProfileInfo(_ data: Data) throws -> ProfileInfo {
        let root = try RepositoryHttp.jsonObject(data)
        let obj = (root["data"] as? [String: Any]) ?? root
        let following = (obj["is_following"] as? Bool)
            ?? (obj["isFollowing"] as? Bool)
            ?? false
        let (aestheticTags, aestheticTagSnapshots) = parseAestheticTagsField(obj)
        let ratingCandidates: [Double] = [
            obj["rating"] as? Double,
            obj["Rating"] as? Double,
            obj["average_rating"] as? Double,
        ].compactMap { $0 }.filter { $0 >= 0 }
        let rating = ratingCandidates.first.map { Float($0) }
        let reviewCount = RepositoryHttp.optInt(obj, "review_count", "ReviewCount")
        let reviewCountOpt = reviewCount >= 0 ? reviewCount : nil
        let heightRaw = RepositoryHttp.optInt(obj, "height_cm", "heightCm")
        let heightCm = (100...250).contains(heightRaw) ? heightRaw : nil
        return ProfileInfo(
            userId: RepositoryHttp.optString(obj, "user_id", "UserID", "id", "ID"),
            username: RepositoryHttp.optString(obj, "username", "Username"),
            displayName: RepositoryHttp.optString(obj, "display_name", "DisplayName", "name", "Name"),
            avatarUrl: RepositoryHttp.optString(obj, "avatar_url", "AvatarURL"),
            coverImageUrl: RepositoryHttp.optString(obj, "cover_image_url", "CoverImageURL"),
            followerCount: RepositoryHttp.optInt(obj, "follower_count", "FollowerCount"),
            followingCount: RepositoryHttp.optInt(obj, "following_count", "FollowingCount"),
            productCount: RepositoryHttp.optInt(obj, "product_count", "ProductCount", "listing_count", "ListingCount"),
            bio: RepositoryHttp.optString(obj, "bio", "Bio"),
            isFollowing: following,
            aestheticTags: aestheticTags,
            aestheticTagSnapshots: aestheticTagSnapshots,
            referenceSize: optionalNonEmpty(RepositoryHttp.optString(obj, "reference_size", "referenceSize")),
            referenceMeasurementUnit: optionalNonEmpty(
                RepositoryHttp.optString(obj, "reference_measurement_unit", "referenceMeasurementUnit")
            ),
            referenceMeasurementChest: optDoubleIfPresent(obj, "reference_measurement_chest"),
            referenceMeasurementHem: optDoubleIfPresent(obj, "reference_measurement_hem"),
            referenceMeasurementLength: optDoubleIfPresent(obj, "reference_measurement_length"),
            referenceMeasurementShoulders: optDoubleIfPresent(obj, "reference_measurement_shoulders"),
            referenceMeasurementSleeveLength: optDoubleIfPresent(obj, "reference_measurement_sleeve_length"),
            gender: RepositoryHttp.optString(obj, "gender", "Gender").trimmingCharacters(in: .whitespaces).lowercased(),
            soldCount: RepositoryHttp.optInt(obj, "sold_count", "SoldCount"),
            rating: rating,
            reviewCount: reviewCountOpt,
            verified: (obj["verified"] as? Bool) ?? (obj["Verified"] as? Bool) ?? false,
            hasFastDelivery: (obj["has_fast_delivery"] as? Bool) ?? (obj["hasFastDelivery"] as? Bool) ?? false,
            reputationPoints: optIntIfPresent(obj, "reputation_points", "ReputationPoints", "reputationPoints"),
            meetingNoShowWarning: (obj["meeting_no_show_warning"] as? Bool)
                ?? (obj["MeetingNoShowWarning"] as? Bool) ?? false,
            sizingReferenceCompleted: (obj["sizing_reference_completed"] as? Bool)
                ?? (obj["SizingReferenceCompleted"] as? Bool) ?? false,
            heightCm: heightCm,
            weightKg: optDoubleIfPresent(obj, "weight_kg"),
            accountEmail: RepositoryHttp.optString(obj, "account_email", "accountEmail"),
            accountPhone: RepositoryHttp.optString(obj, "account_phone", "accountPhone"),
            topBadges: parseTopBadges(obj["top_badges"] ?? obj["TopBadges"])
        )
    }

    func getSellerListingFocus(_ userIdOrUsername: String) async -> Result<SellerListingFocus, Error> {
        let raw = userIdOrUsername.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "@", with: "")
        guard !raw.isEmpty else { return .failure(URLError(.badURL)) }
        let encoded = raw.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? raw
        do {
            let data = try await RepositoryHttp.executeCoreGet(
                relativePath: "api/v1/users/\(encoded)/seller-focus",
                client: client
            )
            let root = try RepositoryHttp.jsonObject(data)
            let inner = (root["data"] as? [String: Any]) ?? root
            return .success(try parseSellerListingFocus(inner))
        } catch let err as CoreServiceHttpException where err.statusCode == 403 {
            return .failure(SellerFocusError.forbidden)
        } catch let err as CoreServiceHttpException where err.statusCode == 401 {
            return .failure(SellerFocusError.unauthorized)
        } catch {
            return .failure(error)
        }
    }

    private func parseSellerListingFocus(_ obj: [String: Any]) throws -> SellerListingFocus {
        var categories: [SellerFocusCategory] = []
        if let arr = obj["categories"] as? [[String: Any]] {
            for c in arr {
                let id = RepositoryHttp.optString(c, "id", "ID")
                let name = RepositoryHttp.optString(c, "name", "Name")
                guard !id.isEmpty || !name.isEmpty else { continue }
                categories.append(SellerFocusCategory(
                    id: id,
                    name: name.isEmpty ? "—" : name,
                    parentId: optionalNonEmpty(RepositoryHttp.optString(c, "parent_id", "parentId")),
                    parentName: optionalNonEmpty(RepositoryHttp.optString(c, "parent_name", "parentName"))
                ))
            }
        }
        var brands: [SellerFocusBrand] = []
        if let arr = obj["brands"] as? [[String: Any]] {
            for b in arr {
                let id = RepositoryHttp.optString(b, "id", "ID")
                let name = RepositoryHttp.optString(b, "name", "Name")
                guard !id.isEmpty || !name.isEmpty else { continue }
                brands.append(SellerFocusBrand(id: id, name: name.isEmpty ? "—" : name))
            }
        }
        var tags: [SellerFocusTag] = []
        if let arr = obj["aesthetic_tags"] as? [[String: Any]] {
            for t in arr {
                let id = RepositoryHttp.optString(t, "id", "ID")
                let name = RepositoryHttp.optString(t, "name", "Name")
                guard !id.isEmpty || !name.isEmpty else { continue }
                tags.append(SellerFocusTag(id: id, name: name.isEmpty ? "—" : name))
            }
        }
        return SellerListingFocus(categories: categories, brands: brands, aestheticTags: tags)
    }

    private func parseTopBadges(_ raw: Any?) -> [SellerBadgeSummary] {
        guard let arr = raw as? [[String: Any]] else { return [] }
        return arr.compactMap { row -> SellerBadgeSummary? in
            let id = RepositoryHttp.optString(row, "badge_id", "badgeId", "id", "ID")
            let slug = RepositoryHttp.optString(row, "slug", "Slug")
            let label = RepositoryHttp.optString(row, "label", "Label")
            let emoji = RepositoryHttp.optString(row, "emoji", "Emoji")
            let count = RepositoryHttp.optInt(row, "count", "Count")
            guard !label.isEmpty || !slug.isEmpty else { return nil }
            return SellerBadgeSummary(
                badgeId: id,
                slug: slug,
                label: label.isEmpty ? slug : label,
                emoji: emoji,
                count: count
            )
        }
    }

    private func optIntIfPresent(_ obj: [String: Any], _ keys: String...) -> Int? {
        for key in keys {
            guard obj[key] != nil else { continue }
            let v = RepositoryHttp.optInt(obj, key)
            return v > 0 ? v : nil
        }
        return nil
    }

    private func parseAestheticTagsField(_ obj: [String: Any]) -> ([String], [AestheticTagPutItem]) {
        guard let raw = obj["aesthetic_tags"] ?? obj["aestheticTags"] else { return ([], []) }
        var labels: [String] = []
        var snapshots: [AestheticTagPutItem] = []
        if let strings = raw as? [String] {
            labels = strings.map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
            return (labels, snapshots)
        }
        guard let arr = raw as? [Any] else { return ([], []) }
        for item in arr {
            if let s = item as? String {
                let t = s.trimmingCharacters(in: .whitespaces)
                if !t.isEmpty { labels.append(t) }
                continue
            }
            guard let row = item as? [String: Any] else { continue }
            let id = RepositoryHttp.optString(row, "id", "ID").trimmingCharacters(in: .whitespaces)
            let name = RepositoryHttp.optString(row, "name", "display_name", "displayName").trimmingCharacters(in: .whitespaces)
            let label = name.isEmpty ? id : name
            if !label.isEmpty { labels.append(label) }
            if !id.isEmpty {
                snapshots.append(AestheticTagPutItem(id: id, name: name.isEmpty ? id : name))
            }
        }
        return (labels, snapshots)
    }

    private func optionalNonEmpty(_ value: String) -> String? {
        let t = value.trimmingCharacters(in: .whitespaces)
        return t.isEmpty ? nil : t
    }

    private func optDoubleIfPresent(_ obj: [String: Any], _ key: String) -> Double? {
        guard obj[key] != nil else { return nil }
        if let n = obj[key] as? Double, !n.isNaN { return n }
        if let n = obj[key] as? Int { return Double(n) }
        if let s = obj[key] as? String, let n = Double(s.trimmingCharacters(in: .whitespaces)) { return n }
        return nil
    }

    func getProfile(_ userIdOrUsername: String) async -> Result<ProfileInfo, Error> {
        let raw = userIdOrUsername.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "@", with: "")
        guard !raw.isEmpty else { return .failure(URLError(.badURL)) }
        let encoded = raw.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? raw
        do {
            let data = try await RepositoryHttp.executeCoreGet(relativePath: "api/v1/users/\(encoded)", client: client)
            return .success(try parseProfileInfo(data))
        } catch {
            if PublicBrowseHttp.isConfigured {
                return await getProfilePublic(raw)
            }
            return .failure(error)
        }
    }

    func getProfilePublic(_ userIdOrUsername: String) async -> Result<ProfileInfo, Error> {
        let raw = userIdOrUsername.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: "@", with: "")
        guard !raw.isEmpty else { return .failure(URLError(.badURL)) }
        let encoded = raw.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? raw
        do {
            let data = try await RepositoryHttp.executeGet(
                urlString: PublicBrowseHttp.publicApiPath("users/\(encoded)"),
                client: client,
                publicBrowse: true
            )
            return .success(try parseProfileInfo(data))
        } catch {
            return .failure(error)
        }
    }

    func follow(_ userIdOrUsername: String) async -> Result<Void, Error> {
        await mutateFollow(userIdOrUsername, follow: true)
    }

    func unfollow(_ userIdOrUsername: String) async -> Result<Void, Error> {
        await mutateFollow(userIdOrUsername, follow: false)
    }

    /// core-service follow/unfollow expect canonical `user_id` (UUID) in path — Android [resolveFollowTargetUserId].
    private func resolveFollowTargetUserId(_ raw: String) async -> Result<String, Error> {
        let t = raw.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: "@", with: "")
        guard !t.isEmpty else { return .failure(URLError(.badURL)) }
        if Self.isUserUuid(t) { return .success(t) }
        switch await getProfile(t) {
        case .success(let prof):
            let id = prof.userId.trimmingCharacters(in: .whitespacesAndNewlines)
            return id.isEmpty
                ? .failure(NSError(domain: "FashUser", code: 0, userInfo: [NSLocalizedDescriptionKey: L10n.feedActionError]))
                : .success(id)
        case .failure(let error):
            return .failure(error)
        }
    }

    private static func isUserUuid(_ value: String) -> Bool {
        value.range(
            of: "^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$",
            options: .regularExpression
        ) != nil
    }

    private static func encodeFollowPathSegment(_ segment: String) -> String {
        if isUserUuid(segment) { return segment }
        return segment.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? segment
    }

    private func mutateFollow(_ userIdOrUsername: String, follow: Bool) async -> Result<Void, Error> {
        switch await resolveFollowTargetUserId(userIdOrUsername) {
        case .failure(let error):
            return .failure(error)
        case .success(let targetId):
            let encoded = Self.encodeFollowPathSegment(targetId)
            let path = "api/v1/users/\(encoded)/follow"
            do {
                if follow {
                    try await RepositoryHttp.executeCorePost(
                        relativePath: path,
                        client: client,
                        body: Data("{}".utf8)
                    )
                } else {
                    try await RepositoryHttp.executeCoreDelete(relativePath: path, client: client)
                }
                return .success(())
            } catch {
                return .failure(error)
            }
        }
    }
}
