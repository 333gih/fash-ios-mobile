import Foundation

extension ListingFeedJsonParser {
    /// Full PDP model from `GET /listings/:id` — mirrors Android `ListingRepository.parseListingDetail`.
    static func parseFullListingDetail(_ data: Data) throws -> ListingDetail? {
        let root = try JSONSerialization.jsonObject(with: data)
        let o: [String: Any]
        if let obj = root as? [String: Any] {
            if let nested = obj["data"] as? [String: Any] { o = nested }
            else if let listing = obj["listing"] as? [String: Any] { o = listing }
            else { o = obj }
        } else {
            return nil
        }
        let id = RepositoryHttp.optString(o, "id", "ID")
        guard !id.isEmpty else { return nil }

        let seller = (o["seller"] as? [String: Any]) ?? (o["Seller"] as? [String: Any])
        let categoryObj = (o["category"] as? [String: Any]) ?? (o["Category"] as? [String: Any])
        let parentObj = (o["parent_category"] as? [String: Any]) ?? (o["ParentCategory"] as? [String: Any])
        let brandObj = (o["brand"] as? [String: Any]) ?? (o["Brand"] as? [String: Any])
        let countryObj = (o["country"] as? [String: Any]) ?? (o["Country"] as? [String: Any])
        let shipObj = (o["shipping_address"] as? [String: Any]) ?? (o["ShippingAddress"] as? [String: Any])

        let imageUrls = ListingImageUrlsWire.parseUrlStrings(from: o)
        let coverUrl = ListingImageUrlsWire.resolveCoverUrl(
            coverFromRoot: RepositoryHttp.optString(o, "cover_image_url", "CoverImageURL"),
            listing: o
        )
        let resolvedImages = imageUrls.isEmpty ? [coverUrl].filter { !$0.isEmpty } : imageUrls

        let aestheticRefs = parseAestheticTagRefs(
            o["aesthetic_tags"] as? [[String: Any]] ?? o["AestheticTags"] as? [[String: Any]]
        )
        let tagsArr = o["tags"] as? [Any] ?? o["Tags"] as? [Any]
        var tagStrings: [String] = []
        if let arr = tagsArr {
            for item in arr {
                if let s = item as? String, !s.isEmpty { tagStrings.append(s) }
            }
        }

        let brandId = brandObj.flatMap { RepositoryHttp.optString($0, "id", "ID") }.flatMap { $0.isEmpty ? nil : $0 }
        let brandName = brandObj.flatMap { RepositoryHttp.optString($0, "name", "Name") }.flatMap { $0.isEmpty ? nil : $0 }
            ?? RepositoryHttp.optString(o, "brand", "Brand").nilIfEmpty

        let listPriceVnd: Int64? = ["list_price", "ListPrice", "compare_at_price", "CompareAtPrice", "original_price", "OriginalPrice", "msrp", "MSRP"]
            .compactMap { key -> Int64? in
                guard o[key] != nil else { return nil }
                let v = RepositoryHttp.optLong(o, key)
                return v > 0 ? v : nil
            }.first

        let estimatedShippingVnd: Int64? = [
            "estimated_shipping_fee", "EstimatedShippingFee",
            "shipping_fee_estimate", "ShippingFeeEstimate",
            "shipping_fee", "ShippingFee",
        ].compactMap { key -> Int64? in
            guard o[key] != nil else { return nil }
            let v = RepositoryHttp.optLong(o, key)
            return v > 0 ? v : nil
        }.first

        let shippingAddress: ListingShippingAddress? = shipObj.flatMap { s in
            let line1 = RepositoryHttp.optString(s, "line1", "Line1")
            let label = RepositoryHttp.optString(s, "label", "Label").nilIfEmpty
            guard !line1.isEmpty || label != nil else { return nil }
            return ListingShippingAddress(
                label: label,
                line1: line1,
                line2: RepositoryHttp.optString(s, "line2", "Line2").nilIfEmpty,
                city: RepositoryHttp.optString(s, "city", "City").nilIfEmpty,
                region: RepositoryHttp.optString(s, "region", "Region").nilIfEmpty,
                postalCode: RepositoryHttp.optString(s, "postal_code", "PostalCode").nilIfEmpty,
                countryCode: RepositoryHttp.optString(s, "country_code", "CountryCode").nilIfEmpty
            )
        }

        func optMeasurement(_ key: String) -> Double? {
            guard o[key] != nil || o[key.capitalized] != nil else { return nil }
            let v = (o[key] as? NSNumber)?.doubleValue ?? (o[key.capitalized] as? NSNumber)?.doubleValue ?? 0
            return v > 0 ? v : nil
        }

        let statusRaw = RepositoryHttp.optString(o, "status", "Status").lowercased()
        let status = statusRaw.isEmpty ? "active" : statusRaw

        return ListingDetail(
            id: id,
            title: RepositoryHttp.optString(o, "title", "Title"),
            description: RepositoryHttp.optString(o, "description", "Description"),
            imageUrls: resolvedImages,
            priceVnd: RepositoryHttp.optLong(o, "price", "Price"),
            listPriceVnd: listPriceVnd,
            condition: RepositoryHttp.optString(o, "condition", "Condition"),
            category: categoryObj.flatMap { RepositoryHttp.optString($0, "name", "Name").nilIfEmpty }
                ?? RepositoryHttp.optString(o, "category", "Category").nilIfEmpty,
            categoryId: categoryObj.flatMap { RepositoryHttp.optString($0, "id", "ID").nilIfEmpty },
            parentCategoryName: parentObj.flatMap { RepositoryHttp.optString($0, "name", "Name").nilIfEmpty },
            parentCategoryId: parentObj.flatMap { RepositoryHttp.optString($0, "id", "ID").nilIfEmpty },
            size: RepositoryHttp.optString(o, "size", "Size").nilIfEmpty,
            brand: brandName,
            brandId: brandId,
            material: RepositoryHttp.optString(o, "material", "Material").nilIfEmpty,
            tags: tagStrings,
            likeCount: RepositoryHttp.optInt(o, "like_count", "LikeCount"),
            saveCount: RepositoryHttp.optInt(o, "save_count", "SaveCount"),
            viewCount: RepositoryHttp.optInt(o, "view_count", "ViewCount"),
            measurementUnit: RepositoryHttp.optString(o, "measurement_unit", "MeasurementUnit").nilIfEmpty,
            measurementHem: optMeasurement("measurement_hem"),
            measurementChest: optMeasurement("measurement_chest"),
            measurementLength: optMeasurement("measurement_length"),
            measurementShoulders: optMeasurement("measurement_shoulders"),
            measurementSleeveLength: optMeasurement("measurement_sleeve_length"),
            aestheticTags: aestheticRefs.map(\.label),
            aestheticTagRefs: aestheticRefs,
            acceptOffers: RepositoryHttp.optBool(o, "accept_offers", "AcceptOffers", default: false),
            autoPriceDropEnabled: RepositoryHttp.optBool(o, "auto_price_drop_enabled", "AutoPriceDropEnabled", default: false),
            floorPriceVnd: o["floor_price"] != nil ? RepositoryHttp.optLong(o, "floor_price", "FloorPrice") : nil,
            priceDropPercent: o["price_drop_percent"] != nil ? RepositoryHttp.optInt(o, "price_drop_percent", "PriceDropPercent") : nil,
            nextPriceDropAtIso: RepositoryHttp.optString(o, "next_price_drop_at", "NextPriceDropAt").nilIfEmpty,
            countryName: countryObj.flatMap { RepositoryHttp.optString($0, "name", "Name").nilIfEmpty },
            countryId: countryObj.flatMap { RepositoryHttp.optString($0, "id", "ID").nilIfEmpty }
                ?? RepositoryHttp.optString(o, "country_id", "CountryID").nilIfEmpty,
            countryIso2: countryObj.flatMap { RepositoryHttp.optString($0, "iso2", "ISO2").nilIfEmpty },
            shippingAddress: shippingAddress,
            estimatedShippingVnd: estimatedShippingVnd,
            sellerId: seller.flatMap { RepositoryHttp.optString($0, "user_id", "UserID", "id", "ID").nilIfEmpty }
                ?? RepositoryHttp.optString(o, "seller_id", "SellerID").nilIfEmpty,
            sellerUsername: seller.flatMap { RepositoryHttp.optString($0, "username", "Username").nilIfEmpty }
                ?? RepositoryHttp.optString(o, "seller_username", "SellerUsername").nilIfEmpty,
            sellerAvatarUrl: seller.flatMap {
                RepositoryHttp.optString($0, "avatar_url", "AvatarURL", "profile_image_url", "ProfileImageURL").nilIfEmpty
            },
            sellerDisplayName: seller.flatMap { RepositoryHttp.optString($0, "display_name", "DisplayName").nilIfEmpty },
            sellerVerified: seller.map {
                RepositoryHttp.optBool($0, "verified", "Verified", default: false)
            } ?? false,
            sellerListingCount: seller.flatMap { s -> Int? in
                if s["listing_count"] != nil { return RepositoryHttp.optInt(s, "listing_count", "ListingCount") }
                if s["ListingCount"] != nil { return RepositoryHttp.optInt(s, "ListingCount") }
                return nil
            },
            sellerFollowerCount: seller.flatMap { s -> Int? in
                if s["follower_count"] != nil { return RepositoryHttp.optInt(s, "follower_count", "FollowerCount") }
                return nil
            },
            sellerFollowingCount: seller.flatMap { s -> Int? in
                if s["following_count"] != nil { return RepositoryHttp.optInt(s, "following_count", "FollowingCount") }
                return nil
            },
            sellerAverageRating: seller.flatMap { s -> Float? in
                if let n = s["average_rating"] as? NSNumber { return n.floatValue }
                if let n = s["AverageRating"] as? NSNumber { return n.floatValue }
                return nil
            },
            createdAtIso: RepositoryHttp.optString(o, "created_at", "CreatedAt").nilIfEmpty,
            updatedAtIso: RepositoryHttp.optString(o, "updated_at", "UpdatedAt").nilIfEmpty,
            isLiked: RepositoryHttp.optBool(o, "is_liked", "IsLiked", default: false),
            isSaved: RepositoryHttp.optBool(o, "is_saved", "IsSaved", default: false),
            sellerIsFollowing: {
                guard let seller else { return nil }
                if seller["is_following"] != nil || seller["IsFollowing"] != nil {
                    return RepositoryHttp.optBool(seller, "is_following", "IsFollowing", default: false)
                }
                return nil
            }(),
            status: status,
            color: RepositoryHttp.optString(o, "color", "Color").lowercased().nilIfEmpty,
            genderTarget: RepositoryHttp.optString(o, "gender_target", "GenderTarget").lowercased().nilIfEmpty,
            seasonKeys: parseStringArray(o, "season_keys", "SeasonKeys"),
            climateZones: parseStringArray(o, "climate_zones", "ClimateZones"),
            macroRegions: parseStringArray(o, "macro_regions", "MacroRegions"),
            yearRoundWear: RepositoryHttp.optBool(o, "year_round_wear", "YearRoundWear", default: false)
        )
    }

    private static func parseStringArray(_ o: [String: Any], _ keys: String...) -> [String] {
        for key in keys {
            if let arr = o[key] as? [String] {
                return arr.map { $0.trimmingCharacters(in: .whitespaces).lowercased() }.filter { !$0.isEmpty }
            }
            if let arr = o[key] as? [Any] {
                return arr.compactMap { ($0 as? String)?.trimmingCharacters(in: .whitespaces).lowercased() }.filter { !$0.isEmpty }
            }
        }
        return []
    }

    private static func parseAestheticTagRefs(_ arr: [[String: Any]]?) -> [AestheticTagRef] {
        guard let arr else { return [] }
        return arr.compactMap { tag in
            let label = (tag["display_name"] as? String) ?? (tag["DisplayName"] as? String)
                ?? (tag["name"] as? String) ?? (tag["Name"] as? String) ?? ""
            let trimmed = label.trimmingCharacters(in: .whitespaces)
            guard !trimmed.isEmpty else { return nil }
            let id = (tag["id"] as? String) ?? (tag["ID"] as? String)
            return AestheticTagRef(id: id?.nilIfEmpty, label: trimmed)
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
