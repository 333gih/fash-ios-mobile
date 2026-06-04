import Foundation
import Observation

private struct StepCompletionContext {
    let status: UserAccessStatus
    let skippedAestheticTags: Bool
    let skippedProfilePhoto: Bool
    let skippedSizing: Bool
    let hasAvatar: Bool
    let skipSizingEnv: Bool
}

/// Observable port of Android `OnboardingViewModel` (ui.onboarding).
@Observable
@MainActor
final class OnboardingViewModel {
    var onboardingStep: OnboardingStep = .aestheticTags
    var tags: [CommonAestheticTagDto] = []
    var selectedIds: Set<String> = []
    var username = ""
    var setupPassword = ""
    var setupPasswordConfirm = ""
    var referenceSize = ""
    var measurementUnit = "cm"
    var measurementHem = ""
    var measurementChest = ""
    var measurementLength = ""
    var measurementShoulders = ""
    var measurementSleeve = ""
    var shoppingBuy = true
    var shoppingSell = false
    var genderPreference = ""
    var heightCm = ""
    var weightKg = ""
    var avatarUrl: String?
    var avatarUploading = false
    var uiProgressStep = 0
    var progressTotalSteps = OnboardingFlowProgress.totalSteps
    var isLoading = true
    var isSubmitting = false

    private var lastAccessStatus: UserAccessStatus?
    private var backStack: [OnboardingStep] = []

    private func currentUserId(deps: AppDependencies) -> String {
        deps.authSessionStore.read()?.userId ?? ""
    }

    func applyInitialStepFromAccessStatus(_ status: UserAccessStatus, deps: AppDependencies) async {
        if status.canAccessHome { return }
        lastAccessStatus = status
        if case .success(let profile) = await deps.userRepository.getMeProfile() {
            applyProfileToState(profile)
        }
        backStack.removeAll()
        let current = firstIncompleteStep(status, deps: deps)
        onboardingStep = current
        seedBackStackForStep(current, status: status, deps: deps)
        syncProgressFromCurrentStep(status, deps: deps)
        isLoading = false
    }

    func markProfileSetupGateSkippedForSession() {
        lastAccessStatus = nil
        backStack.removeAll()
        onboardingStep = .completed
    }

    @discardableResult
    func goBack(deps: AppDependencies) -> Bool {
        if backStack.isEmpty, let status = lastAccessStatus {
            seedBackStackForStep(onboardingStep, status: status, deps: deps)
        }
        guard let previous = backStack.popLast() else { return false }
        onboardingStep = previous
        if let status = lastAccessStatus {
            syncProgressFromCurrentStep(status, deps: deps)
        }
        Task { await hydrateSavedProgressFromServer(deps: deps) }
        if previous == .aestheticTags, tags.isEmpty {
            loadTags(deps: deps)
        }
        return true
    }

    func canNavigateBack(deps: AppDependencies) -> Bool {
        if !backStack.isEmpty { return true }
        guard let status = lastAccessStatus else { return false }
        return !priorStepsFor(onboardingStep, status: status, deps: deps).isEmpty
    }

    func hydrateSavedProgressFromServer(deps: AppDependencies) async {
        guard case .success(let profile) = await deps.userRepository.getMeProfile() else { return }
        applyProfileToState(profile)
    }

    func loadTags(deps: AppDependencies) {
        Task {
            isLoading = true
            defer { isLoading = false }
            switch await deps.commonCatalogRepository.getAestheticTags(all: true) {
            case .success(let loaded):
                tags = loaded
            case .failure:
                deps.showSnackbar(L10n.onboardingLoadError)
            }
        }
    }

    func toggleSelection(_ tag: CommonAestheticTagDto) {
        if selectedIds.contains(tag.id) {
            selectedIds.remove(tag.id)
        } else {
            selectedIds.insert(tag.id)
        }
    }

    func onUsernameChange(_ value: String) {
        username = value
            .lowercased()
            .replacingOccurrences(of: "[^a-z0-9_.]", with: "", options: .regularExpression)
            .prefix(30)
            .description
    }

