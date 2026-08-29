import Foundation

struct OutfitSetItem: Equatable, Identifiable {
    var id: String { listingId }
    let listingId: String
    let slotRole: String
    let coverImageUrl: String
    let title: String
    let priceVnd: Int64
    let hasExploreBoost: Bool
    let hasRealBadge: Bool
}

struct OutfitSetCard: Equatable, Identifiable {
    let id: String
    let title: String
    let reasonLabel: String
    let items: [OutfitSetItem]
}

enum OutfitStylistParse {
    static func parseSets(_ value: Any?) -> [OutfitSetCard] {
        guard let arr = value as? [[String: Any]] else { return [] }
        return arr.compactMap(parseSet)
    }

    static func parseSet(_ dict: [String: Any]) -> OutfitSetCard? {
        let id = (dict["id"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        guard !id.isEmpty else { return nil }
        let titleVi = (dict["title_vi"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let titleEn = (dict["title_en"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let title = !titleVi.isEmpty ? titleVi : (!titleEn.isEmpty ? titleEn : ((dict["title"] as? String) ?? ""))
        let itemsRaw = dict["items"] as? [[String: Any]] ?? []
        let items: [OutfitSetItem] = itemsRaw.compactMap { it in
            let listingId = (it["listing_id"] as? String)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !listingId.isEmpty else { return nil }
            return OutfitSetItem(
                listingId: listingId,
                slotRole: it["slot_role"] as? String ?? "",
                coverImageUrl: it["cover_image_url"] as? String ?? "",
                title: it["title"] as? String ?? "",
                priceVnd: (it["price"] as? NSNumber)?.int64Value ?? Int64(it["price"] as? Int ?? 0),
                hasExploreBoost: it["has_explore_boost"] as? Bool ?? false,
                hasRealBadge: it["has_real_badge"] as? Bool ?? false
            )
        }
        return OutfitSetCard(
            id: id,
            title: title,
            reasonLabel: dict["reason_label"] as? String ?? "",
            items: items
        )
    }
}
