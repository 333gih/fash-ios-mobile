import SwiftUI
import PhotosUI

struct CreateListingPostSteps: View {
    @Environment(\.fashSpacing) private var spacing
    @Bindable var postVM: PostViewModel
    let step: Int

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacing.spacing4) {
                switch step {
                case 1: categoryStep
                case 2: aestheticStep
                case 3: brandStep
                case 4: countryStep
                case 5: detailsStep
                default: EmptyView()
                }
            }
            .padding(spacing.spacing4)
        }
    }

    private var categoryStep: some View {
        VStack(alignment: .leading, spacing: spacing.spacing3) {
            Text(L10n.postStepCategory)
                .font(FashTypography.titleMedium)
            TextField(L10n.createListingSelectCategory, text: Binding(
                get: { postVM.draft.categoryName },
                set: { _ in }
            ))
            .disabled(true)
            ForEach(postVM.categoryTree.allLeaves().prefix(40), id: \.id) { leaf in
                Button(leaf.name) {
                    postVM.updateDraft { $0 = $0.withLeafCategory(treeRoots: postVM.categoryTree, leaf: leaf) }
                    Task { await postVM.ensureListingPhotoSlotsLoaded(deps: deps) }
                }
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textPrimary)
            }
        }
        .task { await postVM.loadCatalogIfNeeded(deps: deps) }
    }

    private var aestheticStep: some View {
        VStack(alignment: .leading, spacing: spacing.spacing2) {
            Text(L10n.postStepStyleOnly)
                .font(FashTypography.titleMedium)
            ForEach(postVM.aestheticTags.prefix(30), id: \.id) { tag in
                let selected = postVM.draft.selectedAestheticTagIds.contains(tag.id)
                Button {
                    postVM.updateDraft { $0 = $0.toggleAestheticTag(tag.id) }
                } label: {
                    HStack {
                        Text(tag.displayName.isEmpty ? tag.name : tag.displayName)
                        Spacer()
                        if selected { Image(systemName: "checkmark") }
                    }
                }
                .foregroundStyle(selected ? FashColors.brandPrimary : FashColors.textPrimary)
            }
        }
    }

    private var brandStep: some View {
        VStack(alignment: .leading, spacing: spacing.spacing3) {
            Text(L10n.postStepBrand)
                .font(FashTypography.titleMedium)
            TextField(L10n.createListingBrandLabel, text: brandQuery)
                .textFieldStyle(.roundedBorder)
            ForEach(postVM.brandsSearch.prefix(30), id: \.id) { brand in
                Button(brand.name) {
                    postVM.updateDraft {
                        $0.brandId = brand.id
                        $0.brandName = brand.name
                    }
                }
                .foregroundStyle(FashColors.textPrimary)
            }
        }
    }

    private var brandQuery: Binding<String> {
        Binding(
            get: { postVM.draft.brandName },
            set: { new in
                postVM.updateDraft { $0.brandName = new }
                Task { await postVM.searchBrands(deps: deps, query: new) }
            }
        )
    }

    private var countryStep: some View {
        VStack(alignment: .leading, spacing: spacing.spacing2) {
            Text(L10n.postStepCountry)
                .font(FashTypography.titleMedium)
            ForEach(postVM.countries.prefix(40), id: \.id) { country in
                Button(country.name) {
                    postVM.updateDraft {
                        $0.countryId = country.id
                        $0.countryIso2 = country.iso2
                        $0.countryName = country.name
                    }
                }
                .foregroundStyle(FashColors.textPrimary)
            }
        }
    }

    private var detailsStep: some View {
        VStack(alignment: .leading, spacing: spacing.spacing3) {
            Text(L10n.postStepCondition)
                .font(FashTypography.titleMedium)
            Picker(L10n.createListingConditionLabel, selection: conditionBinding) {
                Text("new").tag("new")
                Text("like_new").tag("like_new")
                Text("good").tag("good")
                Text("fair").tag("fair")
            }
            .pickerStyle(.segmented)
            TextField(L10n.createListingTitlePlaceholder, text: titleBinding)
                .textFieldStyle(.roundedBorder)
            TextField(L10n.createListingTipText, text: descriptionBinding, axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(.roundedBorder)
            Stepper(
                value: Binding(get: { postVM.draft.conditionScore }, set: { v in postVM.updateDraft { $0.conditionScore = v } }),
                in: 80...99
            ) {
                Text("Score: \(postVM.draft.conditionScore)")
            }
        }
    }

    private var conditionBinding: Binding<String> {
        Binding(get: { postVM.draft.condition }, set: { v in postVM.updateDraft { $0.condition = v } })
    }

    private var titleBinding: Binding<String> {
        Binding(get: { postVM.draft.title }, set: { v in postVM.updateDraft { $0.title = v } })
    }

    private var descriptionBinding: Binding<String> {
        Binding(get: { postVM.draft.description }, set: { v in postVM.updateDraft { $0.description = v } })
    }

    @Environment(AppDependencies.self) private var deps
}