    func onSetupPasswordChange(_ value: String) {
        setupPassword = String(value.prefix(72))
    }

    func onSetupPasswordConfirmChange(_ value: String) {
        setupPasswordConfirm = String(value.prefix(72))
    }

    func canSubmitSetupPassword() -> Bool {
        let p = setupPassword
        let c = setupPasswordConfirm
        return (8...72).contains(p.count) && p == c
    }

    func onReferenceSizeChange(_ value: String) {
        referenceSize = String(value.prefix(40))
    }

    func onMeasurementUnitChange(_ unit: String) {
        measurementUnit = unit.lowercased().trimmingCharacters(in: .whitespaces) == "in" ? "in" : "cm"
    }

    func onMeasurementHemChange(_ value: String) { measurementHem = filterMeasurementInput(value) }
    func onMeasurementChestChange(_ value: String) { measurementChest = filterMeasurementInput(value) }
    func onMeasurementLengthChange(_ value: String) { measurementLength = filterMeasurementInput(value) }
    func onMeasurementShouldersChange(_ value: String) { measurementShoulders = filterMeasurementInput(value) }
    func onMeasurementSleeveChange(_ value: String) { measurementSleeve = filterMeasurementInput(value) }

    func isUsernameValid() -> Bool {
        let u = username.trimmingCharacters(in: .whitespaces)
        guard (3...30).contains(u.count) else { return false }
        return u.range(of: "^[a-z0-9_.]+$", options: .regularExpression) != nil
    }

    func isReferenceSizeValid() -> Bool {
        !referenceSize.trimmingCharacters(in: .whitespaces).isEmpty
    }

    func canSubmitSizing() -> Bool { isReferenceSizeValid() }
    func canSubmitUsername() -> Bool { isUsernameValid() }
    func canContinueFromProfilePhoto() -> Bool { !(avatarUrl?.trimmingCharacters(in: .whitespaces).isEmpty ?? true) }

    func toggleShoppingBuy() { shoppingBuy.toggle() }
    func toggleShoppingSell() { shoppingSell.toggle() }
    func setGenderPreference(_ gender: String) { genderPreference = gender }
    func onHeightCmChange(_ value: String) { heightCm = value }
    func onWeightKgChange(_ value: String) { weightKg = value }

    func getSelectedTagNames() -> [String] {
        tags.filter { selectedIds.contains($0.id) }.map(\.name)
    }

    func submitAestheticTagsPut(deps: AppDependencies, onSuccess: @escaping () -> Void) {
        Task {
            isSubmitting = true
            defer { isSubmitting = false }
            switch await deps.userRepository.putUserAestheticTags(buildSelectedTagPutItems()) {
            case .success:
                let status = (try? await deps.userRepository.getUserAccessStatus().get()) ?? lastAccessStatus
                let base = status ?? UserAccessStatus(
                    hasProfile: false,
                    aestheticTagsConfigured: true,
                    onboardingDone: false,
                    sizingReferenceCompleted: false
                )
                advanceAfterStatus(base.merging(aestheticTagsConfigured: true), completedStep: .aestheticTags, deps: deps)
                onSuccess()
            case .failure(let err):
                let msg = FashErrorPresentation.userMessage(for: err)
                deps.showSnackbar(msg.isEmpty ? L10n.onboardingAestheticError : msg)
            }
        }
    }

    func skipAestheticTagsPersistLocal(deps: AppDependencies, onSuccess: @escaping () -> Void) {
        let uid = currentUserId(deps: deps)
        if !uid.isEmpty { deps.onboardingLocalStore.setSkippedAestheticTags(userId: uid, value: true) }
        Task {
            isSubmitting = true
            defer { isSubmitting = false }
            if case .success(let status) = await deps.userRepository.getUserAccessStatus() {
                advanceAfterStatus(status, completedStep: .aestheticTags, deps: deps)
            }
            onSuccess()
        }
    }

