import Foundation

enum CreateListingFillMode: String, Equatable {
    case manual
    case fromProfileStyle
}

let createListingModeStep = 0
let totalPostSteps = 10
let maxAestheticTags = 5
let minListingTitleLength = 3
let maxListingTitleLength = 60
let maxListingDescriptionLength = 500
let minPriceVnd: Int64 = 1_000
let maxPriceVnd: Int64 = 100_000_000

struct ListingPhotoSlotDraft: Equatable, Identifiable {
    var id: String { stepKey }
    let stepKey: String
    let label: String
    let labelVi: String
    let sortOrder: Int
    let required: Bool
    var localImageUri: String?
    var uploadedImageUrl: String?
    var imageWidth: Int?
    var imageHeight: Int?

    func hasImageSelected() -> Bool {
        !(localImageUri?.trimmingCharacters(in: .whitespaces).isEmpty ?? true)
            || !(uploadedImageUrl?.trimmingCharacters(in: .whitespaces).isEmpty ?? true)
    }

    func displayLabel() -> String {
        BilingualLabel.resolve(en: label, vi: labelVi)
    }
}

struct CreateListingDraft: Equatable {
    var fillMode: CreateListingFillMode = .manual
    var categoryId: String = ""
    var categoryName: String = ""
    var parentCategoryId: String?
    var parentCategoryName: String?
    var selectedAestheticTagIds: Set<String> = []
    var condition: String = ""
    var size: String = ""
    var color: String = ""
    var genderTarget: String = ""
    var brandId: String?
    var brandName: String = ""
    var title: String = ""
    var description: String = ""
    var countryId: String?
    var countryIso2: String = ""
    var countryName: String = ""
    var measurementUnit: String = "cm"
    var measurementHem: String = ""
    var measurementChest: String = ""
    var measurementLength: String = ""
    var measurementShoulders: String = ""
    var measurementSleeveLength: String = ""
    var listingPhotoSlots: [ListingPhotoSlotDraft] = []
    var listingPhotoSlotsCategoryId: String?
    var priceVnd: String = ""
    var acceptOffers: Bool = true
    var autoPriceDropEnabled: Bool = false
    var floorPriceVnd: String = ""
    var priceDropPercentInput: String = "10"
    var shippingAddressId: String?
    var shippingAddressLabel: String = ""
    var onsiteInspectionCommitment: Bool = false
    var conditionScore: Int = 90
    var conditionDefects: [String] = []
}

let listingConditionDefectOptions = ["stains", "worn", "missing_button", "fading", "pilling", "odor"]

func postRequireListingImages() -> Bool { BuildConfig.postRequireListingImages }

private func parsePositiveLong(_ s: String) -> Int64? {
    let digits = s.trimmingCharacters(in: .whitespaces)
        .replacingOccurrences(of: ".", with: "")
        .replacingOccurrences(of: ",", with: "")
    guard let v = Int64(digits), v > 0 else { return nil }
    return v
}

private func parseDoubleOrNil(_ s: String) -> Double? {
    Double(s.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: "."))
}

extension CreateListingDraft {
    func parsedPriceDropPercent() -> Int? {
        let d = priceDropPercentInput.filter(\.isNumber).prefix(2)
        guard !d.isEmpty, let n = Int(d), (1...50).contains(n) else { return nil }
        return n
    }

    func toggleConditionDefect(_ key: String) -> CreateListingDraft {
        var next = conditionDefects
        if next.contains(key) { next.removeAll { $0 == key } } else { next.append(key) }
        return copy(conditionDefects: next)
    }

