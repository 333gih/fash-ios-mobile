import SwiftUI

// MARK: - Completion State

struct ProfileCompletionState {
    let hasPhoto: Bool
    let hasBio: Bool
    let hasAestheticTags: Bool
    let hasSizing: Bool
    let hasFollowing: Bool

    var completedSteps: Int {
        [hasPhoto, hasBio, hasAestheticTags, hasSizing, hasFollowing].filter { $0 }.count
    }

    var totalSteps: Int { 5 }

    var fraction: Double {
        Double(completedSteps) / Double(totalSteps)
    }

    var isComplete: Bool { completedSteps == totalSteps }

    var nextStepLabel: String {
        if !hasPhoto { return L10n.profileCompletionStepPhoto }
        if !hasAestheticTags { return L10n.profileCompletionStepTags }
        if !hasSizing { return L10n.profileCompletionStepSizing }
        if !hasBio { return L10n.profileCompletionStepBio }
        return L10n.profileCompletionStepFollow
    }

    static func from(_ profile: ProfileInfo?) -> ProfileCompletionState {
        guard let p = profile else {
            return ProfileCompletionState(
                hasPhoto: false, hasBio: false,
                hasAestheticTags: false, hasSizing: false, hasFollowing: false
            )
        }
        return ProfileCompletionState(
            hasPhoto: !p.avatarUrl.isEmpty,
            hasBio: !p.bio.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            hasAestheticTags: !p.aestheticTags.isEmpty,
            hasSizing: p.sizingReferenceCompleted,
            hasFollowing: p.followingCount > 0
        )
    }
}

// MARK: - Card View

struct ProfileCompletionCard: View {
    @Environment(\.fashSpacing) private var spacing

    let state: ProfileCompletionState
    var onAction: () -> Void

    var body: some View {
        Button(action: onAction) {
            VStack(alignment: .leading, spacing: spacing.spacing2) {
                HStack {
                    Text(L10n.profileCompletionImproveTitle)
                        .font(FashTypography.labelLarge)
                        .foregroundStyle(FashColors.textPrimary)
                    Spacer()
                    Text(L10n.profileCompletionStepsFormat(state.completedSteps, state.totalSteps))
                        .font(FashTypography.labelMedium.weight(.bold))
                        .foregroundStyle(FashColors.brandPrimary)
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(FashColors.outlineMuted.opacity(0.2))
                        Capsule()
                            .fill(FashColors.brandPrimary)
                            .frame(width: geo.size.width * state.fraction)
                            .animation(FashMotion.progressFill, value: state.fraction)
                    }
                }
                .frame(height: 4)

                HStack(spacing: spacing.spacing1) {
                    Text(state.nextStepLabel)
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(FashColors.textSecondary)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundStyle(FashColors.textSecondary)
                }
            }
            .padding(.horizontal, spacing.editorialStart)
            .padding(.vertical, spacing.spacing3)
            .background(FashColors.surfaceContainerLow)
            .clipShape(FashShapes.medium)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, spacing.editorialStart)
    }
}
