import SwiftUI

struct CreateListingModeStep: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps
    @Bindable var postVM: PostViewModel
    let onClose: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            CreateListingFlowHeader(
                step: 1,
                showBack: false,
                centerTitle: L10n.postFillModeTitle,
                showPrimaryAction: false,
                canProceed: false,
                isSubmitting: false,
                onBack: {},
                onClose: onClose,
                onNext: {}
            )

            ScrollView {
                VStack(alignment: .leading, spacing: spacing.spacing4) {
                    Text(L10n.postFillModeSubtitle)
                        .font(FashTypography.bodyMedium)
                        .foregroundStyle(FashColors.textSecondary)

                    if postVM.meProfile == nil && postVM.catalogLoading {
                        ProgressView()
                            .tint(FashColors.brandPrimary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 160)
                    } else {
                        FillModeOptionCard(
                            title: L10n.postFillModeFromProfileTitle,
                            subtitle: hasStyleData
                                ? L10n.postFillModeFromProfileSubtitleReady
                                : L10n.postFillModeFromProfileSubtitleEmpty,
                            detail: buildProfileStyleSummary(profile: postVM.meProfile),
                            systemImage: "square.stack.3d.up.fill",
                            action: { Task { await postVM.selectFillMode(deps: deps, mode: .fromProfileStyle) } }
                        )
                        FillModeOptionCard(
                            title: L10n.postFillModeManualTitle,
                            subtitle: L10n.postFillModeManualSubtitle,
                            detail: nil,
                            systemImage: "pencil",
                            action: { Task { await postVM.selectFillMode(deps: deps, mode: .manual) } }
                        )
                    }
                }
                .padding(.horizontal, spacing.editorialStart)
                .padding(.bottom, spacing.spacing6)
            }
        }
        .background(PostListingColors.stepCanvas)
        .task {
            await postVM.loadCatalogIfNeeded(deps: deps)
            await postVM.loadProfileForPreview(deps: deps)
        }
    }

    private var hasStyleData: Bool {
        postVM.meProfile?.hasStyleReferenceForListing() == true
    }
}

private struct FillModeOptionCard: View {
    @Environment(\.fashSpacing) private var spacing
    let title: String
    let subtitle: String
    let detail: String?
    let systemImage: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: systemImage)
                    .font(.system(size: 24))
                    .foregroundStyle(FashColors.brandPrimary)
                    .frame(width: 28, height: 28)
                VStack(alignment: .leading, spacing: 4) {
                    Text(title)
                        .font(FashTypography.titleMedium.weight(.semibold))
                        .foregroundStyle(FashColors.textPrimary)
                    Text(subtitle)
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(FashColors.textSecondary)
                        .fixedSize(horizontal: false, vertical: true)
                    if let detail, !detail.isEmpty {
                        Text(detail)
                            .font(FashTypography.labelMedium)
                            .foregroundStyle(FashColors.brandPrimary)
                            .padding(.top, 4)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(spacing.spacing4)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(PostListingColors.fieldSurface)
            .clipShape(RoundedRectangle(cornerRadius: spacing.radiusCard, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: spacing.radiusCard, style: .continuous)
                    .stroke(FashColors.outlineMuted.opacity(0.6), lineWidth: 1.5)
            }
        }
        .buttonStyle(.plain)
    }
}