    func withListingPhotoSlotsFromCatalog(categoryId: String, catalog: [ListingImageStepCatalog]) -> CreateListingDraft {
        let old = Dictionary(uniqueKeysWithValues: listingPhotoSlots.map { ($0.stepKey, $0) })
        let capped = catalog.sorted { $0.sortOrder < $1.sortOrder }.prefix(20)
        let slots = capped.map { c -> ListingPhotoSlotDraft in
            let o = old[c.stepKey]
            return ListingPhotoSlotDraft(
                stepKey: c.stepKey,
                label: c.label,
                labelVi: c.labelVi,
                sortOrder: c.sortOrder,
                required: c.required,
                localImageUri: o?.localImageUri,
                uploadedImageUrl: o?.uploadedImageUrl,
                imageWidth: o?.imageWidth,
                imageHeight: o?.imageHeight
            )
        }
        return copy(listingPhotoSlots: Array(slots), listingPhotoSlotsCategoryId: categoryId)
    }

    func withLeafCategory(treeRoots: [CategoryTreeNode], leaf: CategoryTreeNode) -> CreateListingDraft {
        let parent = treeRoots.findParentOfLeaf(leaf.id)
        return copy(
            categoryId: leaf.id,
            categoryName: leaf.name,
            parentCategoryId: parent?.id,
            parentCategoryName: parent?.name,
            listingPhotoSlots: [],
            listingPhotoSlotsCategoryId: nil
        )
    }

    func toggleAestheticTag(_ id: String) -> CreateListingDraft {
        var next = selectedAestheticTagIds
        if next.contains(id) {
            next.remove(id)
        } else if next.count < maxAestheticTags {
            next.insert(id)
        }
        return copy(selectedAestheticTagIds: next)
    }

    func canProceedFromStep(_ step: Int) -> Bool {
        switch step {
        case 1: return !categoryId.isEmpty
        case 2: return selectedAestheticTagIds.count <= maxAestheticTags
        case 3, 4, 6: return true
        case 5:
            let t = title.trimmingCharacters(in: .whitespaces)
            return !condition.isEmpty
                && t.count >= minListingTitleLength
                && t.count <= maxListingTitleLength
                && description.count <= maxListingDescriptionLength
        case 7:
            if !postRequireListingImages() { return true }
            return !listingPhotoSlots.isEmpty
                && listingPhotoSlots.allSatisfy { !$0.required || $0.hasImageSelected() }
        case 8:
            guard let p = parsePositiveLong(priceVnd), (minPriceVnd...maxPriceVnd).contains(p) else { return false }
            if !autoPriceDropEnabled { return true }
            guard let f = parsePositiveLong(floorPriceVnd),
                  (minPriceVnd...maxPriceVnd).contains(f),
                  f < p,
                  parsedPriceDropPercent() != nil else { return false }
            return true
        case 9: return onsiteInspectionCommitment
        case 10: return true
        default: return false
        }
    }

    func validationErrorKeyForSubmit() -> String? {
        if categoryId.isEmpty || categoryName.isEmpty { return "post_validation_category" }
        let t = title.trimmingCharacters(in: .whitespaces)
        if t.count < minListingTitleLength { return "post_validation_title_short" }
        if t.count > maxListingTitleLength { return "post_validation_title_long" }
        if description.count > maxListingDescriptionLength { return "post_validation_description_long" }
        if condition.isEmpty { return "post_validation_condition" }
        if postRequireListingImages() {
            let missing = listingPhotoSlots.isEmpty || listingPhotoSlots.contains { $0.required && !$0.hasImageSelected() }
            if missing { return "post_validation_photos" }
        }
        guard let p = parsePositiveLong(priceVnd) else { return "post_validation_price" }
        if p < minPriceVnd || p > maxPriceVnd { return "post_validation_price_range" }
        if selectedAestheticTagIds.count > maxAestheticTags { return "post_validation_tags_max" }
        if !onsiteInspectionCommitment { return "post_validation_commitment" }
        if autoPriceDropEnabled {
            guard let f = parsePositiveLong(floorPriceVnd), (minPriceVnd...maxPriceVnd).contains(f) else {
                return "post_validation_floor"
            }
            if f >= p { return "post_validation_floor_below_price" }
            if parsedPriceDropPercent() == nil { return "post_validation_drop_percent" }
        }
        return nil
    }

