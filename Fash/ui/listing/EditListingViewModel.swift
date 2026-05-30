import Foundation
import Observation

private let titleMin = 3
private let titleMax = 60
private let descMax = 500
private let sizeMax = 20
private let brandMax = 50
private let maxTags = 5

private func editListingNonEmpty(_ raw: String?) -> String? {
    let t = raw?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return t.isEmpty ? nil : t
}

@Observable
@MainActor
final class EditListingViewModel {
    var detail: ListingDetail?
    var form = EditListingFormState()
    var catalogTags: [CommonAestheticTagDto] = []
    var brandsFeatured: [CommonBrandDto] = []
    var brandsSearch: [CommonBrandDto] = []
    var countries: [CommonCountryDto] = []
    var countrySearch: [CommonCountryDto] = []
    var baselineTagIds: Set<String> = []

    var isLoading = true
    var isSaving = false
    var isDeleting = false
    var loadError: String?
    var shouldDismissAfterDelete = false

    private var activeListingId = ""

    var canSave: Bool {
        guard let d = detail, !isSaving else { return false }
        guard isListingStatusSellerPutAllowed(d.status) else { return false }
        let title = form.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard title.count >= titleMin, title.count <= titleMax else { return false }
        guard let price = parseEditPositiveLong(form.priceText),
              (minPriceVnd...maxPriceVnd).contains(price) else { return false }
        guard !form.condition.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return false }
        if form.autoPriceDropEnabled {
            guard let floor = effectiveFloorPriceForAutoDrop(form: form, detail: d),
                  (minPriceVnd...maxPriceVnd).contains(floor),
                  floor < price,
                  effectivePriceDropPercentForAutoDrop(form: form, detail: d) != nil else { return false }
        }
        return hasFormChanges(detail: d, form: form, baselineTags: baselineTagIds)
    }

    func load(listingId: String, deps: AppDependencies) async {
        let id = listingId.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !id.isEmpty else {
            loadError = L10n.editListingLoadError
            isLoading = false
            return
        }
        activeListingId = id
        isLoading = true
        loadError = nil
        detail = nil

        if case .success(let page) = await deps.commonCatalogRepository.getBrands(limit: 50) {
            brandsFeatured = page.items
            brandsSearch = page.items
        }
        if case .success(let list) = await deps.commonCatalogRepository.getCountries(all: true) {
            countries = list
            countrySearch = list
        }
        if case .success(let catalog) = await deps.commonCatalogRepository.getAestheticTags(all: true) {
            catalogTags = catalog
        }

        switch await deps.listingRepository.getListingDetailFull(listingId: id) {
        case .success(let d):
            detail = d
            let selectedIds = baselineTagIdsFromDetail(d, catalog: catalogTags)
            baselineTagIds = selectedIds
            let pct = d.priceDropPercent.flatMap { (1...50).contains($0) ? String($0) : nil } ?? "10"
            form = EditListingFormState(
                title: d.title,
                description: String(d.description.prefix(descMax)),
                priceText: d.priceVnd > 0 ? String(d.priceVnd) : "",
                condition: ListingConditionOptions.normalizeApiToUi(d.condition),
                size: String((d.size ?? "").prefix(sizeMax)),
                brandId: d.brandId,
                brandName: String((d.brand ?? "").prefix(brandMax)),
                selectedTagIds: selectedIds,
                countryId: d.countryId,
                countryIso2: d.countryIso2 ?? "",
                countryName: d.countryName ?? "",
                measurementUnit: editListingNonEmpty(d.measurementUnit) ?? "cm",
                measurementHem: formatEditMeasurementField(d.measurementHem),
                measurementChest: formatEditMeasurementField(d.measurementChest),
                measurementLength: formatEditMeasurementField(d.measurementLength),
                measurementShoulders: formatEditMeasurementField(d.measurementShoulders),
                measurementSleeveLength: formatEditMeasurementField(d.measurementSleeveLength),
                acceptOffers: d.acceptOffers,
                autoPriceDropEnabled: d.autoPriceDropEnabled,
                floorPriceText: (d.floorPriceVnd ?? 0) > 0 ? String(d.floorPriceVnd!) : "",
                priceDropPercentInput: pct,
                color: normalizeEditChoice(d.color),
                genderTarget: normalizeEditChoice(d.genderTarget)
            )
        case .failure(let err):
            loadError = editListingNonEmpty(FashErrorPresentation.userMessage(for: err)) ?? L10n.editListingLoadError
        }
        isLoading = false
    }

    func updateForm(_ transform: (inout EditListingFormState) -> Void) {
        var next = form
        transform(&next)
        form = next
    }

    func toggleTag(_ tagId: String) {
        var next = form.selectedTagIds
        if next.contains(tagId) { next.remove(tagId) }
        else if next.count < maxTags { next.insert(tagId) }
        form.selectedTagIds = next
    }

    func searchBrands(query: String, deps: AppDependencies) async {
        if case .success(let page) = await deps.commonCatalogRepository.getBrands(
            q: editListingNonEmpty(query),
            limit: 50
        ) {
            brandsSearch = page.items
        }
    }

    func selectBrand(_ brand: CommonBrandDto?) {
        if let brand {
            form.brandId = brand.id
            form.brandName = String(brand.name.prefix(brandMax))
        } else {
            form.brandId = nil
            form.brandName = ""
        }
    }

    func searchCountries(query: String) {
        let base = countries
        let q = query.trimmingCharacters(in: .whitespacesAndNewlines)
        if q.isEmpty {
            countrySearch = base
            return
        }
        let low = q.lowercased()
        countrySearch = base.filter {
            $0.name.lowercased().contains(low)
                || $0.iso2.lowercased().contains(low)
                || $0.iso3.lowercased().contains(low)
        }
    }

    func selectCountry(_ country: CommonCountryDto?) {
        if let country {
            form.countryId = country.id
            form.countryIso2 = country.iso2
            form.countryName = country.name
        } else {
            form.countryId = nil
            form.countryIso2 = ""
            form.countryName = ""
        }
    }

    func save(deps: AppDependencies) async -> Bool {
        guard let d = detail else { return false }
        guard isListingStatusSellerPutAllowed(d.status) else {
            deps.showSnackbar(L10n.editListingNotEditable)
            return false
        }
        let title = form.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if title.count < titleMin || title.count > titleMax {
            deps.showSnackbar(L10n.editListingTitleInvalid)
            return false
        }
        guard let price = parseEditPositiveLong(form.priceText),
              (minPriceVnd...maxPriceVnd).contains(price) else {
            deps.showSnackbar(L10n.editListingPriceInvalid)
            return false
        }
        if form.condition.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            deps.showSnackbar(L10n.postValidationCondition)
            return false
        }
        if form.autoPriceDropEnabled {
            guard let floor = effectiveFloorPriceForAutoDrop(form: form, detail: d),
                  (minPriceVnd...maxPriceVnd).contains(floor) else {
                deps.showSnackbar(L10n.postValidationFloor)
                return false
            }
            if floor >= price {
                deps.showSnackbar(L10n.postValidationFloorBelowPrice)
                return false
            }
            if effectivePriceDropPercentForAutoDrop(form: form, detail: d) == nil {
                deps.showSnackbar(L10n.postValidationDropPercent)
                return false
            }
        }
        guard hasFormChanges(detail: d, form: form, baselineTags: baselineTagIds) else {
            deps.showSnackbar(L10n.editListingNoChanges)
            return false
        }
        guard let update = buildDeltaUpdate(detail: d, form: form, baselineTags: baselineTagIds, catalog: catalogTags) else {
            deps.showSnackbar(L10n.editListingSaveError)
            return false
        }

        isSaving = true
        defer { isSaving = false }
        switch await deps.listingRepository.updateListing(listingId: activeListingId, update: update) {
        case .success:
            let wasRejected = d.status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "rejected"
            if wasRejected {
                if case .success(let fresh) = await deps.listingRepository.getListingDetailFull(listingId: activeListingId) {
                    detail = fresh
                    baselineTagIds = baselineTagIdsFromDetail(fresh, catalog: catalogTags)
                } else {
                    snapDetailAndBaselineFromForm()
                    if var cur = detail { cur.status = "in_review"; detail = cur }
                }
                deps.showSnackbar(L10n.editListingResubmitted)
            } else {
                snapDetailAndBaselineFromForm()
                deps.showSnackbar(L10n.editListingSaved)
            }
            return true
        case .failure(let err):
            if let http = err as? CoreServiceHttpException, http.statusCode == 409 {
                deps.showSnackbar(editListingNonEmpty(http.message) ?? L10n.editListingNotEditable)
            } else {
                deps.showSnackbar(editListingNonEmpty(FashErrorPresentation.userMessage(for: err)) ?? L10n.editListingSaveError)
            }
            return false
        }
    }

    func delete(deps: AppDependencies) async {
        isDeleting = true
        defer { isDeleting = false }
        switch await deps.listingRepository.deleteListing(listingId: activeListingId) {
        case .success:
            deps.showSnackbar(L10n.editListingDeleted)
            shouldDismissAfterDelete = true
        case .failure(let err):
            deps.showSnackbar(editListingNonEmpty(FashErrorPresentation.userMessage(for: err)) ?? L10n.editListingDeleteError)
        }
    }

    private func snapDetailAndBaselineFromForm() {
        guard var d = detail else { return }
        let f = form
        let title = f.title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let price = parseEditPositiveLong(f.priceText) else { return }
        let tagNames = f.selectedTagIds.compactMap { id in catalogTags.first(where: { $0.id == id })?.name }
        d.title = title
        d.description = String(f.description.prefix(descMax))
        d.priceVnd = price
        d.condition = ListingConditionOptions.normalizeUiToApi(f.condition)
        d.size = editListingNonEmpty(f.size)
        d.brand = editListingNonEmpty(f.brandName)
        d.brandId = f.brandId
        d.tags = tagNames
        d.aestheticTags = tagNames
        d.countryId = f.countryId
        d.countryName = editListingNonEmpty(f.countryName)
        d.countryIso2 = editListingNonEmpty(f.countryIso2)
        d.measurementUnit = editListingNonEmpty(f.measurementUnit)
        d.measurementHem = parseEditDoubleField(f.measurementHem)
        d.measurementChest = parseEditDoubleField(f.measurementChest)
        d.measurementLength = parseEditDoubleField(f.measurementLength)
        d.measurementShoulders = parseEditDoubleField(f.measurementShoulders)
        d.measurementSleeveLength = parseEditDoubleField(f.measurementSleeveLength)
        d.acceptOffers = f.acceptOffers
        d.autoPriceDropEnabled = f.autoPriceDropEnabled
        d.floorPriceVnd = f.autoPriceDropEnabled ? parseEditPositiveLong(f.floorPriceText) : nil
        d.priceDropPercent = f.autoPriceDropEnabled ? parsedEditPriceDropPercent(f.priceDropPercentInput) : nil
        d.color = editListingNonEmpty(normalizeEditChoice(f.color))
        d.genderTarget = editListingNonEmpty(normalizeEditChoice(f.genderTarget))
        detail = d
        baselineTagIds = f.selectedTagIds
    }
}

