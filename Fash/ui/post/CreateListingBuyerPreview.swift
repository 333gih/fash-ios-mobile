import SwiftUI

/// Buyer-facing preview on step 10 — Android [CreateListingBuyerPreview].
struct CreateListingBuyerPreview: View {
    @Environment(\.fashSpacing) private var spacing
    let draft: CreateListingDraft
    let meProfile: ProfileInfo?
    let aestheticTagsById: [String: CommonAestheticTagDto]
    let onEditStep: (Int) -> Void

    private var imageUrls: [URL] {
        draft.listingPhotoSlots.sorted { $0.sortOrder < $1.sortOrder }.compactMap { slot -> URL? in
            if let remote = slot.uploadedImageUrl?.trimmingCharacters(in: .whitespaces), !remote.isEmpty {
                return FeedImageUrl.resolveListingImageUrlOrNil(remote).flatMap { URL(string: $0) }
                    ?? URL(string: remote)
            }
            if let local = slot.localImageUri { return URL(string: local) }
            return nil
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: spacing.spacing4) {
            banner
            Text(L10n.postReviewFeedPreviewHeading)
                .font(FashTypography.labelLarge.weight(.semibold))
                .foregroundStyle(FashColors.textSecondary)
            CreateListingReviewCard(
                draft: draft,
                meProfile: meProfile,
                aestheticTagsById: aestheticTagsById
            )
            Text(L10n.postReviewDetailPreviewHeading)
                .font(FashTypography.labelLarge.weight(.semibold))
                .foregroundStyle(FashColors.textSecondary)
            detailPreviewCard
        }
    }

    private var banner: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(L10n.postReviewBuyerBannerTitle)
                .font(FashTypography.titleSmall.weight(.semibold))
                .foregroundStyle(FashColors.textPrimary)
            Text(L10n.postReviewBuyerBannerSubtitle)
                .font(FashTypography.bodySmall)
                .foregroundStyle(FashColors.textSecondary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FashColors.brandPrimary.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private var detailPreviewCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            if !imageUrls.isEmpty {
                TabView {
                    ForEach(Array(imageUrls.enumerated()), id: \.offset) { _, url in
                        AsyncImage(url: url) { phase in
                            if case .success(let img) = phase {
                                img.resizable().scaledToFill()
                            } else {
                                Color.gray.opacity(0.15)
                            }
                        }
                        .frame(height: 280)
                        .clipped()
                    }
                }
                .frame(height: 280)
                .tabViewStyle(.page(indexDisplayMode: imageUrls.count > 1 ? .automatic : .never))
                PreviewEditRow(
                    label: L10n.postStepPhotos,
                    value: L10n.postReviewPhotoCount(imageUrls.count),
                    onEdit: { onEditStep(7) }
                )
                Divider().padding(.vertical, 8)
            }

            Text(draft.title.isEmpty ? L10n.postReviewMissingTitle : draft.title)
                .font(FashTypography.titleMedium.weight(.semibold))
                .foregroundStyle(draft.title.isEmpty ? FashColors.error : FashColors.textPrimary)
                .lineLimit(2)
            Text(formatDraftPriceVnd(draft.priceVnd))
                .font(FashTypography.titleLarge.weight(.bold))
                .foregroundStyle(FashColors.brandPrimary)
                .padding(.top, 6)

            previewRow(L10n.createListingCategoryLabel, draft.categoryName.isEmpty ? L10n.postReviewNotSet : draft.categoryName, step: 1, missing: draft.categoryId.isEmpty)
            previewRow(L10n.createListingConditionLabel, formatConditionDisplay(draft.condition).isEmpty ? L10n.postReviewNotSet : formatConditionDisplay(draft.condition), step: 5, missing: draft.condition.isEmpty)
            previewRow(L10n.createListingBrandLabel, draft.brandName.isEmpty ? L10n.postReviewOptionalEmpty : draft.brandName, step: 3)
            previewRow(L10n.createListingSizeLabel, draft.size.isEmpty ? L10n.postReviewOptionalEmpty : draft.size, step: 6)
            if !draft.color.isEmpty {
                previewRow(L10n.postStepColor, draft.color, step: 5)
            }
            if !draft.genderTarget.isEmpty {
                previewRow(L10n.postStepGenderTarget, genderTargetLabel(draft.genderTarget), step: 6)
            }
            previewRow(L10n.postStepCountry, draft.countryName.isEmpty ? L10n.postReviewOptionalEmpty : draft.countryName, step: 4)
            previewRow(L10n.postStepPrice, formatDraftPriceVnd(draft.priceVnd), step: 8, missing: draft.priceVnd.trimmingCharacters(in: .whitespaces).isEmpty)
            previewRow(L10n.postStepShipping, draft.shippingAddressLabel.isEmpty ? L10n.postReviewNotSet : draft.shippingAddressLabel, step: 9, missing: draft.shippingAddressLabel.isEmpty)

            if !draft.description.isEmpty {
                Text(L10n.productSectionDescription)
                    .font(FashTypography.labelLarge.weight(.semibold))
                    .padding(.top, 8)
                Text(draft.description)
                    .font(FashTypography.bodyMedium)
                    .foregroundStyle(FashColors.textSecondary)
                editLink(step: 5)
            }

            if hasAnyMeasurement(draft) {
                Text(L10n.productSectionMeasurements)
                    .font(FashTypography.labelLarge.weight(.semibold))
                    .padding(.top, 8)
                ForEach(measurementPreviewLines(draft), id: \.0) { label, value in
                    HStack {
                        Text(label).font(FashTypography.bodySmall).foregroundStyle(FashColors.textSecondary)
                        Spacer()
                        Text(value).font(FashTypography.bodySmall)
                    }
                }
                editLink(step: 6)
            }

            let tags = draft.selectedAestheticTagIds.compactMap { aestheticTagsById[$0]?.displayLabel() }
            if !tags.isEmpty {
                Text(L10n.productSectionStyle)
                    .font(FashTypography.labelLarge.weight(.semibold))
                    .padding(.top, 8)
                FlowLayout(spacing: 8) {
                    ForEach(tags, id: \.self) { tag in
                        Text(tag)
                            .font(FashTypography.labelSmall)
                            .foregroundStyle(FashColors.textSecondary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(FashColors.surfaceContainerHigh)
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                }
                editLink(step: 2)
            }
        }
        .padding(spacing.spacing3)
        .background(PostListingColors.fieldSurface)
        .clipShape(RoundedRectangle(cornerRadius: spacing.radiusCard, style: .continuous))
    }

    private func previewRow(_ label: String, _ value: String, step: Int, missing: Bool = false) {
        PreviewEditRow(label: label, value: value, highlightMissing: missing, onEdit: { onEditStep(step) })
    }

    private func editLink(step: Int) {
        Button(L10n.postReviewEditSection) { onEditStep(step) }
            .font(FashTypography.labelLarge.weight(.semibold))
            .foregroundStyle(FashColors.brandPrimary)
            .padding(.top, 6)
    }
}

private struct PreviewEditRow: View {
    let label: String
    let value: String
    var highlightMissing: Bool = false
    let onEdit: () -> Void

