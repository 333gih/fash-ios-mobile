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
        ScrollView {
            VStack(alignment: .leading, spacing: spacing.spacing4) {
                stepTitle
                switch step {
                case 6: sizeStep
                case 7: photosStep
                case 8: priceStep
                case 9: shippingStep
                case 10: reviewStep
                default: EmptyView()
                }
            }
            .padding(.horizontal, spacing.editorialStart)
            .padding(.bottom, spacing.spacing6)
        }
        .background(PostListingColors.stepCanvas)
    }

    @ViewBuilder
    private var stepTitle: some View {
        let title: String = switch step {
        case 6: L10n.postStepMeasure
        case 7: L10n.postStepPhotos
        case 8: L10n.postStepPrice
        case 9: L10n.postStepShipping
        case 10: L10n.postStepReview
        default: ""
        }
        if !title.isEmpty {
            Text(title)
                .font(FashTypography.titleLarge.weight(.semibold))
                .foregroundStyle(FashColors.textPrimary)
        }
    }

    private var sizeStep: some View {
        PostStepSectionCard {
            TextField(L10n.createListingSizeLabel, text: sizeBinding)
                .padding(spacing.spacing3)
                .background(FashColors.surfaceContainerLow)
                .clipShape(RoundedRectangle(cornerRadius: spacing.radiusSoftMin, style: .continuous))
            measurementField(L10n.postMeasurementChest, binding: chestBinding)
            measurementField(L10n.postMeasurementLength, binding: lengthBinding)
        }
    }

    private func measurementField(_ label: String, binding: Binding<String>) -> some View {
        HStack {
            Text(label)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
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
            Text(slot.label)
                .font(FashTypography.labelLarge)
                .foregroundStyle(FashColors.textPrimary)
            PhotosPicker(selection: photoPickerBinding(for: slot.stepKey), matching: .images) {
                HStack(spacing: spacing.spacing2) {
                    Image(systemName: slot.hasImageSelected() ? "checkmark.circle.fill" : "photo.badge.plus")
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

    private func photoPickerBinding(for stepKey: String) -> Binding<PhotosPickerItem?> {
        Binding(
            get: { nil },
            set: { item in
                guard let item else { return }
                Task {
                    if let data = try? await item.loadTransferable(type: Data.self),
                       let tmp = writeTempImage(data) {
                        postVM.setListingPhotoForStep(stepKey: stepKey, uriString: tmp.absoluteString)
                    }
                }
            }
        )
    }

    private var priceStep: some View {
        PostStepSectionCard {
            TextField(L10n.createListingPricePlaceholder, text: priceBinding)
                .keyboardType(.numberPad)
                .padding(spacing.spacing3)
                .background(FashColors.surfaceContainerLow)
                .clipShape(RoundedRectangle(cornerRadius: spacing.radiusSoftMin, style: .continuous))
            Toggle(L10n.postAcceptOffers, isOn: acceptOffersBinding)
            Toggle(L10n.postAutoPriceDrop, isOn: autoDropBinding)
            if postVM.draft.autoPriceDropEnabled {
                TextField(L10n.postFloorPrice, text: floorBinding)
                    .keyboardType(.numberPad)
                    .padding(spacing.spacing3)
                    .background(FashColors.surfaceContainerLow)
                    .clipShape(RoundedRectangle(cornerRadius: spacing.radiusSoftMin, style: .continuous))
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
                let selected = postVM.draft.shippingAddressId == addr.id
                Button(addr.formattedSingleLine()) {
                    postVM.selectShippingAddressForListing(deps: deps, addressId: addr.id)
                }
                .font(FashTypography.bodyMedium.weight(selected ? .semibold : .regular))
                .foregroundStyle(selected ? FashColors.brandPrimary : FashColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            Button(L10n.postAddShippingAddress, action: onAddAddress)
                .font(FashTypography.labelLarge)
                .foregroundStyle(FashColors.brandPrimary)
        }
    }

    private var reviewStep: some View {
        PostStepSectionCard {
            reviewRow(L10n.createListingCategoryLabel, postVM.draft.categoryName)
            reviewRow(L10n.createListingTitleLabel, postVM.draft.title)
            reviewRow(L10n.createListingPriceLabel, postVM.draft.priceVnd)
            reviewRow(L10n.postStepShipping, postVM.draft.shippingAddressLabel)
        }
    }

    private func reviewRow(_ label: String, _ value: String) -> some View {
        HStack(alignment: .top) {
            Text(label)
                .font(FashTypography.bodySmall)
                .foregroundStyle(FashColors.textSecondary)
                .frame(width: 100, alignment: .leading)
            Text(value.isEmpty ? "—" : value)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textPrimary)
            Spacer()
        }
    }

    private var sizeBinding: Binding<String> {
        Binding(get: { postVM.draft.size }, set: { v in postVM.updateDraft { $0.size = v } })
    }
    private var chestBinding: Binding<String> {
        Binding(get: { postVM.draft.measurementChest }, set: { v in postVM.updateDraft { $0.measurementChest = v } })
    }
    private var lengthBinding: Binding<String> {
        Binding(get: { postVM.draft.measurementLength }, set: { v in postVM.updateDraft { $0.measurementLength = v } })
    }
    private var priceBinding: Binding<String> {
        Binding(get: { postVM.draft.priceVnd }, set: { v in postVM.updateDraft { $0.priceVnd = v } })
    }
    private var floorBinding: Binding<String> {
        Binding(get: { postVM.draft.floorPriceVnd }, set: { v in postVM.updateDraft { $0.floorPriceVnd = v } })
    }
    private var acceptOffersBinding: Binding<Bool> {
        Binding(get: { postVM.draft.acceptOffers }, set: { v in postVM.updateDraft { $0.acceptOffers = v } })
    }
    private var autoDropBinding: Binding<Bool> {
        Binding(get: { postVM.draft.autoPriceDropEnabled }, set: { v in postVM.updateDraft { $0.autoPriceDropEnabled = v } })
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
