import Foundation

/// Canonical onboarding chain — Android [OnboardingFlowProgress].
enum OnboardingFlowProgress {
    static let totalSteps = 6
    static let progressHeaderHeight: CGFloat = 20

    static func buildCanonicalSteps(includePassword: Bool, includeSizing: Bool = true) -> [OnboardingStep] {
        var flow: [OnboardingStep] = []
        if includePassword { flow.append(.setupPassword) }
        flow.append(.aestheticTags)
        flow.append(.shoppingPreferences)
        flow.append(.profilePhoto)
        if includeSizing { flow.append(.sizingReference) }
        flow.append(.username)
        return flow
    }

    static func includesPasswordStep(_ status: UserAccessStatus) -> Bool {
        status.needsPasswordSetup()
            || status.nextStep?.trimmingCharacters(in: .whitespaces).lowercased() == "password"
    }

    static func isStepComplete(
        step: OnboardingStep,
        status: UserAccessStatus,
        skippedAestheticTags: Bool,
        skippedProfilePhoto: Bool,
        skippedSizing: Bool,
        hasAvatar: Bool,
        skipSizingEnv: Bool
    ) -> Bool {
        switch step {
        case .setupPassword:
            return !status.needsPasswordSetup()
                && status.nextStep?.trimmingCharacters(in: .whitespaces).lowercased() != "password"
        case .aestheticTags:
            return status.aestheticTagsConfigured || skippedAestheticTags
        case .shoppingPreferences:
            return status.shoppingPreferencesConfigured
        case .profilePhoto:
            return hasAvatar || skippedProfilePhoto
        case .sizingReference:
            return status.sizingReferenceCompleted || skippedSizing || skipSizingEnv
        case .username:
            return status.onboardingDone
        case .completed:
            return true
        }
    }

    static func firstIncompleteStep(
        flow: [OnboardingStep],
        status: UserAccessStatus,
        skippedAestheticTags: Bool,
        skippedProfilePhoto: Bool,
        skippedSizing: Bool,
        hasAvatar: Bool,
        skipSizingEnv: Bool
    ) -> OnboardingStep {
        for step in flow {
            if !isStepComplete(
                step: step,
                status: status,
                skippedAestheticTags: skippedAestheticTags,
                skippedProfilePhoto: skippedProfilePhoto,
                skippedSizing: skippedSizing,
                hasAvatar: hasAvatar,
                skipSizingEnv: skipSizingEnv
            ) {
                return step
            }
        }
        if status.canAccessHome || status.onboardingDone {
            return .completed
        }
        return flow.last ?? .completed
    }

    static func buildPriorSteps(flow: [OnboardingStep], current: OnboardingStep) -> [OnboardingStep] {
        guard let idx = flow.firstIndex(of: current), idx > 0 else { return [] }
        return Array(flow[..<idx])
    }

    static func nextStepInFlow(flow: [OnboardingStep], current: OnboardingStep) -> OnboardingStep? {
        guard let idx = flow.firstIndex(of: current), idx >= 0, idx < flow.count - 1 else { return nil }
        return flow[idx + 1]
    }

    static func progressDisplayIndex(step: OnboardingStep, flow: [OnboardingStep]) -> Int {
        if step == .completed { return flow.count }
        return max(flow.firstIndex(of: step) ?? 0, 0)
    }

    static func blocksShellPromosAndTours(needsOnboarding: Bool?) -> Bool {
        needsOnboarding != false
    }
}
