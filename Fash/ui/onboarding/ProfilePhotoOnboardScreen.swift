import PhotosUI
import SwiftUI

struct ProfilePhotoOnboardScreen: View {
    @Environment(AppDependencies.self) private var deps
    @Bindable var viewModel: OnboardingViewModel
    var onStepComplete: () -> Void

    @State private var pickerItem: PhotosPickerItem?

    var body: some View {
        VStack(spacing: 0) {
            OnboardingStepHeader(
                title: L10n.onboardingProfilePhotoTitle,
                displayProgressStep: viewModel.uiProgressStep,
                progressTotal: viewModel.progressTotalSteps,
                onBack: { _ = viewModel.goBack(deps: deps) }
            )
            .padding(.horizontal, 8)
            .padding(.top, 8)

            Spacer()

            VStack(spacing: 16) {
                Text(L10n.onboardingProfilePhotoSubtitle)
                    .font(FashTypography.bodyMedium)
                    .foregroundStyle(FashColors.textSecondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                ZStack(alignment: .bottomTrailing) {
                    Group {
                        if let url = viewModel.avatarUrl, !url.isEmpty {
                            FashAsyncImage(url: url)
                                .clipShape(Circle())
                        } else {
                            FashDefaultProfileAvatar()
                        }
                    }
                    .frame(width: 140, height: 140)
                    .overlay {
                        Circle()
                            .stroke(FashColors.outlineMuted.opacity(0.45), lineWidth: 2)
                    }

                    if viewModel.avatarUploading {
                        ProgressView()
                            .tint(FashColors.brandPrimary)
                            .frame(width: 140, height: 140)
                    }

                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(FashColors.readableOnBrandPrimary)
                            .frame(width: 44, height: 44)
                            .background(FashColors.brandPrimary)
                            .clipShape(Circle())
                    }
                    .disabled(viewModel.avatarUploading || viewModel.isSubmitting)
                }

                Text(L10n.onboardingProfilePhotoHint)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            HStack {
                Spacer()
                Button(L10n.onboardingSkip) {
                    viewModel.skipProfilePhoto(deps: deps, onSuccess: onStepComplete)
                }
                .font(FashTypography.labelLarge)
                .foregroundStyle(FashColors.brandPrimary)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 12)

            FashPrimaryButton(
                title: L10n.onboardingContinue,
                isLoading: viewModel.isSubmitting,
                enabled: viewModel.canContinueFromProfilePhoto() && !viewModel.isSubmitting && !viewModel.avatarUploading
            ) {
                viewModel.completeProfilePhotoStep(deps: deps, onSuccess: onStepComplete)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .background(FashColors.screen)
        .onChange(of: pickerItem) { _, item in
            guard let item else { return }
            Task {
                if let data = try? await item.loadTransferable(type: Data.self), !data.isEmpty {
                    let mime = item.supportedContentTypes.first?.preferredMIMEType ?? "image/jpeg"
                    viewModel.setAvatarFromBytes(data, mimeType: mime, deps: deps)
                }
                pickerItem = nil
            }
        }
    }
}