// MARK: - Delta / validation helpers

private func parseEditPositiveLong(_ s: String) -> Int64? {
    let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        .replacingOccurrences(of: ".", with: "")
        .replacingOccurrences(of: ",", with: "")
    guard let v = Int64(t), v > 0 else { return nil }
    return v
}

private func parseEditDoubleField(_ s: String) -> Double? {
    let t = s.trimmingCharacters(in: .whitespacesAndNewlines).replacingOccurrences(of: ",", with: ".")
    return Double(t)
}

private func formatEditMeasurementField(_ d: Double?) -> String {
    guard let d else { return "" }
    if abs(d.truncatingRemainder(dividingBy: 1)) < 1e-6 {
        return String(Int(d))
    }
    return String(format: "%.1f", locale: Locale(identifier: "en_US_POSIX"), d)
}

private func normalizeEditChoice(_ raw: String?) -> String {
    raw?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() ?? ""
}

private func parsedEditPriceDropPercent(_ input: String) -> Int? {
    let d = input.filter(\.isNumber).prefix(2)
    guard !d.isEmpty, let n = Int(d), (1...50).contains(n) else { return nil }
    return n
}

private func effectiveFloorPriceForAutoDrop(form: EditListingFormState, detail: ListingDetail) -> Int64? {
    if let fromForm = parseEditPositiveLong(form.floorPriceText) { return fromForm }
    if let floor = detail.floorPriceVnd, floor > 0 { return floor }
    return nil
}