    func submitShoppingPreferences(deps: AppDependencies, onSuccess: @escaping () -> Void) {
        var intents: [String] = []
        if shoppingBuy { intents.append("buy") }
        if shoppingSell { intents.append("sell") }
        guard !intents.isEmpty else {
            deps.showSnackbar(L10n.onboardingShoppingError)
            return
        }
        Task {
            isSubmitting = true
            defer { isSubmitting = false }
            let gender = genderPreference.trimmingCharacters(in: .whitespaces).lowercased()
            switch await deps.userRepository.saveShoppingPreferences(
                shoppingIntents: intents,
                gender: gender.isEmpty ? nil : gender
            ) {
            case .success:
                let status = (try? await deps.userRepository.getUserAccessStatus().get()) ?? lastAccessStatus
                let base = status ?? UserAccessStatus(
                    hasProfile: false,
                    aestheticTagsConfigured: true,
                    onboardingDone: false,
                    sizingReferenceCompleted: false,
                    shoppingPreferencesConfigured: true
                )
                advanceAfterStatus(base.merging(shoppingPreferencesConfigured: true), completedStep: .shoppingPreferences, deps: deps)
                onSuccess()
            case .failure:
                deps.showSnackbar(L10n.onboardingShoppingError)
            }
        }
    }

    func setAvatarFromBytes(_ bytes: Data, mimeType: String = "image/jpeg", deps: AppDependencies) {
        let ext: String
        switch mimeType.lowercased() {
        case "image/png": ext = "png"
        case "image/webp": ext = "webp"
        case "image/gif": ext = "gif"
        default: ext = "jpg"
        }
        Task {
            avatarUploading = true
            defer { avatarUploading = false }
            switch await deps.userRepository.uploadProfileImage(
                bytes: bytes,
                filename: "avatar.\(ext)",
                type: "avatar",
                mimeType: mimeType
            ) {
            case .success(let url):
                avatarUrl = url
            case .failure:
                deps.showSnackbar(L10n.editProfileUploadError)
            }
        }
    }

    func completeProfilePhotoStep(deps: AppDependencies, onSuccess: @escaping () -> Void) {
        guard canContinueFromProfilePhoto() else {
            deps.showSnackbar(L10n.onboardingProfilePhotoRequired)
            return
        }
        advanceAfterProfilePhoto(deps: deps, onSuccess: onSuccess)
    }

    func skipProfilePhoto(deps: AppDependencies, onSuccess: @escaping () -> Void) {
        let uid = currentUserId(deps: deps)
        if !uid.isEmpty { deps.onboardingLocalStore.setSkippedProfilePhoto(userId: uid, value: true) }
        advanceAfterProfilePhoto(deps: deps, onSuccess: onSuccess)
    }

    func submitSizingOnly(deps: AppDependencies, onSuccess: @escaping () -> Void) {
        guard canSubmitSizing() else { return }
        Task {
            isSubmitting = true
            defer { isSubmitting = false }
            switch await deps.userRepository.saveSizingReference(buildSizingRequest()) {
            case .success:
                let status = (try? await deps.userRepository.getUserAccessStatus().get()) ?? lastAccessStatus
                let base = status ?? UserAccessStatus(
                    hasProfile: false,
                    aestheticTagsConfigured: true,
                    onboardingDone: false,
                    sizingReferenceCompleted: true
                )
                advanceAfterStatus(base.merging(sizingReferenceCompleted: true), completedStep: .sizingReference, deps: deps)
                onSuccess()
            case .failure(let err):
                let msg = FashErrorPresentation.userMessage(for: err)
                deps.showSnackbar(msg.isEmpty ? L10n.onboardingSizingError : msg)
            }
        }
    }