    func buildListingImageStepPayloads() -> [ListingImageStepPayload] {
        listingPhotoSlots.sorted { $0.sortOrder < $1.sortOrder }.compactMap { s in
            guard let url = s.uploadedImageUrl?.trimmingCharacters(in: .whitespaces), !url.isEmpty else { return nil }
            return ListingImageStepPayload(
                stepKey: s.stepKey,
                label: s.label.isEmpty ? s.stepKey : s.label,
                labelVi: s.labelVi.isEmpty ? nil : s.labelVi,
                sortOrder: s.sortOrder,
                required: s.required,
                imageUrl: url,
                width: s.imageWidth,
                height: s.imageHeight
            )
        }
    }

    func toCreateListingRequest(
        imageUrlSteps: [ListingImageStepPayload],
        aestheticTagsById: [String: CommonAestheticTagDto]
    ) -> CreateListingRequest {
        let aestheticTagRefs = selectedAestheticTagIds.compactMap { tid -> NamedRefPayload? in
            guard let dto = aestheticTagsById[tid] else { return nil }
            let n = dto.displayName.trimmingCharacters(in: .whitespaces).isEmpty
                ? dto.name.trimmingCharacters(in: .whitespaces)
                : dto.displayName.trimmingCharacters(in: .whitespaces)
            guard !n.isEmpty else { return nil }
            return NamedRefPayload(id: tid, name: n)
        }
        let parentRef: NamedRefPayload? = {
            guard let pid = parentCategoryId?.trimmingCharacters(in: .whitespaces), !pid.isEmpty else { return nil }
            let pn = parentCategoryName?.trimmingCharacters(in: .whitespaces) ?? ""
            guard !pn.isEmpty else { return nil }
            return NamedRefPayload(id: pid, name: pn)
        }()
        let brandRef: NamedRefPayload? = {
            guard let bid = brandId?.trimmingCharacters(in: .whitespaces), !bid.isEmpty else { return nil }
            let bn = brandName.trimmingCharacters(in: .whitespaces)
            guard !bn.isEmpty else { return nil }
            return NamedRefPayload(id: bid, name: bn)
        }()
        let price = parsePositiveLong(priceVnd) ?? 1_000
        let floor = floorPriceVnd.trimmingCharacters(in: .whitespaces).isEmpty ? nil : parsePositiveLong(floorPriceVnd)
        return CreateListingRequest(
            title: title.trimmingCharacters(in: .whitespaces),
            imageUrlSteps: imageUrlSteps,
            priceVnd: price,
            condition: ListingConditionOptions.normalizeUiToApi(condition),
            category: NamedRefPayload(id: categoryId.trimmingCharacters(in: .whitespaces), name: categoryName.trimmingCharacters(in: .whitespaces)),
            description: description.trimmingCharacters(in: .whitespaces),
            size: size.trimmingCharacters(in: .whitespaces),
            color: color.trimmingCharacters(in: .whitespaces).lowercased().nilIfEmpty,
            genderTarget: genderTarget.trimmingCharacters(in: .whitespaces).lowercased().nilIfEmpty,
            parentCategory: parentRef,
            brand: brandRef,
            aestheticTags: aestheticTagRefs,
            countryOfOrigin: countryIso2.count == 2 ? countryIso2 : nil,
            countryId: countryId?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
            countryName: countryName.trimmingCharacters(in: .whitespaces).nilIfEmpty,
            measurementUnit: measurementUnit.nilIfEmpty,
            measurementHem: parseDoubleOrNil(measurementHem),
            measurementChest: parseDoubleOrNil(measurementChest),
            measurementLength: parseDoubleOrNil(measurementLength),
            measurementShoulders: parseDoubleOrNil(measurementShoulders),
            measurementSleeveLength: parseDoubleOrNil(measurementSleeveLength),
            acceptOffers: acceptOffers,
            autoPriceDropEnabled: autoPriceDropEnabled,
            floorPriceVnd: autoPriceDropEnabled ? floor : nil,
            priceDropPercent: autoPriceDropEnabled ? parsedPriceDropPercent() : nil,
            shippingAddressId: shippingAddressId?.trimmingCharacters(in: .whitespaces).nilIfEmpty,
            onsiteInspectionCommitment: onsiteInspectionCommitment,
            conditionScore: min(max(conditionScore, 80), 99),
            conditionDefects: conditionDefects
        )
    }

