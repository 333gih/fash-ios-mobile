import Foundation

enum ProductDiscoveryRelation: Equatable {
    case seller
    case category
    case brand
    case style
}

struct ProductDiscoveryFeedEntry: Identifiable, Equatable {
    let item: ListingFeedItem
    let relation: ProductDiscoveryRelation
    let relationLabel: String

    var id: String { item.id }
}

enum ProductDiscoveryFeedBuilder {
    static func merge(
        detail: ListingDetail,
        sellerLabel: String,
        sellerItems: [ListingFeedItem],
        categoryLabel: String?,
        categoryItems: [ListingFeedItem],
        brandLabel: String?,
        brandItems: [ListingFeedItem],
        styleItems: [ListingFeedItem],
        limit: Int = ProductDetailDiscoveryConstants.mergedDiscoveryLimit
    ) -> [ProductDiscoveryFeedEntry] {
        var seen = Set<String>()
        var result: [ProductDiscoveryFeedEntry] = []

        func append(_ items: [ListingFeedItem], relation: ProductDiscoveryRelation, label: String) {
            let badge = label.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !badge.isEmpty else { return }
            for item in items {
                let key = item.id.lowercased()
                if seen.contains(key) { continue }
                seen.insert(key)
                result.append(
                    ProductDiscoveryFeedEntry(item: item, relation: relation, relationLabel: badge)
                )
                if result.count >= limit { return }
            }
        }

        append(sellerItems, relation: .seller, label: sellerLabel)
        if result.count < limit, let cat = categoryLabel?.nilIfEmpty {
            append(categoryItems, relation: .category, label: cat)
        }
        if result.count < limit, let brand = brandLabel?.nilIfEmpty {
            append(brandItems, relation: .brand, label: brand)
        }
        if result.count < limit {
            let styleBadge = detail.aestheticTagRefs.first?.label.nilIfEmpty ?? L10n.productRelatedStyle
            append(styleItems, relation: .style, label: styleBadge)
        }
        return result
    }
}

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