    func skipSizingPersistLocal(deps: AppDependencies, onSuccess: @escaping () -> Void) {
        let uid = currentUserId(deps: deps)
        if !uid.isEmpty { deps.onboardingLocalStore.setSkippedSizing(userId: uid, value: true) }
        Task {
            isSubmitting = true
            defer { isSubmitting = false }
            if case .success(let status) = await deps.userRepository.getUserAccessStatus() {
                advanceAfterStatus(status, completedStep: .sizingReference, deps: deps)
            }
            onSuccess()
        }
    }

    func submitUsernameOnboard(deps: AppDependencies, onSuccess: @escaping () -> Void) {
        let u = username.trimmingCharacters(in: .whitespaces)
        guard isUsernameValid() else { return }
        let selectedTags = getSelectedTagNames()
        let refTok = deps.pendingReferralToken?.trimmingCharacters(in: .whitespaces).nilIfEmpty
        Task {
            isSubmitting = true
            defer { isSubmitting = false }
            switch await deps.userRepository.onboard(username: u, aestheticTags: selectedTags, referralToken: refTok) {
            case .success:
                deps.pendingReferralToken = nil
                deps.pendingReferrerUsername = nil
                let status = (try? await deps.userRepository.getUserAccessStatus().get()) ?? lastAccessStatus
                let base = (status ?? UserAccessStatus(
                    hasProfile: false,
                    aestheticTagsConfigured: true,
                    onboardingDone: true,
                    sizingReferenceCompleted: true
                )).merging(onboardingDone: true, hasProfile: true)
                advanceAfterStatus(base, completedStep: .username, deps: deps)
                onSuccess()
            case .failure(let err):
                let msg = FashErrorPresentation.userMessage(for: err)
                if msg.contains("409") || msg.localizedCaseInsensitiveContains("taken") || msg.localizedCaseInsensitiveContains("username") {
                    deps.showSnackbar(L10n.profileSetupUsernameTaken)
                } else {
                    deps.showSnackbar(msg.isEmpty ? L10n.onboardingSubmitError : msg)
                }
            }
        }
    }

    func submitSetupPassword(deps: AppDependencies, onSuccess: @escaping () -> Void) {
        guard canSubmitSetupPassword() else { return }
        let pwd = setupPassword
        Task {
            isSubmitting = true
            defer { isSubmitting = false }
            switch await deps.userRepository.putUserPassword(newPassword: pwd, currentPassword: nil) {
            case .success:
                setupPassword = ""
                setupPasswordConfirm = ""
                _ = await AuthTokenRefreshCoordinator.refreshIfStillCurrent(
                    sessionStore: deps.authSessionStore,
                    authRepository: deps.authRepository,
                    expectedRefreshToken: ""
                )
                let status = (try? await deps.userRepository.getUserAccessStatus().get())
                let base = status
                    ?? lastAccessStatus?.merging(passwordSet: true, isChangePassword: false)
                    ?? UserAccessStatus(
                        hasProfile: true,
                        aestheticTagsConfigured: true,
                        onboardingDone: true,
                        sizingReferenceCompleted: true,
                        passwordSet: true,
                        isChangePassword: false
                    )
                advanceAfterStatus(base, completedStep: .setupPassword, deps: deps)
                onSuccess()
            case .failure(let err):
                let raw = FashErrorPresentation.userMessage(for: err)
                let msg: String
                if raw.contains("PASSWORD_LENGTH") {
                    msg = L10n.passwordErrorLength
                } else if raw.contains("INVALID_CURRENT_PASSWORD") {
                    msg = L10n.passwordErrorInvalidCurrent
                } else if raw.contains("CURRENT_PASSWORD_REQUIRED") {
                    msg = L10n.passwordErrorCurrentRequired
                } else {
                    msg = raw.isEmpty ? L10n.passwordChangeErrorGeneric : raw
                }
                deps.showSnackbar(msg)
            }
        }
    }

    // MARK: - Private

