import Foundation
import Observation
import PhotosUI
import UniformTypeIdentifiers

@Observable
@MainActor
final class PostViewModel {
    var draft = CreateListingDraft()
    var step = createListingModeStep
    var categoryTree: [CategoryTreeNode] = []
    var aestheticTags: [CommonAestheticTagDto] = []
    var aestheticTagsById: [String: CommonAestheticTagDto] = [:]
    var brandsFeatured: [CommonBrandDto] = []
    var brandsSearch: [CommonBrandDto] = []
    var countries: [CommonCountryDto] = []
    var catalogLoading = false
    var catalogReady = false
    var navReselectLoading = false
    var meProfile: ProfileInfo?
    var localAddresses: [ShippingAddress] = []
    var isUploading = false
    var listingPhotoSetupLoading = false
    var isSubmitting = false
    var eventMessage: String?

    func loadCatalogIfNeeded(deps: AppDependencies) async {
        guard !catalogReady, !catalogLoading else { return }
        await loadCatalogInternal(deps: deps)
    }

    func reloadOnNavReselect(deps: AppDependencies) async {
        navReselectLoading = true
        defer { navReselectLoading = false }
        await loadCatalogInternal(deps: deps, force: true)
        await loadProfileForPreview(deps: deps)
        loadLocalShippingAddresses(deps: deps)
        await loadShippingAddresses(deps: deps)
    }

