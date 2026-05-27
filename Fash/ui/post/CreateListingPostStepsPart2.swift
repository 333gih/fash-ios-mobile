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
                switch step {
                case 6: sizeStep
                case 7: photosStep
                case 8: priceStep
                case 9: shippingStep
                case 10: reviewStep
                default: EmptyView()
                }
            }
            .padding(spacing.spacing4)
        }
    }

    private var sizeStep: some View {
        VStack(alignment: .leading, spacing: spacing.spacing3) {
            Text(L10n.postStepMeasure)
                .font(FashTypography.titleMedium)
            TextField(L10n.createListingSizeLabel, text: sizeBinding)
                .textFieldStyle(.roundedBorder)
            measurementField(L10n.postMeasurementChest, binding: chestBinding)
            measurementField(L10n.postMeasurementLength, binding: lengthBinding)
        }
    }

    private func measurementField(_ label: String, binding: Binding<String>) -> some View {
        HStack {
            Text(label)
                .font(FashTypography.bodyMedium)
            TextField("0", text: binding)
                .keyboardType(.decimalPad)
                .textFieldStyle(.roundedBorder)
        }
    }

    private var photosStep: some View {
        VStack(alignment: .leading, spacing: spacing.spacing3) {
            Text(L10n.postStepPhotos)
                .font(FashTypography.titleMedium)
            if postVM.listingPhotoSetupLoading {
                ProgressView()
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
            PhotosPicker(selection: photoPickerBinding(for: slot.stepKey), matching: .images) {
                HStack {
                    Image(systemName: slot.hasImageSelected() ? "checkmark.circle.fill" : "photo.badge.plus")
                    Text(slot.hasImageSelected() ? L10n.createListingAddPhoto : L10n.createListingAddPhotos)
                }
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.brandPrimary)
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
        VStack(alignment: .leading, spacing: spacing.spacing3) {
            Text(L10n.postStepPrice)
                .font(FashTypography.titleMedium)
            TextField(L10n.createListingPricePlaceholder, text: priceBinding)
                .keyboardType(.numberPad)
                .textFieldStyle(.roundedBorder)
            Toggle(L10n.postAcceptOffers, isOn: acceptOffersBinding)
            Toggle(L10n.postAutoPriceDrop, isOn: autoDropBinding)
            if postVM.draft.autoPriceDropEnabled {
                TextField(L10n.postFloorPrice, text: floorBinding)
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
            }
        }
    }

    private var shippingStep: some View {
        VStack(alignment: .leading, spacing: spacing.spacing3) {
            Text(L10n.postStepShipping)
                .font(FashTypography.titleMedium)
            Toggle(L10n.listingCommitmentTitle, isOn: commitmentBinding)
            if !postVM.draft.shippingAddressLabel.isEmpty {
                Text(postVM.draft.shippingAddressLabel)
                    .font(FashTypography.bodyMedium)
            }
            ForEach(postVM.localAddresses, id: \.id) { addr in
                Button(addr.formattedSingleLine()) {
                    postVM.selectShippingAddressForListing(deps: deps, addressId: addr.id)
                }
                .foregroundStyle(FashColors.textPrimary)
            }
            Button(L10n.postAddShippingAddress, action: onAddAddress)
                .font(FashTypography.labelLarge)
                .foregroundStyle(FashColors.brandPrimary)
        }
    }

    private var reviewStep: some View {
        VStack(alignment: .leading, spacing: spacing.spacing3) {
            Text(L10n.postStepReview)
                .font(FashTypography.titleMedium)
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