    private func stepCompletionContext(_ status: UserAccessStatus, deps: AppDependencies) -> StepCompletionContext {
        let uid = currentUserId(deps: deps)
        return StepCompletionContext(
            status: status,
            skippedAestheticTags: deps.onboardingLocalStore.skippedAestheticTags(userId: uid),
            skippedProfilePhoto: deps.onboardingLocalStore.skippedProfilePhoto(userId: uid),
            skippedSizing: deps.onboardingLocalStore.skippedSizing(userId: uid),
            hasAvatar: !(avatarUrl?.trimmingCharacters(in: .whitespaces).isEmpty ?? true),
            skipSizingEnv: AppEnvironment.skipSizingReferenceCompleted
        )
    }

    private func canonicalFlow(_ status: UserAccessStatus) -> [OnboardingStep] {
        OnboardingFlowProgress.buildCanonicalSteps(
            includePassword: OnboardingFlowProgress.includesPasswordStep(status),
            includeSizing: !AppEnvironment.skipSizingReferenceCompleted
        )
    }

    private func firstIncompleteStep(_ status: UserAccessStatus, deps: AppDependencies) -> OnboardingStep {
        let ctx = stepCompletionContext(status, deps: deps)
        return OnboardingFlowProgress.firstIncompleteStep(
            flow: canonicalFlow(status),
            status: ctx.status,
            skippedAestheticTags: ctx.skippedAestheticTags,
            skippedProfilePhoto: ctx.skippedProfilePhoto,
            skippedSizing: ctx.skippedSizing,
            hasAvatar: ctx.hasAvatar,
            skipSizingEnv: ctx.skipSizingEnv
        )
    }

    private func syncProgressFromCurrentStep(_ status: UserAccessStatus, deps: AppDependencies) {
        let flow = canonicalFlow(status)
        progressTotalSteps = flow.count
        uiProgressStep = OnboardingFlowProgress.progressDisplayIndex(step: onboardingStep, flow: flow)
    }

    private func advanceAfterStatus(_ status: UserAccessStatus, completedStep: OnboardingStep?, deps: AppDependencies) {
        lastAccessStatus = status
        let prev = onboardingStep
        let flow = canonicalFlow(status)
        let next: OnboardingStep
        if completedStep == .username {
            next = .completed
        } else if let completedStep {
            next = OnboardingFlowProgress.nextStepInFlow(flow: flow, current: completedStep)
                ?? ((status.canAccessHome || status.onboardingDone) ? .completed : firstIncompleteStep(status, deps: deps))
        } else {
            next = OnboardingFlowProgress.nextStepInFlow(flow: flow, current: prev)
                ?? firstIncompleteStep(status, deps: deps)
        }
        if next != prev { backStack.append(prev) }
        onboardingStep = next
        syncProgressFromCurrentStep(status, deps: deps)
    }

    private func seedBackStackForStep(_ current: OnboardingStep, status: UserAccessStatus, deps: AppDependencies) {
        backStack = priorStepsFor(current, status: status, deps: deps)
    }

    private func priorStepsFor(_ current: OnboardingStep, status: UserAccessStatus, deps: AppDependencies) -> [OnboardingStep] {
        OnboardingFlowProgress.buildPriorSteps(flow: canonicalFlow(status), current: current)
    }

    private func advanceAfterProfilePhoto(deps: AppDependencies, onSuccess: @escaping () -> Void) {
        Task {
            isSubmitting = true
            defer { isSubmitting = false }
            if case .success(let status) = await deps.userRepository.getUserAccessStatus() {
                advanceAfterStatus(status, completedStep: .profilePhoto, deps: deps)
            }
            onSuccess()
        }
    }

