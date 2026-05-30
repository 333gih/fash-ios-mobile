import SwiftUI

// MARK: - Brand picker

struct EditListingBrandPicker: View {
    let brandName: String
    let brandId: String?
    let brands: [CommonBrandDto]
    let enabled: Bool
    let onSearch: (String) -> Void
    let onSelect: (CommonBrandDto?) -> Void

    @State private var showSheet = false
    @State private var query = ""

    var body: some View {
        Button {
            guard enabled else { return }
            query = ""
            onSearch("")
            showSheet = true
        } label: {
            HStack {
                Text(brandName.isEmpty ? L10n.editListingBrandDropdownPlaceholder : brandName)
                    .foregroundStyle(brandName.isEmpty ? FashColors.textSecondary : FashColors.textPrimary)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundStyle(FashColors.textSecondary)
            }
            .padding(12)
            .background(FashColors.surfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .sheet(isPresented: $showSheet) {
            NavigationStack {
                List {
                    if !brandName.isEmpty {
                        Button(L10n.postClearBrand) {
                            onSelect(nil)
                            showSheet = false
                        }
                    }
                    ForEach(brands, id: \.id) { brand in
                        Button {
                            onSelect(brand)
                            showSheet = false
                        } label: {
                            HStack {
                                Text(brand.name)
                                Spacer()
                                if brandId == brand.id {
                                    Image(systemName: "checkmark")
                                        .foregroundStyle(FashColors.brandPrimary)
                                }
                            }
                        }
                    }
                    if brands.isEmpty {
                        Text(L10n.editListingBrandDropdownEmpty)
                            .foregroundStyle(FashColors.textSecondary)
                    }
                }
                .searchable(text: $query, prompt: L10n.postSearchBrand)
                .onChange(of: query) { _, newValue in
                    onSearch(newValue)
                }
                .navigationTitle(L10n.postStepBrand)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(L10n.createListingCancel) { showSheet = false }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
}

// MARK: - Country picker

struct EditListingCountryPicker: View {
    let countryName: String
    let countries: [CommonCountryDto]
    let enabled: Bool
    let onSearch: (String) -> Void
    let onSelect: (CommonCountryDto?) -> Void

    @State private var showSheet = false
    @State private var query = ""

    var body: some View {
        Button {
            guard enabled else { return }
            query = ""
            onSearch("")
            showSheet = true
        } label: {
            HStack {
                Text(countryName.isEmpty ? L10n.editListingCountryDropdownPlaceholder : countryName)
                    .foregroundStyle(countryName.isEmpty ? FashColors.textSecondary : FashColors.textPrimary)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundStyle(FashColors.textSecondary)
            }
            .padding(12)
            .background(FashColors.surfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .sheet(isPresented: $showSheet) {
            NavigationStack {
                List {
                    if !countryName.isEmpty {
                        Button(L10n.editListingClearCountry) {
                            onSelect(nil)
                            showSheet = false
                        }
                    }
                    ForEach(countries, id: \.id) { country in
                        Button {
                            onSelect(country)
                            showSheet = false
                        } label: {
                            Text("\(country.name) (\(country.iso2))")
                        }
                    }
                    if countries.isEmpty {
                        Text(L10n.editListingCountryDropdownEmpty)
                            .foregroundStyle(FashColors.textSecondary)
                    }
                }
                .searchable(text: $query, prompt: L10n.postStepCountry)
                .onChange(of: query) { _, newValue in
                    onSearch(newValue)
                }
                .navigationTitle(L10n.postStepCountry)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(L10n.createListingCancel) { showSheet = false }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
}

// MARK: - Style tags picker

struct EditListingStyleTagsPicker: View {
    let catalogTags: [CommonAestheticTagDto]
    let selectedTagIds: Set<String>
    let maxTags: Int
    let enabled: Bool
    let onToggle: (String) -> Void

    @State private var showSheet = false

    var body: some View {
        let count = selectedTagIds.count
        Button {
            guard enabled else { return }
            showSheet = true
        } label: {
            HStack {
                Text(count == 0
                    ? L10n.editListingTagsDropdownPlaceholder
                    : L10n.editListingTagsCountFmt(count, maxTags))
                    .foregroundStyle(count == 0 ? FashColors.textSecondary : FashColors.textPrimary)
                Spacer()
                Image(systemName: "chevron.down")
                    .font(.caption)
                    .foregroundStyle(FashColors.textSecondary)
            }
            .padding(12)
            .background(FashColors.surfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .sheet(isPresented: $showSheet) {
            NavigationStack {
                ScrollView {
                    FlowPillsGrid {
                        ForEach(catalogTags, id: \.id) { tag in
                            let selected = selectedTagIds.contains(tag.id)
                            PostSelectablePill(
                                text: AestheticTagLabels.resolveLabel(
                                    catalog: catalogTags,
                                    id: tag.id,
                                    rawName: tag.name
                                ),
                                selected: selected
                            ) {
                                onToggle(tag.id)
                            }
                            .disabled(!selected && selectedTagIds.count >= maxTags)
                        }
                    }
                    .padding()
                }
                .navigationTitle(L10n.editListingStyleTags)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(L10n.editListingTagsDone) { showSheet = false }
                    }
                }
            }
            .presentationDetents([.medium, .large])
        }
    }
}
