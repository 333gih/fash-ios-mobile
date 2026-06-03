import SwiftUI
import PhotosUI

struct CreateListingPostStepsPart2: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps
    @Bindable var postVM: PostViewModel
    @Bindable var addressVM: AddressBookViewModel
    let step: Int
    var onAddAddress: () -> Void

    var body: some View {
        Group {
            if step == 11 {
                reviewStep
            } else if step == 6 {
                CreateListingWearSeasonStep(postVM: postVM)
            } else {
                PostStepScrollContent(bottomNotice: bottomNotice) {
                    stepTitle
                    switch step {
                    case 7: sizeStep
                    case 8: photosStep
                    case 9: priceStep
                    case 10: shippingStep
                    default: EmptyView()
                    }
                }
            }
        }
        .background(PostListingColors.stepCanvas)
    }

    private var bottomNotice: String? {
        switch step {
        case 7: return L10n.postMeasureNoticeCombined
        case 8: return L10n.postHintPhotos
        case 9: return L10n.postHintPrice
        case 10: return L10n.postHintShipping
        default: return nil
        }
    }

    @ViewBuilder
    private var stepTitle: some View {
        let title: String = switch step {
        case 7: L10n.postStepMeasure
        case 8: L10n.postStepPhotos
        case 9: L10n.postStepPrice
        case 10: L10n.postStepShipping
        default: ""
        }
        if !title.isEmpty {
            Text(title)
                .font(FashTypography.titleLarge.weight(.semibold))
                .foregroundStyle(FashColors.textPrimary)
        }
    }

    private var sizeStep: some View {
        VStack(alignment: .leading, spacing: spacing.spacing3) {
            Text(L10n.postListingSizingSubtitle)
                .font(FashTypography.bodySmall)
                .foregroundStyle(FashColors.textSecondary)
            if postVM.draft.fillMode == .fromProfileStyle,
               !postVM.draft.size.isEmpty || hasAnyMeasurement(postVM.draft) || !postVM.draft.genderTarget.isEmpty {
                PostProfilePrefilledBanner()
            }
            PostStepSectionCard {
                Text(L10n.postStepGenderTarget + " (\(L10n.postListingSizingGenderRecommended))")
                    .font(FashTypography.labelLarge.weight(.medium))
                Text(L10n.postListingSizingGenderHint)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
                FlowPillsGrid {
                    ForEach([
                        ("women", L10n.genderTargetWomen),
                        ("men", L10n.genderTargetMen),
                        ("unisex", L10n.genderTargetUnisex),
                        ("kids", L10n.genderTargetKids),
                    ], id: \.0) { value, label in
                        PostSelectablePill(text: label, selected: postVM.draft.genderTarget == value) {
                            postVM.updateDraft { $0.genderTarget = $0.genderTarget == value ? "" : value }
                        }
                    }
                }
            }
            PostStepSectionCard {
                PostListingOutlinedField(label: L10n.createListingSizeLabel, text: sizeBinding)
                measureRow(L10n.postMeasurementChest, binding: chestBinding)
                measureRow(L10n.postMeasurementLength, binding: lengthBinding)
                measureRow(L10n.postMeasurementHem, binding: hemBinding)
                measureRow(L10n.postMeasurementShoulders, binding: shouldersBinding)
                measureRow(L10n.postMeasurementSleeve, binding: sleeveBinding)
                Picker(L10n.postMeasureSectionUnit, selection: unitBinding) {
                    Text(L10n.postUnitCm).tag("cm")
                    Text(L10n.postUnitIn).tag("in")
                }
                .pickerStyle(.segmented)
            }
        }
        .task { await postVM.loadProfileForPreview(deps: deps) }
    }

    private func measureRow(_ label: String, binding: Binding<String>) -> some View {
        HStack(spacing: 12) {
            Text(label)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
                .frame(width: 120, alignment: .leading)
            TextField("0", text: binding)
                .keyboardType(.decimalPad)
                .padding(spacing.spacing3)
                .background(FashColors.surfaceContainerLow)
                .clipShape(RoundedRectangle(cornerRadius: spacing.radiusSoftMin, style: .continuous))
        }
    }

    private var photosStep: some View {
        PostStepSectionCard {
            if postVM.listingPhotoSetupLoading {
                ProgressView().tint(FashColors.brandPrimary)
            }
            ForEach(postVM.draft.listingPhotoSlots) { slot in
                photoSlotRow(slot)
            }
        }
        .task { await postVM.ensureListingPhotoSlotsLoaded(deps: deps) }
    }

    private func photoSlotRow(_ slot: ListingPhotoSlotDraft) -> some View {
        VStack(alignment: .leading, spacing: spacing.spacing2) {
            HStack {
                Text(slot.displayLabel())
                    .font(FashTypography.labelLarge)
                if slot.required {
                    Text("*")
                        .foregroundStyle(FashColors.error)
                }
                Spacer()
                if slot.hasImageSelected() {
                    Button(L10n.createListingCancel) {
                        postVM.clearListingPhotoForStep(stepKey: slot.stepKey)
                    }
                    .font(FashTypography.labelSmall)
                    .foregroundStyle(FashColors.textSecondary)
                }
            }
            photoPreview(slot)
            PhotosPicker(selection: photoPickerBinding(for: slot.stepKey), matching: .images) {
                HStack(spacing: spacing.spacing2) {
                    Image(systemName: slot.hasImageSelected() ? "arrow.triangle.2.circlepath" : "photo.badge.plus")
                    Text(slot.hasImageSelected() ? L10n.createListingAddPhoto : L10n.createListingAddPhotos)
                }
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.brandPrimary)
                .padding(spacing.spacing3)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(FashColors.surfaceContainerLow)
                .clipShape(RoundedRectangle(cornerRadius: spacing.radiusSoftMin, style: .continuous))
            }
        }
    }

    @ViewBuilder
    private func photoPreview(_ slot: ListingPhotoSlotDraft) -> some View {
        if let remote = slot.uploadedImageUrl,
           let url = FeedImageUrl.resolveListingImageUrlOrNil(remote) {
            FashAsyncImage(url: url, contentMode: .fill)
                .frame(height: 120)
                .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        } else if let local = slot.localImageUri, let url = URL(string: local) {
            AsyncImage(url: url) { phase in
                if case .success(let img) = phase {
                    img.resizable().scaledToFill()
                }
            }
            .frame(height: 120)
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        }
    }

    private var priceStep: some View {
        VStack(alignment: .leading, spacing: spacing.spacing3) {
            Text(L10n.postPriceStepSubtitle)
                .font(FashTypography.bodySmall)
                .foregroundStyle(FashColors.textSecondary)
            Text(L10n.postPriceVndRangeHint)
                .font(FashTypography.labelSmall)
                .foregroundStyle(FashColors.textSecondary)
            PostListingVndPriceField(label: L10n.createListingPriceLabel, digits: priceDigitsBinding)
            Toggle(L10n.postAcceptOffers, isOn: acceptOffersBinding)
            Toggle(L10n.postAutoPriceDrop, isOn: autoDropBinding)
            if postVM.draft.autoPriceDropEnabled {
                PostListingVndPriceField(label: L10n.postFloorPrice, digits: floorDigitsBinding)
                PostListingOutlinedField(
                    label: L10n.postDropPercent,
                    text: dropPercentBinding,
                    keyboard: .numberPad
                )
            }
        }
    }

    private var shippingStep: some View {
        PostStepSectionCard {
            Toggle(L10n.listingCommitmentTitle, isOn: commitmentBinding)
            if !postVM.draft.shippingAddressLabel.isEmpty {
                Text(postVM.draft.shippingAddressLabel)
                    .font(FashTypography.bodyMedium)
                    .foregroundStyle(FashColors.textPrimary)
            }
            ForEach(postVM.localAddresses, id: \.id) { addr in
                PostSelectableListRow(
                    text: addr.labelForDraft(),
                    subtitle: addr.formattedSingleLine(),
                    selected: postVM.draft.shippingAddressId == addr.id
                ) {
                    postVM.selectShippingAddressForListing(deps: deps, addressId: addr.id)
                }
            }
            Button(L10n.postAddShippingAddress, action: onAddAddress)
                .font(FashTypography.labelLarge)
                .foregroundStyle(FashColors.brandPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .task {
            await postVM.loadShippingAddresses(deps: deps)
            postVM.applyDefaultShippingIfNeeded(deps: deps)
        }
    }

    private var reviewStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacing.spacing4) {
                Text(L10n.postStepReview)
                    .font(FashTypography.titleLarge.weight(.semibold))
                Text(L10n.postReviewBuyerPageSubtitle)
                    .font(FashTypography.bodyMedium)
                    .foregroundStyle(FashColors.textSecondary)
                CreateListingBuyerPreview(
                    draft: postVM.draft,
                    meProfile: postVM.meProfile,
                    aestheticTagsById: postVM.aestheticTagsById,
                    onEditStep: { postVM.goToStep($0) }
                )
                PostFlowNoticeCard(text: L10n.createListingLegalMid, title: L10n.postReviewNoticeTitle)
            }
            .padding(.horizontal, spacing.editorialStart)
            .padding(.bottom, spacing.spacing6)
        }
        .task {
            await postVM.loadProfileForPreview(deps: deps)
            await postVM.loadShippingAddresses(deps: deps)
        }
    }

    private var priceDigitsBinding: Binding<String> {
        Binding(
            get: { postVM.draft.priceVnd.filter(\.isNumber) },
            set: { v in postVM.updateDraft { $0.priceVnd = String(v.filter(\.isNumber).prefix(12)) } }
        )
    }

    private var floorDigitsBinding: Binding<String> {
        Binding(
            get: { postVM.draft.floorPriceVnd.filter(\.isNumber) },
            set: { v in postVM.updateDraft { $0.floorPriceVnd = String(v.filter(\.isNumber).prefix(12)) } }
        )
    }

    private var dropPercentBinding: Binding<String> {
        Binding(
            get: { postVM.draft.priceDropPercentInput },
            set: { v in postVM.updateDraft { $0.priceDropPercentInput = String(v.filter(\.isNumber).prefix(2)) } }
        )
    }

    private func photoPickerBinding(for stepKey: String) -> Binding<PhotosPickerItem?> {
        Binding(
            get: { nil },
            set: { item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let tmp = writeTempImage(data) {
                        let size = ListingImagePixelSize.fromImageData(data)
                        postVM.setListingPhotoForStep(
                            stepKey: stepKey,
                            uriString: tmp.absoluteString,
                            width: size?.width,
                            height: size?.height
                        )
                    }
                }
            }
        )
    }

    private var sizeBinding: Binding<String> {
        Binding(get: { postVM.draft.size }, set: { v in postVM.updateDraft { $0.size = String(v.prefix(20)) } })
    }
    private var chestBinding: Binding<String> {
        Binding(get: { postVM.draft.measurementChest }, set: { v in postVM.updateDraft { $0.measurementChest = v } })
    }
    private var lengthBinding: Binding<String> {
        Binding(get: { postVM.draft.measurementLength }, set: { v in postVM.updateDraft { $0.measurementLength = v } })
    }
    private var hemBinding: Binding<String> {
        Binding(get: { postVM.draft.measurementHem }, set: { v in postVM.updateDraft { $0.measurementHem = v } })
    }
    private var shouldersBinding: Binding<String> {
        Binding(get: { postVM.draft.measurementShoulders }, set: { v in postVM.updateDraft { $0.measurementShoulders = v } })
    }
    private var sleeveBinding: Binding<String> {
        Binding(get: { postVM.draft.measurementSleeveLength }, set: { v in postVM.updateDraft { $0.measurementSleeveLength = v } })
    }
    private var unitBinding: Binding<String> {
        Binding(get: { postVM.draft.measurementUnit }, set: { v in postVM.updateDraft { $0.measurementUnit = v } })
    }
    private var acceptOffersBinding: Binding<Bool> {
        Binding(get: { postVM.draft.acceptOffers }, set: { v in postVM.updateDraft { $0.acceptOffers = v } })
    }
    private var autoDropBinding: Binding<Bool> {
        Binding(
            get: { postVM.draft.autoPriceDropEnabled },
            set: { on in
                postVM.updateDraft {
                    $0.autoPriceDropEnabled = on
                    if on, $0.priceDropPercentInput.filter(\.isNumber).isEmpty {
                        $0.priceDropPercentInput = "10"
                    }
                }
            }
        )
    }
    private var commitmentBinding: Binding<Bool> {
        Binding(get: { postVM.draft.onsiteInspectionCommitment }, set: { v in postVM.updateDraft { $0.onsiteInspectionCommitment = v } })
    }
}

private func writeTempImage(_ data: Data) -> URL? {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString + ".jpg")
    do {
        try data.write(to: url)
        return url
    } catch {
        return nil
    }
}
