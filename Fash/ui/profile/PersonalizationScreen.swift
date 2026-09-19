import PhotosUI
import SwiftUI

struct PersonalizationScreen: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps
    var onDismiss: () -> Void
    var onNavigateToExplore: () -> Void
    var onOpenEditProfile: () -> Void

    @State private var viewModel = PersonalizationViewModel()
    @State private var selectedPhoto: PhotosPickerItem?

    var body: some View {
        OverlayScreenHost(title: L10n.profilePersonalizationSection, onDismiss: onDismiss) {
            Group {
                if viewModel.isLoading && viewModel.profile == nil {
                    ProgressView()
                        .tint(FashColors.brandPrimary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    content
                }
            }
            .background(FashColors.screen)
        }
        .photosPicker(
            isPresented: $viewModel.showPhotoPicker,
            selection: $selectedPhoto,
            matching: .images
        )
        .onChange(of: selectedPhoto) { _, item in
            Task { await viewModel.handlePhotoSelection(item, deps: deps) }
        }
        .task { await viewModel.reload(deps: deps) }
    }

    private var content: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                progressHeader
                    .padding(.horizontal, spacing.editorialStart)
                    .padding(.top, spacing.spacing4)
                    .padding(.bottom, spacing.spacing5)

                stepList

                if let error = viewModel.photoError {
                    Text(error)
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(FashColors.error)
                        .padding(.horizontal, spacing.editorialStart)
                        .padding(.top, spacing.spacing3)
                }
            }
        }
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: spacing.spacing2) {
            Text(L10n.personalizationSubtitle)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(FashColors.outlineMuted.opacity(0.2))
                    Capsule()
                        .fill(FashColors.brandPrimary)
                        .frame(width: geo.size.width * viewModel.completionState.fraction)
                        .animation(FashMotion.progressFill, value: viewModel.completionState.fraction)
                }
            }
            .frame(height: 6)

            Text(L10n.personalizationProgressFormat(
                viewModel.completionState.completedSteps,
                viewModel.completionState.totalSteps
            ))
            .font(FashTypography.labelMedium.weight(.semibold))
            .foregroundStyle(FashColors.brandPrimary)
        }
    }

    private var stepList: some View {
        VStack(spacing: 0) {
            ForEach(PersonalizationStep.allCases, id: \.self) { step in
                stepRow(step)
                Divider()
                    .padding(.leading, spacing.editorialStart + 52)
            }
        }
    }

    @ViewBuilder
    private func stepRow(_ step: PersonalizationStep) -> some View {
        let done = viewModel.isStepCompleted(step)
        Button {
            handleStepTap(step)
        } label: {
            HStack(spacing: spacing.spacing3) {
                ZStack {
                    Circle()
                        .fill(done ? FashColors.brandPrimary : FashColors.surfaceContainer)
                        .frame(width: 36, height: 36)
                    if done {
                        Image(systemName: "checkmark")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(FashColors.readableOnBrandPrimary)
                    } else {
                        Image(systemName: step.icon)
                            .font(.system(size: 15, weight: .medium))
                            .foregroundStyle(FashColors.textSecondary)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(step.title)
                        .font(FashTypography.labelLarge)
                        .foregroundStyle(FashColors.textPrimary)
                    Text(done ? L10n.personalizationStepDone : step.subtitle)
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(done ? FashColors.brandPrimary : FashColors.textSecondary)
                }

                Spacer()

                if !done {
                    if step == .photo && viewModel.isUploadingPhoto {
                        ProgressView()
                            .scaleEffect(0.8)
                            .tint(FashColors.brandPrimary)
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(FashColors.outlineMuted)
                    }
                }
            }
            .padding(.horizontal, spacing.editorialStart)
            .padding(.vertical, spacing.spacing3)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(done || (step == .photo && viewModel.isUploadingPhoto))
    }

    private func handleStepTap(_ step: PersonalizationStep) {
        switch step {
        case .photo:
            viewModel.showPhotoPicker = true
        case .tags, .sizing, .bio:
            onOpenEditProfile()
        case .following:
            onNavigateToExplore()
        }
    }
}