    private func loadCatalogInternal(deps: AppDependencies, force: Bool = false) async {
        if !force, catalogReady || catalogLoading { return }
        catalogLoading = true
        defer {
            catalogLoading = false
            catalogReady = true
        }
        if case .success(let tree) = await deps.commonCatalogRepository.getCategoryTree() {
            categoryTree = tree
        }
        if case .success(let tags) = await deps.commonCatalogRepository.getAestheticTags(all: true) {
            aestheticTags = tags
            aestheticTagsById = Dictionary(tags.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        }
        if case .success(let page) = await deps.commonCatalogRepository.getBrands(limit: 50) {
            brandsFeatured = page.items
            brandsSearch = page.items
        }
        if case .success(let list) = await deps.commonCatalogRepository.getCountries(all: true) {
            countries = list
        }
    }

    func clearCachesForSignedOutUser() {
        draft = CreateListingDraft()
        step = createListingModeStep
        meProfile = nil
        localAddresses = []
        isUploading = false
        isSubmitting = false
    }

    func searchBrands(deps: AppDependencies, query: String) async {
        let q = query.trimmingCharacters(in: .whitespaces)
        if case .success(let page) = await deps.commonCatalogRepository.getBrands(q: q.isEmpty ? nil : q, limit: 50) {
            brandsSearch = page.items
        }
    }

    func loadProfileForPreview(deps: AppDependencies) async {
        switch await deps.userRepository.getMeProfile() {
        case .success(let profile): meProfile = profile
        case .failure: meProfile = nil
        }
    }

    func selectFillMode(deps: AppDependencies, mode: CreateListingFillMode) async {
        if mode == .fromProfileStyle {
            await loadProfileForPreview(deps: deps)
            if let profile = meProfile {
                draft = draft.applyProfileStyleIfEmpty(profile: profile)
                if !profile.hasStyleReferenceForListing() {
                    eventMessage = L10n.postFillModeProfileEmpty
                }
            } else {
                draft.fillMode = .fromProfileStyle
                eventMessage = L10n.postFillModeProfileEmpty
            }
        } else {
            draft.fillMode = .manual
        }
        step = 1
    }

    func loadLocalShippingAddresses(deps: AppDependencies) {
        guard let uid = deps.authSessionStore.read()?.userId else { return }
        localAddresses = deps.addressLocalStore.listAddresses(uid)
    }

    func loadShippingAddresses(deps: AppDependencies) async {
        guard let uid = deps.authSessionStore.read()?.userId else { return }
        switch await deps.userShippingAddressRepository.listShippingAddresses() {
        case .success(let api):
            let local = deps.addressLocalStore.listAddresses(uid)
            let merged = mergeShippingAddressesWithLocal(api: api, local: local)
            deps.addressLocalStore.saveAddresses(uid, list: merged)
            localAddresses = merged
        case .failure:
            localAddresses = deps.addressLocalStore.listAddresses(uid)
        }
    }

    func selectShippingAddressForListing(deps: AppDependencies, addressId: String) {
        guard let uid = deps.authSessionStore.read()?.userId,
              let addr = deps.addressLocalStore.listAddresses(uid).first(where: { $0.id == addressId }) else { return }
        draft.shippingAddressId = addr.id
        draft.shippingAddressLabel = addr.labelForDraft()
    }

    func applyDefaultShippingIfNeeded(deps: AppDependencies) {
        guard draft.shippingAddressId == nil,
              let uid = deps.authSessionStore.read()?.userId,
              let def = deps.addressLocalStore.getDefaultOrFirst(uid) else { return }
        draft.shippingAddressId = def.id
        draft.shippingAddressLabel = def.labelForDraft()
    }

    func ensureListingPhotoSlotsLoaded(deps: AppDependencies) async {
        let cat = draft.categoryId.trimmingCharacters(in: .whitespaces)
        guard !cat.isEmpty else { return }
        if draft.listingPhotoSlotsCategoryId == cat, !draft.listingPhotoSlots.isEmpty { return }
        listingPhotoSetupLoading = true
        defer { listingPhotoSetupLoading = false }
        let catalog: [ListingImageStepCatalog]
        if case .success(let setup) = await deps.commonCatalogRepository.getListingImageSetup(categoryId: cat) {
            catalog = setup.steps
        } else {
            catalog = defaultListingImageCatalogSteps()
        }
        draft = draft.withListingPhotoSlotsFromCatalog(categoryId: cat, catalog: catalog)
    }

    func setListingPhotoForStep(stepKey: String, uriString: String?, width: Int? = nil, height: Int? = nil) {
        draft.listingPhotoSlots = draft.listingPhotoSlots.map { s in
            guard s.stepKey == stepKey else { return s }
            var copy = s
            copy.localImageUri = uriString?.trimmingCharacters(in: .whitespaces).nilIfEmpty
            copy.uploadedImageUrl = nil
            copy.imageWidth = width
            copy.imageHeight = height
            return copy
        }
    }

    func clearListingPhotoForStep(stepKey: String) {
        setListingPhotoForStep(stepKey: stepKey, uriString: nil)
    }

    func nextStep(deps: AppDependencies) async {
        guard draft.canProceedFromStep(step) else { return }
        guard step < totalPostSteps else { return }
        step += 1
        if step == 10 {
            await loadShippingAddresses(deps: deps)
            applyDefaultShippingIfNeeded(deps: deps)
        } else if step == 11 {
            await loadProfileForPreview(deps: deps)
            await loadShippingAddresses(deps: deps)
        }
    }

    func prevStep() {
        if step <= createListingModeStep { return }
        if step == 1 {
            step = createListingModeStep
        } else {
            step -= 1
        }
    }

    func goToStep(_ stepNum: Int) {
        if stepNum == createListingModeStep || (1...totalPostSteps).contains(stepNum) {
            step = stepNum
        }
    }

    func updateDraft(_ block: (inout CreateListingDraft) -> Void) {
        var copy = draft
        block(&copy)
        draft = copy
    }

    func uploadImages(deps: AppDependencies) async -> Bool {
        let slots = draft.listingPhotoSlots
        guard !slots.isEmpty else { return true }
        let toUpload = slots.filter {
            !($0.localImageUri?.trimmingCharacters(in: .whitespaces).isEmpty ?? true)
                && ($0.uploadedImageUrl?.trimmingCharacters(in: .whitespaces).isEmpty ?? true)
        }
        guard !toUpload.isEmpty else { return true }
        isUploading = true
        defer { isUploading = false }
        var fileIndex = 0
        for slot in toUpload.sorted(by: { $0.sortOrder < $1.sortOrder }) {
            guard let local = slot.localImageUri,
                  let url = URL(string: local),
                  let data = try? Data(contentsOf: url) else {
                eventMessage = L10n.createListingImageError
                return false
            }
            let measured = ListingImagePixelSize.fromImageData(data)
            let mime = mimeTypeForURL(url)
            let ext = mimeTypeToExt(mime)
            let slug = slot.stepKey.replacingOccurrences(of: "[^a-zA-Z0-9_-]", with: "_", options: .regularExpression).prefix(32)
            let filename = "\(slug)_\(fileIndex).\(ext)"
            fileIndex += 1
            switch await deps.listingRepository.uploadListingImage(bytes: data, filename: String(filename), mimeType: mime) {
            case .success(let uploaded):
                let width = uploaded.width ?? measured?.width ?? slot.imageWidth
                let height = uploaded.height ?? measured?.height ?? slot.imageHeight
                draft.listingPhotoSlots = draft.listingPhotoSlots.map { s in
                    guard s.stepKey == slot.stepKey else { return s }
                    var copy = s
                    copy.uploadedImageUrl = uploaded.url
                    copy.localImageUri = nil
                    copy.imageWidth = width
                    copy.imageHeight = height
                    return copy
                }
            case .failure:
                eventMessage = L10n.createListingUploadError
                return false
            }
        }
        return true
    }

    func submitListing(deps: AppDependencies, onSuccess: () -> Void) async {
        guard !isSubmitting else { return }
        isSubmitting = true
        defer { isSubmitting = false }
        await ensureListingPhotoSlotsLoaded(deps: deps)
        if let errKey = draft.validationErrorKeyForSubmit() {
            eventMessage = resolvePostValidationMessage(errKey)
            return
        }
        let anyPhoto = draft.listingPhotoSlots.contains { $0.hasImageSelected() }
        let skipImages = !postRequireListingImages() && !anyPhoto
        var stepsPayload: [ListingImageStepPayload] = []
        if !skipImages {
            let needsUpload = draft.listingPhotoSlots.contains {
                !($0.localImageUri?.trimmingCharacters(in: .whitespaces).isEmpty ?? true)
                    && ($0.uploadedImageUrl?.trimmingCharacters(in: .whitespaces).isEmpty ?? true)
            }
            if needsUpload {
                guard await uploadImages(deps: deps) else { return }
            }
            stepsPayload = draft.buildListingImageStepPayloads()
        }
        if stepsPayload.isEmpty, postRequireListingImages() {
            eventMessage = L10n.createListingNoImages
            return
        }
        let req = draft.toCreateListingRequest(imageUrlSteps: stepsPayload, aestheticTagsById: aestheticTagsById)
        switch await deps.listingRepository.createListing(req) {
        case .success:
            eventMessage = L10n.createListingSuccessDialogMessage
            resetDraft()
            onSuccess()
        case .failure(let err):
            eventMessage = FashErrorPresentation.userMessage(for: err)
        }
    }

    func cancel() { resetDraft() }

    private func resetDraft() {
        draft = CreateListingDraft()
        step = createListingModeStep
    }

    private func mimeTypeForURL(_ url: URL) -> String {
        if let type = UTType(filenameExtension: url.pathExtension),
           let mime = type.preferredMIMEType {
            return mime
        }
        return "image/jpeg"
    }

    private func mimeTypeToExt(_ mimeType: String) -> String {
        switch mimeType.lowercased() {
        case "image/png": return "png"
        case "image/webp": return "webp"
        case "image/gif": return "gif"
        default: return "jpg"
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespaces)
        return t.isEmpty ? nil : t
    }
}