    private func copy(
        fillMode: CreateListingFillMode? = nil,
        categoryId: String? = nil,
        categoryName: String? = nil,
        parentCategoryId: String?? = nil,
        parentCategoryName: String?? = nil,
        selectedAestheticTagIds: Set<String>? = nil,
        condition: String? = nil,
        listingPhotoSlots: [ListingPhotoSlotDraft]? = nil,
        listingPhotoSlotsCategoryId: String?? = nil,
        conditionDefects: [String]? = nil
    ) -> CreateListingDraft {
        CreateListingDraft(
            fillMode: fillMode ?? self.fillMode,
            categoryId: categoryId ?? self.categoryId,
            categoryName: categoryName ?? self.categoryName,
            parentCategoryId: parentCategoryId ?? self.parentCategoryId,
            parentCategoryName: parentCategoryName ?? self.parentCategoryName,
            selectedAestheticTagIds: selectedAestheticTagIds ?? self.selectedAestheticTagIds,
            condition: condition ?? self.condition,
            size: size,
            color: color,
            genderTarget: genderTarget,
            brandId: brandId,
            brandName: brandName,
            title: title,
            description: description,
            countryId: countryId,
            countryIso2: countryIso2,
            countryName: countryName,
            measurementUnit: measurementUnit,
            measurementHem: measurementHem,
            measurementChest: measurementChest,
            measurementLength: measurementLength,
            measurementShoulders: measurementShoulders,
            measurementSleeveLength: measurementSleeveLength,
            listingPhotoSlots: listingPhotoSlots ?? self.listingPhotoSlots,
            listingPhotoSlotsCategoryId: listingPhotoSlotsCategoryId ?? self.listingPhotoSlotsCategoryId,
            priceVnd: priceVnd,
            acceptOffers: acceptOffers,
            autoPriceDropEnabled: autoPriceDropEnabled,
            floorPriceVnd: floorPriceVnd,
            priceDropPercentInput: priceDropPercentInput,
            shippingAddressId: shippingAddressId,
            shippingAddressLabel: shippingAddressLabel,
            onsiteInspectionCommitment: onsiteInspectionCommitment,
            conditionScore: conditionScore,
            conditionDefects: conditionDefects ?? self.conditionDefects
        )
    }
}

extension CategoryTreeNode {
    func findLeaf(_ id: String) -> CategoryTreeNode? {
        if self.id == id { return children.isEmpty ? self : nil }
        for ch in children {
            if let found = ch.findLeaf(id) { return found }
        }
        return nil
    }

    func findParentOf(_ childId: String) -> CategoryTreeNode? {
        for ch in children {
            if ch.id == childId { return self }
            if let inner = ch.findParentOf(childId) { return inner }
        }
        return nil
    }
}

extension Array where Element == CategoryTreeNode {
    func findParentOfLeaf(_ leafId: String) -> CategoryTreeNode? {
        for root in self {
            if let p = root.findParentOf(leafId) { return p }
        }
        return nil
    }

    func allLeaves() -> [CategoryTreeNode] {
        flatMap { node -> [CategoryTreeNode] in
            if node.children.isEmpty { return [node] }
            return node.children.allLeaves()
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespaces)
        return t.isEmpty ? nil : t
    }
}
