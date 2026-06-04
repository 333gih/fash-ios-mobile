import Foundation

extension UserRepository {

    func getUserAccessStatus() async -> Result<UserAccessStatus, Error> {
        let urls = AppEnvironment.coreApiCandidateURLs(AppEnvironment.userAccessStatusPath)
        var lastError: Error = URLError(.cannotConnectToHost)
        for urlString in urls {
            guard let url = URL(string: urlString) else { continue }
            var req = URLRequest(url: url)
            req.httpMethod = "GET"
            do {
                let (data, http) = try await client.data(for: req)
                guard (200..<300).contains(http.statusCode) else {
                    lastError = CoreServiceHttpException(
                        statusCode: http.statusCode,
                        message: CoreServiceErrors.parseMessage(data: data, statusCode: http.statusCode)
                    )
                    continue
                }
                return .success(try parseUserAccessStatus(data))
            } catch {
                lastError = error
            }
        }
        return .failure(lastError)
    }

    func putUserAestheticTags(_ tags: [AestheticTagPutItem]) async -> Result<Void, Error> {
        let arr = tags.map { ["id": $0.id, "name": $0.name] }
        guard let body = try? JSONSerialization.data(withJSONObject: ["aesthetic_tags": arr]) else {
            return .failure(URLError(.cannotParseResponse))
        }
        do {
            _ = try await RepositoryHttp.executeCorePut(
                relativePath: "api/v1/users/me/aesthetic-tags",
                client: client,
                body: body
            )
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    func onboard(username: String, aestheticTags: [String], referralToken: String? = nil) async -> Result<Void, Error> {
        var json: [String: Any] = [
            "username": username,
            "aesthetic_tags": aestheticTags,
        ]
        let rt = referralToken?.trimmingCharacters(in: .whitespaces) ?? ""
        if !rt.isEmpty { json["referral_token"] = rt }
        guard let body = try? JSONSerialization.data(withJSONObject: json) else {
            return .failure(URLError(.cannotParseResponse))
        }
        do {
            _ = try await RepositoryHttp.executeCorePost(
                relativePath: "api/v1/users/onboard",
                client: client,
                body: body
            )
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    func saveSizingReference(_ request: SizingReferenceRequest) async -> Result<Void, Error> {
        var json: [String: Any] = [
            "reference_size": request.referenceSize.trimmingCharacters(in: .whitespaces),
            "reference_measurement_unit": request.referenceMeasurementUnit.trimmingCharacters(in: .whitespaces).lowercased(),
            "reference_measurement_chest": request.referenceMeasurementChest,
            "reference_measurement_hem": request.referenceMeasurementHem,
            "reference_measurement_length": request.referenceMeasurementLength,
            "reference_measurement_shoulders": request.referenceMeasurementShoulders,
            "reference_measurement_sleeve_length": request.referenceMeasurementSleeveLength,
        ]
        if let h = request.heightCm { json["height_cm"] = h }
        if let w = request.weightKg { json["weight_kg"] = w }
        guard let body = try? JSONSerialization.data(withJSONObject: json) else {
            return .failure(URLError(.cannotParseResponse))
        }
        do {
            _ = try await RepositoryHttp.executeCorePut(
                relativePath: "api/v1/users/me/sizing-reference",
                client: client,
                body: body
            )
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    func uploadProfileImage(
        bytes: Data,
        filename: String = "image.jpg",
        type: String = "avatar",
        mimeType: String = "image/jpeg"
    ) async -> Result<String, Error> {
        let path = type.lowercased() == "cover" ? "api/v1/users/me/cover" : "api/v1/users/me/avatar"
        let urlString = AppEnvironment.apiPath(path)
        guard let url = URL(string: urlString) else { return .failure(URLError(.badURL)) }
        let safeMime = mimeType.contains("/") && !mimeType.contains("*") ? mimeType : "image/jpeg"
        let boundary = "FashBoundary-\(UUID().uuidString)"
        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(filename)\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: \(safeMime)\r\n\r\n".data(using: .utf8)!)
        body.append(bytes)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
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
            let avatar = RepositoryHttp.optString(obj, "avatar_url", "image_url")
            let cover = RepositoryHttp.optString(obj, "cover_image_url", "image_url")
            let resolved = type.lowercased() == "cover" ? cover : avatar
            guard !resolved.isEmpty else {
                return .failure(URLError(.cannotParseResponse))
            }
            return .success(resolved)
        } catch {
            return .failure(error)
        }
    }

    private func parseUserAccessStatus(_ data: Data) throws -> UserAccessStatus {
        let root = try RepositoryHttp.jsonObject(data)
        let obj = (root["data"] as? [String: Any]) ?? root
        let serverGate = parseServerCanAccessHome(obj)
        let passwordSet = parseOptionalBool(obj, "password_set", "passwordSet")
        let isChangePassword = parseOptionalBool(obj, "is_change_password", "isChangePassword")
        let reverify = parseJsonBool(obj, "meeting_scheduling_reverify_required")
            ?? parseJsonBool(obj, "meetingSchedulingReverifyRequired")
            ?? false
        let suspended = RepositoryHttp.optString(
            obj,
            "meeting_scheduling_suspended_until",
            "meetingSchedulingSuspendedUntil"
        ).trimmingCharacters(in: .whitespaces)
        let nextRaw = RepositoryHttp.optString(obj, "next_step", "nextStep").trimmingCharacters(in: .whitespaces)
        return UserAccessStatus(
            hasProfile: RepositoryHttp.optBool(obj, "has_profile", "hasProfile"),
            aestheticTagsConfigured: RepositoryHttp.optBool(obj, "aesthetic_tags_configured", "aestheticTagsConfigured"),
            onboardingDone: RepositoryHttp.optBool(obj, "onboarding_done", "onboardingDone"),
            sizingReferenceCompleted: RepositoryHttp.optBool(
                obj,
                "sizing_reference_completed",
                "sizingReferenceCompleted"
            ),
            shoppingPreferencesConfigured: RepositoryHttp.optBool(
                obj,
                "shopping_preferences_configured",
                "shoppingPreferencesConfigured"
            ),
            serverCanAccessHome: serverGate,
            nextStep: nextRaw.isEmpty ? nil : nextRaw,
            passwordSet: passwordSet,
            isChangePassword: isChangePassword,
            meetingSchedulingReverifyRequired: reverify,
            meetingSchedulingSuspendedUntil: suspended.isEmpty ? nil : suspended
        )
    }

    private func parseServerCanAccessHome(_ obj: [String: Any]) -> Bool? {
        if obj["can_access_home"] != nil {
            return parseJsonBool(obj, "can_access_home")
        }
        if obj["canAccessHome"] != nil {
            return parseJsonBool(obj, "canAccessHome")
        }
        return nil
    }

    private func parseOptionalBool(_ obj: [String: Any], _ keys: String...) -> Bool? {
        for key in keys where obj[key] != nil {
            return parseJsonBool(obj, key)
        }
        return nil
    }

    private func parseJsonBool(_ obj: [String: Any], _ key: String) -> Bool? {
        guard let v = obj[key] else { return nil }
        if v is NSNull { return nil }
        if let b = v as? Bool { return b }
        if let n = v as? NSNumber { return n.intValue != 0 }
        if let s = v as? String {
            let t = s.trimmingCharacters(in: .whitespaces).lowercased()
            return t == "true" || t == "1"
        }
        return nil
    }
}