    private func applyProfileToState(_ profile: ProfileInfo) {
        if !profile.aestheticTagSnapshots.isEmpty {
            selectedIds = Set(profile.aestheticTagSnapshots.map(\.id))
        }
        if !profile.gender.isEmpty { genderPreference = profile.gender }
        if let ref = profile.referenceSize { referenceSize = ref }
        if let unit = profile.referenceMeasurementUnit { onMeasurementUnitChange(unit) }
        if let v = profile.referenceMeasurementChest { measurementChest = formatMeasurement(v) }
        if let v = profile.referenceMeasurementHem { measurementHem = formatMeasurement(v) }
        if let v = profile.referenceMeasurementLength { measurementLength = formatMeasurement(v) }
        if let v = profile.referenceMeasurementShoulders { measurementShoulders = formatMeasurement(v) }
        if let v = profile.referenceMeasurementSleeveLength { measurementSleeve = formatMeasurement(v) }
        if let h = profile.heightCm { heightCm = "\(h)" }
        if let w = profile.weightKg { weightKg = formatMeasurement(w) }
        if !profile.username.isEmpty, username.isEmpty { username = profile.username }
        if !profile.avatarUrl.isEmpty { avatarUrl = profile.avatarUrl }
    }

    private func formatMeasurement(_ value: Double) -> String {
        let rounded = (value * 10).rounded() / 10
        if rounded.truncatingRemainder(dividingBy: 1) == 0 {
            return String(Int(rounded))
        }
        return String(rounded)
    }

    private func filterMeasurementInput(_ raw: String) -> String {
        var result = ""
        var dotSeen = false
        for c in raw.replacingOccurrences(of: ",", with: ".") {
            if c.isNumber, result.count < 8 {
                result.append(c)
            } else if c == ".", !dotSeen, !result.isEmpty {
                result.append(".")
                dotSeen = true
            }
        }
        return result
    }

    private func buildSelectedTagPutItems() -> [AestheticTagPutItem] {
        tags
            .filter { selectedIds.contains($0.id) }
            .map { AestheticTagPutItem(id: $0.id, name: $0.name.isEmpty ? $0.displayName : $0.name) }
    }

    private func buildSizingRequest() -> SizingReferenceRequest {
        let heightVal = Int(heightCm.trimmingCharacters(in: .whitespaces)).flatMap { (100...250).contains($0) ? $0 : nil }
        let weightTrim = weightKg.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        let weightVal = Double(weightTrim).flatMap { (20.0...300.0).contains($0) ? $0 : nil }
        return SizingReferenceRequest(
            referenceSize: referenceSize.trimmingCharacters(in: .whitespaces),
            referenceMeasurementUnit: measurementUnit,
            referenceMeasurementChest: parseMeasurementToDouble(measurementChest),
            referenceMeasurementHem: parseMeasurementToDouble(measurementHem),
            referenceMeasurementLength: parseMeasurementToDouble(measurementLength),
            referenceMeasurementShoulders: parseMeasurementToDouble(measurementShoulders),
            referenceMeasurementSleeveLength: parseMeasurementToDouble(measurementSleeve),
            heightCm: heightVal,
            weightKg: weightVal
        )
    }

    private func parseMeasurementToDouble(_ s: String) -> Double {
        let t = s.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        guard !t.isEmpty, let v = Double(t) else { return 0 }
        return max(v, 0)
    }
}

private extension UserAccessStatus {
    func merging(
        hasProfile: Bool? = nil,
        aestheticTagsConfigured: Bool? = nil,
        onboardingDone: Bool? = nil,
        sizingReferenceCompleted: Bool? = nil,
        shoppingPreferencesConfigured: Bool? = nil,
        passwordSet: Bool? = nil,
        isChangePassword: Bool? = nil
    ) -> UserAccessStatus {
        var copy = self
        if let hasProfile { copy.hasProfile = hasProfile }
        if let aestheticTagsConfigured { copy.aestheticTagsConfigured = aestheticTagsConfigured }
        if let onboardingDone { copy.onboardingDone = onboardingDone }
        if let sizingReferenceCompleted { copy.sizingReferenceCompleted = sizingReferenceCompleted }
        if let shoppingPreferencesConfigured { copy.shoppingPreferencesConfigured = shoppingPreferencesConfigured }
        if let passwordSet { copy.passwordSet = passwordSet }
        if let isChangePassword { copy.isChangePassword = isChangePassword }
        return copy
    }
}

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespaces)
        return t.isEmpty ? nil : t
    }
}