private func effectivePriceDropPercentForAutoDrop(form: EditListingFormState, detail: ListingDetail) -> Int? {
    if let fromForm = parsedEditPriceDropPercent(form.priceDropPercentInput) { return fromForm }
    if let p = detail.priceDropPercent, (1...50).contains(p) { return p }
    return nil
}

private func measurementEq(_ a: Double?, _ b: Double?) -> Bool {
    switch (a, b) {
    case (nil, nil): return true
    case let (x?, y?): return abs(x - y) < 1e-6
    default: return false
    }
}

private func hasFormChanges(detail: ListingDetail, form: EditListingFormState, baselineTags: Set<String>) -> Bool {
    let title = form.title.trimmingCharacters(in: .whitespacesAndNewlines)
    let desc = String(form.description.prefix(descMax))
    let size = String(form.size.prefix(sizeMax)).trimmingCharacters(in: .whitespacesAndNewlines)
    let bn = String(form.brandName.prefix(brandMax)).trimmingCharacters(in: .whitespacesAndNewlines)
    let dDesc = String(detail.description.prefix(descMax))
    let dSize = (detail.size ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let dBrand = (detail.brand ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    if title != detail.title { return true }
    if desc != dDesc { return true }
    if form.priceText.trimmingCharacters(in: .whitespacesAndNewlines) != (detail.priceVnd > 0 ? String(detail.priceVnd) : "") { return true }
    if ListingConditionOptions.canonicalApi(form.condition) != ListingConditionOptions.canonicalApi(detail.condition) { return true }
    if size != dSize { return true }
    if bn != dBrand || form.brandId != detail.brandId { return true }
    if form.selectedTagIds != baselineTags { return true }
    let coIso = form.countryIso2.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    let dCo = (detail.countryIso2 ?? "").trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    if coIso != dCo { return true }
    if form.countryId != detail.countryId { return true }
    if form.countryName.trimmingCharacters(in: .whitespacesAndNewlines) != (detail.countryName ?? "").trimmingCharacters(in: .whitespacesAndNewlines) { return true }
    let unitForm = form.measurementUnit.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    let unitD = editListingNonEmpty((detail.measurementUnit ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()) ?? "cm"
    if unitForm != unitD { return true }
    if !measurementEq(parseEditDoubleField(form.measurementHem), detail.measurementHem) { return true }
    if !measurementEq(parseEditDoubleField(form.measurementChest), detail.measurementChest) { return true }
    if !measurementEq(parseEditDoubleField(form.measurementLength), detail.measurementLength) { return true }
    if !measurementEq(parseEditDoubleField(form.measurementShoulders), detail.measurementShoulders) { return true }
    if !measurementEq(parseEditDoubleField(form.measurementSleeveLength), detail.measurementSleeveLength) { return true }
    if form.acceptOffers != detail.acceptOffers { return true }
    if form.autoPriceDropEnabled != detail.autoPriceDropEnabled { return true }
    if form.autoPriceDropEnabled {
        if parseEditPositiveLong(form.floorPriceText) != detail.floorPriceVnd { return true }
        if let p = parsedEditPriceDropPercent(form.priceDropPercentInput), p != detail.priceDropPercent { return true }
    }
    if normalizeEditChoice(form.color) != normalizeEditChoice(detail.color) { return true }
    if normalizeEditChoice(form.genderTarget) != normalizeEditChoice(detail.genderTarget) { return true }
    return false
}

private func buildDeltaUpdate(
    detail: ListingDetail,
    form: EditListingFormState,
    baselineTags: Set<String>,
    catalog: [CommonAestheticTagDto]
) -> UpdateListingRequest? {
    guard hasFormChanges(detail: detail, form: form, baselineTags: baselineTags) else { return nil }
    let title = form.title.trimmingCharacters(in: .whitespacesAndNewlines)
    let desc = String(form.description.prefix(descMax))
    guard let price = parseEditPositiveLong(form.priceText) else { return nil }
    let size = String(form.size.prefix(sizeMax)).trimmingCharacters(in: .whitespacesAndNewlines)
    let bn = String(form.brandName.prefix(brandMax)).trimmingCharacters(in: .whitespacesAndNewlines)
    let dDesc = String(detail.description.prefix(descMax))
    let dSize = (detail.size ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    let dBrand = (detail.brand ?? "").trimmingCharacters(in: .whitespacesAndNewlines)

    let titleP = title != detail.title ? title : nil
    let descP = desc != dDesc ? desc : nil
    let priceP = price != detail.priceVnd ? price : nil
    let condP: String? = ListingConditionOptions.canonicalApi(form.condition) != ListingConditionOptions.canonicalApi(detail.condition)
        ? ListingConditionOptions.normalizeUiToApi(form.condition) : nil
    let sizeP = size != dSize ? size : nil
    let brandChanged = bn != dBrand || form.brandId != detail.brandId
    let brandIdP = brandChanged ? editListingNonEmpty(form.brandId) : nil
    let brandNameP = brandChanged ? bn : nil
    let tagsP: [String]? = form.selectedTagIds != baselineTags
        ? form.selectedTagIds.compactMap { id in catalog.first(where: { $0.id == id })?.name.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
            .sorted()
        : nil

    let coIso = form.countryIso2.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    let dCo = (detail.countryIso2 ?? "").trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
    let countryOfOriginP = coIso != dCo ? (coIso.count == 2 ? coIso : nil) : nil
    let countryIdP = form.countryId != detail.countryId ? form.countryId : nil
    let countryNameP = form.countryName.trimmingCharacters(in: .whitespacesAndNewlines) != (detail.countryName ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        ? form.countryName.trimmingCharacters(in: .whitespacesAndNewlines) : nil

    let unitForm = form.measurementUnit.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    let unitD = editListingNonEmpty((detail.measurementUnit ?? "").trimmingCharacters(in: .whitespacesAndNewlines).lowercased()) ?? "cm"
    let measurementUnitP = unitForm != unitD ? unitForm : nil

    func deltaMeasurement(_ formVal: String, _ detailVal: Double?) -> Double? {
        let parsed = parseEditDoubleField(formVal)
        if measurementEq(parsed, detailVal) { return nil }
        return parsed ?? 0
    }

    let acceptP = form.acceptOffers != detail.acceptOffers ? form.acceptOffers : nil
    let autoP = form.autoPriceDropEnabled != detail.autoPriceDropEnabled ? form.autoPriceDropEnabled : nil
    let floorParsed = parseEditPositiveLong(form.floorPriceText)
    let floorP = form.autoPriceDropEnabled && floorParsed != detail.floorPriceVnd ? floorParsed : nil
    let percentP: Int? = form.autoPriceDropEnabled ? {
        let p = parsedEditPriceDropPercent(form.priceDropPercentInput)
        return p != nil && p != detail.priceDropPercent ? p : nil
    }() : nil

    let colorNorm = normalizeEditChoice(form.color)
    let colorP = colorNorm != normalizeEditChoice(detail.color) ? editListingNonEmpty(colorNorm) : nil
    let genderNorm = normalizeEditChoice(form.genderTarget)
    let genderP = genderNorm != normalizeEditChoice(detail.genderTarget) ? editListingNonEmpty(genderNorm) : nil

    var hemP = deltaMeasurement(form.measurementHem, detail.measurementHem)
    var chestP = deltaMeasurement(form.measurementChest, detail.measurementChest)
    var lenP = deltaMeasurement(form.measurementLength, detail.measurementLength)
    var shP = deltaMeasurement(form.measurementShoulders, detail.measurementShoulders)
    var slP = deltaMeasurement(form.measurementSleeveLength, detail.measurementSleeveLength)

    return UpdateListingRequest(
        title: titleP,
        condition: condP,
        priceVnd: priceP,
        description: descP,
        brandId: brandIdP,
        brandName: brandNameP,
        size: sizeP,
        aestheticTags: tagsP,
        acceptOffers: acceptP,
        autoPriceDropEnabled: autoP,
        floorPriceVnd: floorP,
        priceDropPercent: percentP,
        countryOfOrigin: countryOfOriginP,
        countryId: countryIdP,
        countryName: countryNameP,
        measurementUnit: measurementUnitP,
        measurementHem: hemP,
        measurementChest: chestP,
        measurementLength: lenP,
        measurementShoulders: shP,
        measurementSleeveLength: slP,
        color: colorP,
        genderTarget: genderP
    )
}

private func baselineTagIdsFromDetail(_ detail: ListingDetail, catalog: [CommonAestheticTagDto]) -> Set<String> {
    guard !catalog.isEmpty else { return [] }
    if !detail.aestheticTagRefs.isEmpty {
        let fromIds = Set(detail.aestheticTagRefs.compactMap { ref -> String? in
            guard let id = ref.id, catalog.contains(where: { $0.id == id }) else { return nil }
            return id
        })
        if !fromIds.isEmpty { return fromIds }
    }
    let strings = detail.aestheticTags.isEmpty ? detail.tags : detail.aestheticTags
    return matchEditTagIds(listingTagStrings: strings, catalog: catalog)
}

private func matchEditTagIds(listingTagStrings: [String], catalog: [CommonAestheticTagDto]) -> Set<String> {
    var out = Set<String>()
    for s in listingTagStrings {
        let t = s.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { continue }
        if let byId = catalog.first(where: { $0.id.caseInsensitiveCompare(t) == .orderedSame }) {
            out.insert(byId.id)
            continue
        }
        for tag in catalog where !out.contains(tag.id) {
            if tag.name.caseInsensitiveCompare(t) == .orderedSame
                || tag.displayName().caseInsensitiveCompare(t) == .orderedSame {
                out.insert(tag.id)
                break
            }
        }
    }
    return out
}
