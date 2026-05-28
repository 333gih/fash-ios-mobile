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
                            field(L10n.profileSizingRefTitle, text: $viewModel.referenceSize)
                            aestheticSection
                            if let err = viewModel.errorMessage {
                                Text(err)
                                    .font(FashTypography.bodySmall)
                                    .foregroundStyle(FashColors.error)
                            }
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
                        }
                        .padding(spacing.editorialStart)
                        .padding(.bottom, spacing.spacing6)
                    }
                }
            }
            .background(FashColors.screen)
        }
        .task { await viewModel.load(deps: deps) }
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

/// Simple flow layout for aesthetic chips.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > width, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        return CGSize(width: width, height: y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX
        var y = bounds.minY
        var rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > bounds.maxX, x > bounds.minX {
                x = bounds.minX
                y += rowHeight + spacing
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}
