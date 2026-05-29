import SwiftUI

/// Feed-style preview card on review step — Android [CreateListingReviewCard].
struct CreateListingReviewCard: View {
    @Environment(\.fashSpacing) private var spacing
    let draft: CreateListingDraft
    let meProfile: ProfileInfo?
    let aestheticTagsById: [String: CommonAestheticTagDto]

    private var coverSlot: ListingPhotoSlotDraft? {
        draft.listingPhotoSlots.filter { $0.hasImageSelected() }.min(by: { $0.sortOrder < $1.sortOrder })
    }

    private var firstTag: String? {
        draft.selectedAestheticTagIds.first.flatMap { aestheticTagsById[$0]?.displayLabel() }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 12) {
                sellerAvatar
                VStack(alignment: .leading, spacing: 2) {
                    Text("@\(meProfile?.username ?? "user")")
                        .font(FashTypography.labelLarge.weight(.medium))
                        .foregroundStyle(FashColors.textPrimary)
                    Text(L10n.createListingSellerJustActive)
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(FashColors.textSecondary)
                }
                Spacer(minLength: 0)
                if let firstTag {
                    Text(firstTag)
                        .font(FashTypography.labelSmall)
                        .foregroundStyle(FashColors.textSecondary)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(FashColors.surfaceContainerHigh)
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                }
            }
            .padding(spacing.spacing3)

            ZStack(alignment: .bottomLeading) {
                coverImage
                    .frame(height: 280)
                    .frame(maxWidth: .infinity)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .padding(.horizontal, spacing.spacing3)
                if !draft.condition.isEmpty {
                    Text(formatConditionDisplay(draft.condition))
                        .font(FashTypography.labelSmall)
                        .foregroundStyle(FashColors.brandPrimary)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(PostListingColors.fieldSurface)
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .padding(22)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }
                Text(formatDraftPriceVnd(draft.priceVnd))
                    .font(FashTypography.titleMedium.weight(.bold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(Color.black.opacity(0.45))
                    .padding(.horizontal, spacing.spacing3)
            }

            Text(draft.title.isEmpty ? "—" : draft.title)
                .font(FashTypography.bodyLarge.weight(.medium))
                .foregroundStyle(FashColors.textPrimary)
                .lineLimit(3)
                .padding(.horizontal, spacing.spacing3)
                .padding(.vertical, spacing.spacing2)

            if !draft.brandName.isEmpty || !draft.size.isEmpty {
                Text([draft.brandName.nilIfEmpty, draft.size.nilIfEmpty.map { "\(L10n.createListingSizeLabel): \($0)" }]
                    .compactMap { $0 }
                    .joined(separator: " · "))
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
                    .lineLimit(2)
                    .padding(.horizontal, spacing.spacing3)
            }

            if !draft.description.isEmpty {
                Text(draft.description)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
                    .lineLimit(4)
                    .padding(.horizontal, spacing.spacing3)
                    .padding(.bottom, 4)
            }

            HStack(spacing: 16) {
                Label(
                    draft.countryName.isEmpty ? L10n.createListingLocationDefault : draft.countryName,
                    systemImage: "mappin.and.ellipse"
                )
                Label(L10n.createListingJustNow, systemImage: "clock")
            }
            .font(FashTypography.bodySmall)
            .foregroundStyle(FashColors.textSecondary)
            .padding(.horizontal, spacing.spacing3)
            .padding(.vertical, spacing.spacing2)

            if !draft.shippingAddressLabel.isEmpty {
                Text(draft.shippingAddressLabel)
                    .font(FashTypography.labelSmall)
                    .foregroundStyle(FashColors.brandPrimary)
                    .lineLimit(2)
                    .padding(.horizontal, spacing.spacing3)
                    .padding(.bottom, spacing.spacing2)
            }
        }
        .background(PostListingColors.fieldSurface)
        .clipShape(RoundedRectangle(cornerRadius: spacing.radiusCard, style: .continuous))
        .shadow(color: .black.opacity(0.06), radius: 4, y: 2)
    }

    @ViewBuilder
    private var sellerAvatar: some View {
        ZStack {
            Circle()
                .fill(FashColors.brandPrimary.opacity(0.2))
                .frame(width: 40, height: 40)
            if let url = meProfile?.avatarUrl.trimmingCharacters(in: .whitespaces),
               !url.isEmpty,
               let resolved = FeedImageUrl.resolveListingImageUrlOrNil(url) {
                FashAsyncImage(url: resolved, contentMode: .fill)
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
            }
        }
    }

    @ViewBuilder
    private var coverImage: some View {
        if let slot = coverSlot {
            if let remote = slot.uploadedImageUrl?.trimmingCharacters(in: .whitespaces),
               !remote.isEmpty,
               let url = FeedImageUrl.resolveListingImageUrlOrNil(remote) {
                FashAsyncImage(url: url, contentMode: .fill)
            } else if let local = slot.localImageUri, let url = URL(string: local) {
                AsyncImage(url: url) { phase in
                    if case .success(let image) = phase {
                        image.resizable().scaledToFill()
                    } else {
                        placeholderImage
                    }
                }
            } else {
                placeholderImage
            }
        } else {
            placeholderImage
        }
    }

    private var placeholderImage: some View {
        ZStack {
            PostListingColors.fieldSurface
            Text(L10n.noImage)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
        }
    }
}

func formatConditionDisplay(_ condition: String) -> String {
    ListingConditionOptions.normalizeApiToUi(condition)
}

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespaces)
        return t.isEmpty ? nil : t
    }
}
