import SwiftUI

struct EditListingScreen: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps

    var listingId: String
    var onDismiss: () -> Void

    @State private var viewModel = EditListingViewModel()
    @State private var showDeleteDialog = false
    @State private var sharePayload: FashSharePayload?

    var body: some View {
        OverlayScreenHost(title: L10n.editListingScreenTitle, onDismiss: onDismiss, trailing: {
            if viewModel.detail != nil {
                Button {
                    guard let d = viewModel.detail else { return }
                    viewModel.reportShare(listingId: d.id, title: d.title, deps: deps)
                    let web = AppEnvironment.listingShareURL(listingId: d.id)
                    let fashUri = ListingDeepLinks.fashListingURL(listingId: d.id)?.absoluteString ?? ""
                    let title = d.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                        ? L10n.productDetailTitle
                        : d.title
                    sharePayload = FashSharePayload(items: [L10n.shareListingSubject, L10n.shareListingText(title, web, fashUri)])
                } label: {
                    Image(systemName: "square.and.arrow.up")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(FashColors.brandPrimary)
                        .frame(width: 44, height: 44)
                }
            }
        }) {
            Group {
                if viewModel.isLoading && viewModel.detail == nil {
                    ProgressView()
                        .tint(FashColors.brandPrimary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let err = viewModel.loadError, viewModel.detail == nil {
                    loadErrorView(err)
                } else if let detail = viewModel.detail {
                    formContent(detail: detail)
                }
            }
            .background(FashColors.screen)
            .safeAreaInset(edge: .bottom, spacing: 0) {
                if let detail = viewModel.detail, isListingStatusSellerPutAllowed(detail.status) {
                    bottomBar(detail: detail)
                }
            }
        }
        .task(id: listingId) {
            await viewModel.load(listingId: listingId, deps: deps)
        }
        .onChange(of: viewModel.shouldDismissAfterDelete) { _, dismiss in
            if dismiss { onDismiss() }
        }
        .sheet(item: $sharePayload) { payload in
            ActivityShareSheet(items: payload.items) { completed in
                FashActivityShare.showSuccessIfNeeded(
                    completed,
                    message: L10n.shareListingSuccess,
                    deps: deps
                )
            }
        }
        .alert(L10n.editListingDeleteTitle, isPresented: $showDeleteDialog) {
            Button(L10n.editListingDeleteConfirm, role: .destructive) {
                Task { await viewModel.delete(deps: deps) }
            }
            Button(L10n.createListingCancel, role: .cancel) {}
        } message: {
            Text(L10n.editListingDeleteBody)
        }
    }

    @ViewBuilder
    private func loadErrorView(_ message: String) -> some View {
        VStack(spacing: 16) {
            Text(message)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
                .multilineTextAlignment(.center)
            Button(L10n.feedRetry) {
                Task { await viewModel.load(listingId: listingId, deps: deps) }
            }
            .buttonStyle(.borderedProminent)
            .tint(FashColors.brandPrimary)
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    @ViewBuilder
    private func formContent(detail: ListingDetail) -> some View {
        let editable = isListingStatusSellerPutAllowed(detail.status)
        let status = detail.status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        let saving = viewModel.isSaving

        ScrollView {
            VStack(alignment: .leading, spacing: spacing.spacing4) {
                if !editable {
                    banner(editListingReadOnlyBannerMessage(status: detail.status), errorStyle: false)
                } else if status == "rejected" {
                    banner(L10n.editListingRejectedBanner, errorStyle: true)
                }

                sectionTitle(L10n.editListingPhotosSection)
                Text(L10n.editListingPhotosNote)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
                listingImageStrip(detail: detail)

                editListingCard {
                    Text(L10n.editListingCategoryLocked)
                        .font(FashTypography.labelMedium)
                        .foregroundStyle(FashColors.textSecondary)
                    Text(categoryLine(detail))
                        .font(FashTypography.bodyLarge)
                        .foregroundStyle(FashColors.textPrimary)
                }

                sectionTitle(L10n.postStepStyleOnly)
                Text(L10n.editListingTagsHint)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
                EditListingStyleTagsPicker(
                    catalogTags: viewModel.catalogTags,
                    selectedTagIds: viewModel.form.selectedTagIds,
                    maxTags: maxAestheticTags,
                    enabled: editable && !saving,
                    onToggle: { viewModel.toggleTag($0) }
                )
                if viewModel.form.selectedTagIds != viewModel.baselineTagIds,
                   viewModel.form.selectedTagIds.isEmpty {
                    Text(L10n.editListingTagsClearedNote)
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(FashColors.textSecondary)
                }

                editListingCard {
                    Text(L10n.postStepBrand)
                        .font(FashTypography.labelMedium)
                        .foregroundStyle(FashColors.textSecondary)
                    EditListingBrandPicker(
                        brandName: viewModel.form.brandName,
                        brandId: viewModel.form.brandId,
                        brands: viewModel.brandsSearch,
                        enabled: editable && !saving,
                        onSearch: { q in Task { await viewModel.searchBrands(query: q, deps: deps) } },
                        onSelect: { viewModel.selectBrand($0) }
                    )
                }

                Text(L10n.postStepConditionShort)
                    .font(FashTypography.labelMedium)
                    .foregroundStyle(FashColors.textSecondary)
                FlowPillsGrid {
                    ForEach(ListingConditionOptions.uiValues, id: \.self) { cond in
                        PostSelectablePill(text: cond, selected: viewModel.form.condition == cond) {
                            guard editable, !saving else { return }
                            viewModel.updateForm { $0.condition = cond }
                        }
                    }
                }

                PostListingOutlinedField(label: L10n.createListingTitleLabel, text: titleBinding(editable: editable && !saving))
                Text("\(viewModel.form.title.count)/\(maxListingTitleLength)")
                    .font(FashTypography.labelSmall)
                    .foregroundStyle(FashColors.textSecondary)

                PostListingOutlinedField(
                    label: L10n.editListingDescriptionLabel,
                    text: descriptionBinding(editable: editable && !saving),
                    axis: .vertical,
                    lineLimit: 4...8
                )
                Text("\(viewModel.form.description.count)/\(maxListingDescriptionLength)")
                    .font(FashTypography.labelSmall)
                    .foregroundStyle(FashColors.textSecondary)

                editListingCard {
                    PostListingOutlinedField(label: L10n.createListingSizeLabel, text: sizeBinding(editable: editable && !saving))
                    PostListingOutlinedField(
                        label: L10n.createListingPriceLabel,
                        text: priceBinding(editable: editable && !saving),
                        keyboard: .numberPad
                    )
                }

                sectionTitle(L10n.postStepGenderTarget)
                editListingCard {
                    FlowPillsGrid {
                        ForEach(editListingGenderOptions, id: \.0) { value, label in
                            PostSelectablePill(text: label, selected: viewModel.form.genderTarget == value) {
                                guard editable, !saving else { return }
                                viewModel.updateForm {
                                    $0.genderTarget = $0.genderTarget == value ? "" : value
                                }
                            }
                        }
                    }
                }

                sectionTitle(L10n.postStepColor)
                editListingCard {
                    FlowPillsGrid {
                        ForEach(listingPrimaryColorOptions, id: \.value) { option in
                            PostSelectablePill(text: option.label(), selected: viewModel.form.color == option.value) {
                                guard editable, !saving else { return }
                                viewModel.updateForm {
                                    $0.color = $0.color == option.value ? "" : option.value
                                }
                            }
                        }
                    }
                }

                sectionTitle(L10n.postStepWearSeason)
                Text(L10n.postStepWearSeasonSubtitle)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
                editListingCard {
                    ListingWearSeasonEditor(
                        yearRoundWear: viewModel.form.yearRoundWear,
                        seasonKeys: viewModel.form.seasonKeys,
                        climateZones: viewModel.form.climateZones,
                        macroRegions: viewModel.form.macroRegions,
                        enabled: editable && !saving,
                        onYearRoundToggle: {
                            viewModel.updateForm { $0.yearRoundWear.toggle() }
                        },
                        onToggleSeason: { key in
                            viewModel.updateForm { f in
                                var next = f.seasonKeys
                                if next.contains(key) { next.remove(key) } else { next.insert(key) }
                                f.seasonKeys = next
                            }
                        },
                        onToggleClimate: { key in
                            viewModel.updateForm { f in
                                var next = f.climateZones
                                if next.contains(key) { next.remove(key) } else { next.insert(key) }
                                f.climateZones = next
                            }
                        },
                        onToggleRegion: { key in
                            viewModel.updateForm { f in
                                var next = f.macroRegions
                                if next.contains(key) { next.remove(key) } else { next.insert(key) }
                                f.macroRegions = next
                            }
                        }
                    )
                }

                sectionTitle(L10n.postStepCountry)
                editListingCard {
                    EditListingCountryPicker(
                        countryName: viewModel.form.countryName,
                        countries: viewModel.countrySearch,
                        enabled: editable && !saving,
                        onSearch: { viewModel.searchCountries(query: $0) },
                        onSelect: { viewModel.selectCountry($0) }
                    )
                }

                sectionTitle(L10n.postStepMeasure)
                Text(L10n.postMeasureStepSubtitle)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
                measurementsSection(editable: editable && !saving)

                sectionTitle(L10n.editListingOffersSection)
                Text(L10n.editListingOffersSectionHint)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.textSecondary)
                offersSection(editable: editable && !saving)

                readOnlyShippingSection(detail: detail)

                if editable {
                    Text(status == "rejected" ? L10n.editListingRejectedBottomHint : L10n.editListingBottomHint)
                        .font(FashTypography.bodySmall)
                        .foregroundStyle(FashColors.textSecondary)
                        .padding(.top, 8)
                } else {
                    deleteOnlySection
                }
            }
            .padding(spacing.editorialStart)
            .padding(.bottom, spacing.spacing3)
        }
    }

    private var deleteOnlySection: some View {
        Button(role: .destructive) {
            showDeleteDialog = true
        } label: {
            Label(L10n.editListingDelete, systemImage: "trash")
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.bordered)
        .disabled(viewModel.isDeleting)
        .padding(.top, 16)
    }

    @ViewBuilder
    private func bottomBar(detail: ListingDetail) -> some View {
        let isRejected = detail.status.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() == "rejected"
        VStack(spacing: 0) {
            Divider().overlay(FashColors.outlineMuted.opacity(0.72))
            VStack(spacing: 10) {
                FashPrimaryButton(
                    title: isRejected ? L10n.editListingSaveResubmit : L10n.editListingSave,
                    isLoading: viewModel.isSaving,
                    enabled: viewModel.canSave && !viewModel.isDeleting
                ) {
                    Task { _ = await viewModel.save(deps: deps) }
                }
                Button(role: .destructive) {
                    showDeleteDialog = true
                } label: {
                    Label(L10n.editListingDelete, systemImage: "trash")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .disabled(viewModel.isSaving || viewModel.isDeleting)
            }
            .padding(.horizontal, spacing.editorialStart)
            .padding(.vertical, 12)
        }
        .background(FashColors.surface)
    }

    @ViewBuilder
    private func measurementsSection(editable: Bool) -> some View {
        let unit = viewModel.form.measurementUnit.lowercased() == "in" ? L10n.postUnitIn : L10n.postUnitCm
        editListingCard {
            Text(L10n.postMeasureSectionUnit)
                .font(FashTypography.labelMedium)
                .foregroundStyle(FashColors.textSecondary)
            HStack(spacing: 8) {
                PostSelectablePill(text: L10n.postUnitCm, selected: viewModel.form.measurementUnit.lowercased() == "cm") {
                    guard editable else { return }
                    viewModel.updateForm { $0.measurementUnit = "cm" }
                }
                PostSelectablePill(text: L10n.postUnitIn, selected: viewModel.form.measurementUnit.lowercased() == "in") {
                    guard editable else { return }
                    viewModel.updateForm { $0.measurementUnit = "in" }
                }
            }
            Text(L10n.postMeasureSectionDetails)
                .font(FashTypography.labelMedium)
                .foregroundStyle(FashColors.textSecondary)
            measurementField(L10n.postMeasurementHem, binding: measurementBinding(\.measurementHem, editable: editable), unit: unit)
            measurementField(L10n.postMeasurementChest, binding: measurementBinding(\.measurementChest, editable: editable), unit: unit)
            measurementField(L10n.postMeasurementLength, binding: measurementBinding(\.measurementLength, editable: editable), unit: unit)
            measurementField(L10n.postMeasurementShoulders, binding: measurementBinding(\.measurementShoulders, editable: editable), unit: unit)
            measurementField(L10n.postMeasurementSleeve, binding: measurementBinding(\.measurementSleeveLength, editable: editable), unit: unit)
        }
    }

    @ViewBuilder
    private func offersSection(editable: Bool) -> some View {
        editListingCard {
            Toggle(L10n.postAcceptOffers, isOn: Binding(
                get: { viewModel.form.acceptOffers },
                set: { v in viewModel.updateForm { $0.acceptOffers = v } }
            ))
            .disabled(!editable)
            Toggle(L10n.postAutoPriceDrop, isOn: Binding(
                get: { viewModel.form.autoPriceDropEnabled },
                set: { v in viewModel.updateForm { $0.autoPriceDropEnabled = v } }
            ))
            .disabled(!editable)
            if viewModel.form.autoPriceDropEnabled {
                PostListingOutlinedField(
                    label: L10n.postFloorPrice,
                    text: floorBinding(editable: editable),
                    keyboard: .numberPad
                )
                PostListingOutlinedField(
                    label: L10n.postDropPercent,
                    text: percentBinding(editable: editable),
                    keyboard: .numberPad
                )
            }
        }
    }

    @ViewBuilder
    private func readOnlyShippingSection(detail: ListingDetail) -> some View {
        let hasShipping = detail.shippingAddress != nil
        let hasEst = detail.estimatedShippingVnd != nil
        if hasShipping || hasEst {
            sectionTitle(L10n.editListingReadonlySectionTitle)
            Text(L10n.editListingReadonlySectionSubtitle)
                .font(FashTypography.bodySmall)
                .foregroundStyle(FashColors.textSecondary)
            editListingCard {
                if let addr = detail.shippingAddress {
                    Text(L10n.postStepShipping)
                        .font(FashTypography.labelMedium)
                        .foregroundStyle(FashColors.textSecondary)
                    Text(formatEditShippingAddress(addr))
                        .font(FashTypography.bodyMedium)
                        .foregroundStyle(FashColors.textPrimary)
                }
                if let fee = detail.estimatedShippingVnd {
                    Text(L10n.productShippingEstimate(FeedPriceFormat.format(fee)))
                        .font(FashTypography.bodyMedium)
                        .foregroundStyle(FashColors.textSecondary)
                }
            }
        }
    }

    private func listingImageStrip(detail: ListingDetail) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(detail.imageUrls, id: \.self) { url in
                    FashAsyncImage(url: FeedImageUrl.resolveListingImageUrlOrNil(url) ?? url, contentMode: .fill)
                        .frame(width: 88, height: 110)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                }
            }
        }
    }

    private func categoryLine(_ detail: ListingDetail) -> String {
        var parts: [String] = []
        if let p = detail.parentCategoryName?.trimmingCharacters(in: .whitespacesAndNewlines), !p.isEmpty {
            parts.append(p)
        }
        let cat = detail.category?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        parts.append(cat.isEmpty ? L10n.createListingSelect : cat)
        return parts.joined(separator: " · ")
    }

    private func sectionTitle(_ text: String) -> some View {
        Text(text)
            .font(FashTypography.titleSmall)
            .foregroundStyle(FashColors.textPrimary)
    }

    private func banner(_ text: String, errorStyle: Bool) -> some View {
        Text(text)
            .font(FashTypography.bodyMedium)
            .foregroundStyle(errorStyle ? FashColors.error : FashColors.textPrimary)
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background((errorStyle ? FashColors.error : FashColors.brandPrimary).opacity(0.12))
            .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func editListingCard<Content: View>(@ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: spacing.spacing3) {
            content()
        }
        .padding(spacing.spacing4)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(FashColors.surfaceContainerLow)
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func measurementField(_ label: String, binding: Binding<String>, unit: String) -> some View {
        HStack(alignment: .bottom, spacing: 8) {
            PostListingOutlinedField(label: label, text: binding, keyboard: .decimalPad)
            Text(unit)
                .font(FashTypography.labelMedium)
                .foregroundStyle(FashColors.textSecondary)
                .padding(.bottom, 10)
        }
    }

    private func titleBinding(editable: Bool) -> Binding<String> {
        Binding(
            get: { viewModel.form.title },
            set: { v in
                guard editable else { return }
                viewModel.updateForm { $0.title = String(v.prefix(maxListingTitleLength)) }
            }
        )
    }

    private func descriptionBinding(editable: Bool) -> Binding<String> {
        Binding(
            get: { viewModel.form.description },
            set: { v in
                guard editable else { return }
                viewModel.updateForm { $0.description = String(v.prefix(maxListingDescriptionLength)) }
            }
        )
    }

    private func sizeBinding(editable: Bool) -> Binding<String> {
        Binding(
            get: { viewModel.form.size },
            set: { v in
                guard editable else { return }
                viewModel.updateForm { $0.size = String(v.prefix(20)) }
            }
        )
    }

    private func priceBinding(editable: Bool) -> Binding<String> {
        Binding(
            get: { viewModel.form.priceText },
            set: { v in
                guard editable else { return }
                let digits = v.filter(\.isNumber).prefix(12)
                viewModel.updateForm { $0.priceText = String(digits) }
            }
        )
    }

    private func floorBinding(editable: Bool) -> Binding<String> {
        Binding(
            get: { viewModel.form.floorPriceText },
            set: { v in
                guard editable else { return }
                let digits = v.filter(\.isNumber).prefix(12)
                viewModel.updateForm { $0.floorPriceText = String(digits) }
            }
        )
    }

    private func percentBinding(editable: Bool) -> Binding<String> {
        Binding(
            get: { viewModel.form.priceDropPercentInput },
            set: { v in
                guard editable else { return }
                viewModel.updateForm { $0.priceDropPercentInput = String(v.filter(\.isNumber).prefix(2)) }
            }
        )
    }

    private func measurementBinding(
        _ keyPath: WritableKeyPath<EditListingFormState, String>,
        editable: Bool
    ) -> Binding<String> {
        Binding(
            get: { viewModel.form[keyPath: keyPath] },
            set: { v in
                guard editable else { return }
                viewModel.updateForm { $0[keyPath: keyPath] = v }
            }
        )
    }
}

private struct EditListingSharePayload: Identifiable {
    let id = UUID()
    let items: [Any]
}

private let editListingGenderOptions: [(String, String)] = [
    ("women", L10n.genderTargetWomen),
    ("men", L10n.genderTargetMen),
    ("unisex", L10n.genderTargetUnisex),
    ("kids", L10n.genderTargetKids),
]

private func formatEditShippingAddress(_ addr: ListingShippingAddress) -> String {
    var lines: [String] = []
    if let label = addr.label?.trimmingCharacters(in: .whitespacesAndNewlines), !label.isEmpty {
        lines.append(label)
    }
    lines.append(addr.line1)
    if let l2 = addr.line2?.trimmingCharacters(in: .whitespacesAndNewlines), !l2.isEmpty { lines.append(l2) }
    var cityLine: [String] = []
    if let c = addr.city?.trimmingCharacters(in: .whitespacesAndNewlines), !c.isEmpty { cityLine.append(c) }
    if let r = addr.region?.trimmingCharacters(in: .whitespacesAndNewlines), !r.isEmpty { cityLine.append(r) }
    if let z = addr.postalCode?.trimmingCharacters(in: .whitespacesAndNewlines), !z.isEmpty { cityLine.append(z) }
    if !cityLine.isEmpty { lines.append(cityLine.joined(separator: ", ")) }
    if let cc = addr.countryCode?.trimmingCharacters(in: .whitespacesAndNewlines), !cc.isEmpty {
        lines.append(cc.uppercased())
    }
    return lines.joined(separator: "\n")
}
