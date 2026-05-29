import Foundation

extension UserRepository {
    /// GET auth/me — Android [fetchAuthMeJsonOrNull].
    func fetchAuthMeData() async -> Data? {
        let path = AppEnvironment.authMePath.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        let urlString = AppEnvironment.authServicePath(path)
        guard let url = URL(string: urlString) else { return nil }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        do {
            let (data, http) = try await client.data(for: request)
            guard (200..<300).contains(http.statusCode), !data.isEmpty else { return nil }
            return data
        } catch {
            return nil
        }
    }

    /// Merges auth identity (email, phone) into core profile — Android [mergeAuthMeIntoProfile].
    func mergeAuthMeIntoProfile(_ profile: ProfileInfo, authData: Data?) -> ProfileInfo {
        guard let authData,
              let root = try? RepositoryHttp.jsonObject(authData) else { return profile }
        let obj = (root["data"] as? [String: Any]) ?? root

        let email = RepositoryHttp.optString(obj, "email", "Email")
        let phone = RepositoryHttp.optString(obj, "phone_number", "phoneNumber", "PhoneNumber")
        let fullName = RepositoryHttp.optString(obj, "full_name", "fullName", "FullName")
        let avatar = RepositoryHttp.optString(obj, "avatar_url", "avatarUrl", "AvatarURL")
        let authId = RepositoryHttp.optString(obj, "id", "ID")

        var display = profile.displayName
        if display.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !fullName.isEmpty {
            display = fullName
        }
        var avatarUrl = profile.avatarUrl
        if avatarUrl.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !avatar.isEmpty {
            avatarUrl = avatar
        }
        var userId = profile.userId
        if userId.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !authId.isEmpty {
            userId = authId
        }

        return ProfileInfo(
            userId: userId,
            username: profile.username,
            displayName: display,
            avatarUrl: avatarUrl,
            coverImageUrl: profile.coverImageUrl,
            followerCount: profile.followerCount,
            followingCount: profile.followingCount,
            productCount: profile.productCount,
            bio: profile.bio,
            isFollowing: profile.isFollowing,
            aestheticTags: profile.aestheticTags,
            aestheticTagSnapshots: profile.aestheticTagSnapshots,
            referenceSize: profile.referenceSize,
            referenceMeasurementUnit: profile.referenceMeasurementUnit,
            referenceMeasurementChest: profile.referenceMeasurementChest,
            referenceMeasurementHem: profile.referenceMeasurementHem,
            referenceMeasurementLength: profile.referenceMeasurementLength,
            referenceMeasurementShoulders: profile.referenceMeasurementShoulders,
            referenceMeasurementSleeveLength: profile.referenceMeasurementSleeveLength,
            gender: profile.gender,
            soldCount: profile.soldCount,
            rating: profile.rating,
            reviewCount: profile.reviewCount,
            verified: profile.verified,
            hasFastDelivery: profile.hasFastDelivery,
            reputationPoints: profile.reputationPoints,
            meetingNoShowWarning: profile.meetingNoShowWarning,
            sizingReferenceCompleted: profile.sizingReferenceCompleted,
            heightCm: profile.heightCm,
            weightKg: profile.weightKg,
            accountEmail: email.isEmpty ? profile.accountEmail : email,
            accountPhone: phone.isEmpty ? profile.accountPhone : phone,
            topBadges: profile.topBadges
        )
    }
}
