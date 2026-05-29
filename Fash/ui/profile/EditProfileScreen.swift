import SwiftUI

struct EditProfileScreen: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps
    var onDismiss: () -> Void

    @State private var viewModel = EditProfileViewModel()

    var body: some View {
        OverlayScreenHost(title: L10n.editProfileTitle, onDismiss: onDismiss) {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(FashColors.brandPrimary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: spacing.spacing4) {
                            field(L10n.editProfileDisplayNameLabel, text: $viewModel.displayName)
                            field(L10n.editProfileUsernameLabel, text: $viewModel.username)
                            field(L10n.editProfileBioLabel, text: $viewModel.bio, axis: true)
                            ReferenceSizePickerSection(
                                referenceSize: $viewModel.referenceSize,
                                genderPreference: viewModel.genderPreference,
                                label: L10n.profileSetupReferenceSizeLabel
                            )
                            aestheticSection
                            if let err = viewModel.errorMessage {
                                Text(err)
                                    .font(FashTypography.bodySmall)
                                    .foregroundStyle(FashColors.error)
                            }
                        }
                        .padding(spacing.editorialStart)
                        .padding(.bottom, spacing.spacing3)
                    }
                }
            }
            .background(FashColors.screen)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if !viewModel.isLoading {
                    saveBar
                }
            }
        }
        .task { await viewModel.load(deps: deps) }
    }

    private var saveBar: some View {
        VStack(spacing: 0) {
            Divider().overlay(FashColors.outlineMuted.opacity(0.72))
            FashPrimaryButton(
                title: L10n.editProfileSaveChanges,
                isLoading: viewModel.isSubmitting,
                enabled: viewModel.canSave
            ) {
                Task {
                    if await viewModel.save(deps: deps) {
                        onDismiss()
                    }
                }
            }
            .padding(.horizontal, spacing.editorialStart)
            .padding(.vertical, 12)
        }
        .background(FashColors.surface)
    }

    private func field(_ title: String, text: Binding<String>, axis: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(FashTypography.labelMedium)
                .foregroundStyle(FashColors.textSecondary)
            if axis {
                TextField(title, text: text, axis: .vertical)
                    .lineLimit(3...6)
                    .textFieldStyle(.roundedBorder)
            } else {
                TextField(title, text: text)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var aestheticSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.editProfileStyleLabel)
                .font(FashTypography.labelMedium)
                .foregroundStyle(FashColors.textSecondary)
            FlowLayout(spacing: 8) {
                ForEach(viewModel.tags, id: \.id) { tag in
                    let selected = viewModel.selectedTagIds.contains(tag.id)
                    Button {
                        viewModel.toggleTag(tag.id)
                    } label: {
                        Text(AestheticTagLabels.resolveLabel(
                            catalog: viewModel.tags,
                            id: tag.id,
                            rawName: tag.name,
                            preferVi: AppLocale.currentTag != AppLocale.tagEN
                        ))
                        .font(FashTypography.labelSmall)
                        .foregroundStyle(selected ? FashColors.readableOnBrandPrimary : FashColors.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(selected ? FashColors.brandPrimary : FashColors.surfaceContainer)
                        .clipShape(Capsule())
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}