    var body: some View {
        Button(action: onEdit) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(FashTypography.labelSmall)
                        .foregroundStyle(FashColors.textSecondary)
                    Text(value)
                        .font(FashTypography.bodyMedium)
                        .foregroundStyle(highlightMissing ? FashColors.error : FashColors.textPrimary)
                        .lineLimit(2)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundStyle(FashColors.brandPrimary)
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
    }
}

private func measurementPreviewLines(_ draft: CreateListingDraft) -> [(String, String)] {
    let unit = draft.measurementUnit.lowercased() == "in" ? L10n.postUnitIn : L10n.postUnitCm
    var lines: [(String, String)] = []
    if !draft.measurementHem.isEmpty { lines.append((L10n.profileSetupMeasurementHem, "\(draft.measurementHem) \(unit)")) }
    if !draft.measurementChest.isEmpty { lines.append((L10n.profileSetupMeasurementChest, "\(draft.measurementChest) \(unit)")) }
    if !draft.measurementLength.isEmpty { lines.append((L10n.profileSetupMeasurementLength, "\(draft.measurementLength) \(unit)")) }
    if !draft.measurementShoulders.isEmpty { lines.append((L10n.profileSetupMeasurementShoulders, "\(draft.measurementShoulders) \(unit)")) }
    if !draft.measurementSleeveLength.isEmpty { lines.append((L10n.profileSetupMeasurementSleeve, "\(draft.measurementSleeveLength) \(unit)")) }
    return lines
}

/// Simple flow layout for tag chips.
private struct FlowLayout: Layout {
    var spacing: CGFloat = 8
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = arrange(proposal: proposal, subviews: subviews)
        return result.size
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = arrange(proposal: proposal, subviews: subviews)
        for (index, origin) in result.origins.enumerated() {
            subviews[index].place(at: CGPoint(x: bounds.minX + origin.x, y: bounds.minY + origin.y), proposal: .unspecified)
        }
    }
    private func arrange(proposal: ProposedViewSize, subviews: Subviews) -> (size: CGSize, origins: [CGPoint]) {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0
        var y: CGFloat = 0
        var rowHeight: CGFloat = 0
        var origins: [CGPoint] = []
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x + size.width > maxWidth, x > 0 {
                x = 0
                y += rowHeight + spacing
                rowHeight = 0
            }
            origins.append(CGPoint(x: x, y: y))
            rowHeight = max(rowHeight, size.height)
            x += size.width + spacing
        }
        return (CGSize(width: maxWidth, height: y + rowHeight), origins)
    }
}

private extension CommonAestheticTagDto {
    func displayLabel() -> String {
        let d = displayName.trimmingCharacters(in: .whitespaces)
        return d.isEmpty ? name : d
    }
}
