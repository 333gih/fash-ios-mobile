import Foundation

struct CategorySearchMatch: Identifiable, Equatable {
    var id: String { leaf.id }
    let leaf: CategoryTreeNode
    let pathSegments: [String]

    var pathLabel: String { pathSegments.joined(separator: " · ") }
}

func buildCategorySearchMatches(roots: [CategoryTreeNode], query: String) -> [CategorySearchMatch] {
    let q = query.trimmingCharacters(in: .whitespaces)
    guard !q.isEmpty else { return [] }
    let ql = q.lowercased()
    var out: [CategorySearchMatch] = []
    func walk(_ node: CategoryTreeNode, ancestors: [String]) {
        let segments = ancestors + [node.name]
        if node.children.isEmpty {
            let searchable = segments.joined(separator: " ").lowercased()
            if searchable.contains(ql) {
                out.append(CategorySearchMatch(leaf: node, pathSegments: segments))
            }
        } else {
            for child in node.children { walk(child, ancestors: segments) }
        }
    }
    for root in roots { walk(root, ancestors: []) }
    var seen = Set<String>()
    return out
        .filter { seen.insert($0.leaf.id).inserted }
        .sorted {
            if $0.pathSegments.count != $1.pathSegments.count {
                return $0.pathSegments.count < $1.pathSegments.count
            }
            return $0.pathLabel < $1.pathLabel
        }
}

func resolvePostValidationMessage(_ key: String) -> String {
    switch key {
    case "post_validation_category": return L10n.postValidationCategory
    case "post_validation_title_short": return L10n.postValidationTitleShort
    case "post_validation_title_long": return L10n.postValidationTitleLong
    case "post_validation_description_long": return L10n.postValidationDescriptionLong
    case "post_validation_condition": return L10n.postValidationCondition
    case "post_validation_photos": return L10n.postValidationPhotos
    case "post_validation_price": return L10n.postValidationPrice
    case "post_validation_price_range": return L10n.postValidationPriceRange
    case "post_validation_tags_max": return L10n.postValidationTagsMax
    case "post_validation_commitment": return L10n.postValidationCommitment
    case "post_validation_floor": return L10n.postValidationFloor
    case "post_validation_floor_below_price": return L10n.postValidationFloorBelowPrice
    case "post_validation_drop_percent": return L10n.postValidationDropPercent
    default: return key
    }
}

func formatDraftPriceVnd(_ raw: String) -> String {
    guard let amount = parsePositiveLong(raw) else { return "—" }
    return FeedPriceFormat.format(amount)
}

private func parsePositiveLong(_ s: String) -> Int64? {
    let digits = s.trimmingCharacters(in: .whitespaces)
        .replacingOccurrences(of: ".", with: "")
        .replacingOccurrences(of: ",", with: "")
    guard let v = Int64(digits), v > 0 else { return nil }
    return v
}

func genderTargetLabel(_ value: String) -> String {
    switch value.lowercased() {
    case "women": return L10n.genderTargetWomen
    case "men": return L10n.genderTargetMen
    case "unisex": return L10n.genderTargetUnisex
    case "kids": return L10n.genderTargetKids
    case "baby": return L10n.genderTargetKids
    default: return value
    }
}

func hasAnyMeasurement(_ draft: CreateListingDraft) -> Bool {
    [draft.measurementHem, draft.measurementChest, draft.measurementLength,
     draft.measurementShoulders, draft.measurementSleeveLength]
        .contains { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
}

func matchesBrandQuery(_ brand: CommonBrandDto, query: String) -> Bool {
    let q = query.trimmingCharacters(in: .whitespaces).lowercased()
    if q.isEmpty { return true }
    return brand.name.lowercased().contains(q)
}

func matchesCountryQuery(_ country: CommonCountryDto, query: String) -> Bool {
    let q = query.trimmingCharacters(in: .whitespaces).lowercased()
    if q.isEmpty { return true }
    return country.name.lowercased().contains(q) || country.iso2.lowercased().contains(q)
}

let listingPrimaryColorOptions: [(value: String, label: () -> String)] = [
    ("black", { L10n.colorBlack }),
    ("white", { L10n.colorWhite }),
    ("grey", { L10n.colorGray }),
    ("navy", { L10n.colorNavy }),
    ("beige", { L10n.colorBeige }),
    ("brown", { L10n.colorBrown }),
    ("blue", { L10n.colorBlue }),
    ("red", { L10n.colorRed }),
    ("green", { L10n.colorGreen }),
    ("pink", { L10n.colorPink }),
    ("yellow", { L10n.colorYellow }),
    ("olive", { L10n.colorOlive }),
    ("cream", { L10n.colorCream }),
    ("orange", { L10n.colorOrange }),
    ("purple", { L10n.colorPurple }),
]

func matchesTagQuery(_ tag: CommonAestheticTagDto, query: String) -> Bool {
    let q = query.trimmingCharacters(in: .whitespaces).lowercased()
    if q.isEmpty { return true }
    return tag.name.lowercased().contains(q)
        || tag.displayName.lowercased().contains(q)
        || tag.displayNameVi.lowercased().contains(q)
}

extension CreateListingDraft {
    func nextStepBlockedReason(step: Int) -> String? {
        guard !canProceedFromStep(step) else { return nil }
        switch step {
        case 1:
            if categoryId.isEmpty { return L10n.postNextBlockedCategory }
            return L10n.postNextBlockedGeneric
        case 2:
            if selectedAestheticTagIds.count > maxAestheticTags { return L10n.postNextBlockedTags }
            return L10n.postNextBlockedGeneric
        case 5:
            if condition.isEmpty { return L10n.postNextBlockedCondition }
            let t = title.trimmingCharacters(in: .whitespaces)
            if t.count < minListingTitleLength { return L10n.postNextBlockedTitleShort }
            if t.count > maxListingTitleLength { return L10n.postNextBlockedTitleLong }
            if description.count > maxListingDescriptionLength { return L10n.postNextBlockedDescriptionLong }
            return L10n.postNextBlockedGeneric
        case 7:
            return L10n.postNextBlockedPhotos
        case 8:
            return step8NextBlockedReason()
        case 9:
            if !onsiteInspectionCommitment { return L10n.postNextBlockedCommitment }
            return L10n.postNextBlockedGeneric
        default:
            return L10n.postNextBlockedGeneric
        }
    }

    private func step8NextBlockedReason() -> String {
        guard let p = parsePositiveLong(priceVnd) else { return L10n.postNextBlockedPrice }
        if p < minPriceVnd || p > maxPriceVnd { return L10n.postNextBlockedPriceRange }
        if !autoPriceDropEnabled { return L10n.postNextBlockedGeneric }
        guard let f = parsePositiveLong(floorPriceVnd), (minPriceVnd...maxPriceVnd).contains(f) else {
            return L10n.postNextBlockedFloor
        }
        if f >= p { return L10n.postNextBlockedFloorBelow }
        guard let pct = parsedPriceDropPercent(), (1...50).contains(pct) else {
            return L10n.postNextBlockedDropPercent
        }
        return L10n.postNextBlockedGeneric
    }
}

private func parsePositiveLong(_ s: String) -> Int64? {
    let digits = s.trimmingCharacters(in: .whitespaces)
        .replacingOccurrences(of: ".", with: "")
        .replacingOccurrences(of: ",", with: "")
    guard let v = Int64(digits), v > 0 else { return nil }
    return v
}
