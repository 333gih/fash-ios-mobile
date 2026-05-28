import SwiftUI
import PhotosUI

struct CreateListingPostSteps: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps
    @Bindable var postVM: PostViewModel
    let step: Int

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacing.spacing4) {
                stepTitle
                switch step {
                case 1: categoryStep
                case 2: aestheticStep
                case 3: brandStep
                case 4: countryStep
                case 5: detailsStep
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
        switch step {
        case 1:
            Text(L10n.postStepCategory)
                .font(FashTypography.titleLarge.weight(.semibold))
                .foregroundStyle(FashColors.textPrimary)
        case 2:
            Text(L10n.postStepStyleOnly)
                .font(FashTypography.titleLarge.weight(.semibold))
                .foregroundStyle(FashColors.textPrimary)
        case 3:
            Text(L10n.postStepBrand)
                .font(FashTypography.titleLarge.weight(.semibold))
                .foregroundStyle(FashColors.textPrimary)
        case 4:
            Text(L10n.postStepCountry)
                .font(FashTypography.titleLarge.weight(.semibold))
                .foregroundStyle(FashColors.textPrimary)
        case 5:
            Text(L10n.postStepCondition)
                .font(FashTypography.titleLarge.weight(.semibold))
                .foregroundStyle(FashColors.textPrimary)
        default:
            EmptyView()
        }
    }

    private var categoryStep: some View {
        PostStepSectionCard {
            if postVM.catalogLoading && postVM.categoryTree.isEmpty {
                ProgressView().tint(FashColors.brandPrimary)
            }
            TextField(L10n.createListingSelectCategory, text: Binding(
                get: { postVM.draft.categoryName },
                set: { _ in }
            ))
            .disabled(true)
            .padding(spacing.spacing3)
            .background(FashColors.surfaceContainerLow)
            .clipShape(RoundedRectangle(cornerRadius: spacing.radiusSoftMin, style: .continuous))
            ForEach(postVM.categoryTree.allLeaves().prefix(40), id: \.id) { leaf in
                let selected = postVM.draft.categoryId == leaf.id
                Button(leaf.name) {
                    postVM.updateDraft { $0 = $0.withLeafCategory(treeRoots: postVM.categoryTree, leaf: leaf) }
                    Task { await postVM.ensureListingPhotoSlotsLoaded(deps: deps) }
                }
                .font(FashTypography.bodyMedium.weight(selected ? .semibold : .regular))
                .foregroundStyle(selected ? FashColors.brandPrimary : FashColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .task { await postVM.loadCatalogIfNeeded(deps: deps) }
    }

    private var aestheticStep: some View {
        VStack(alignment: .leading, spacing: spacing.spacing3) {
            if postVM.draft.fillMode == .fromProfileStyle {
                PostProfilePrefilledBanner()
            }
            PostStepSectionCard {
                ForEach(postVM.aestheticTags.prefix(30), id: \.id) { tag in
                    let selected = postVM.draft.selectedAestheticTagIds.contains(tag.id)
                    Button {
                        postVM.updateDraft { $0 = $0.toggleAestheticTag(tag.id) }
                    } label: {
                        HStack {
                            Text(tag.displayName.isEmpty ? tag.name : tag.displayName)
                            Spacer()
                            if selected { Image(systemName: "checkmark.circle.fill") }
                        }
                    }
                    .foregroundStyle(selected ? FashColors.brandPrimary : FashColors.textPrimary)
                }
            }
        }
    }

    private var brandStep: some View {
        PostStepSectionCard {
            TextField(L10n.createListingBrandLabel, text: brandQuery)
                .padding(spacing.spacing3)
                .background(FashColors.surfaceContainerLow)
                .clipShape(RoundedRectangle(cornerRadius: spacing.radiusSoftMin, style: .continuous))
            ForEach(postVM.brandsSearch.prefix(30), id: \.id) { brand in
                let selected = postVM.draft.brandId == brand.id
                Button(brand.name) {
                    postVM.updateDraft {
                        $0.brandId = brand.id
                        $0.brandName = brand.name
                    }
                }
                .font(FashTypography.bodyMedium.weight(selected ? .semibold : .regular))
                .foregroundStyle(selected ? FashColors.brandPrimary : FashColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
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
        PostStepSectionCard {
            ForEach(postVM.countries.prefix(40), id: \.id) { country in
                let selected = postVM.draft.countryId == country.id
                Button(country.name) {
                    postVM.updateDraft {
                        $0.countryId = country.id
                        $0.countryIso2 = country.iso2
                        $0.countryName = country.name
                    }
                }
                .font(FashTypography.bodyMedium.weight(selected ? .semibold : .regular))
                .foregroundStyle(selected ? FashColors.brandPrimary : FashColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var detailsStep: some View {
        PostStepSectionCard {
            Picker(L10n.createListingConditionLabel, selection: conditionBinding) {
                Text(L10n.conditionNew).tag("new")
                Text(L10n.conditionLikeNew).tag("like_new")
                Text(L10n.conditionGood).tag("good")
                Text(L10n.conditionFair).tag("fair")
            }
            .pickerStyle(.segmented)
            TextField(L10n.createListingTitlePlaceholder, text: titleBinding)
                .padding(spacing.spacing3)
                .background(FashColors.surfaceContainerLow)
                .clipShape(RoundedRectangle(cornerRadius: spacing.radiusSoftMin, style: .continuous))
            TextField(L10n.createListingTipText, text: descriptionBinding, axis: .vertical)
                .lineLimit(3...6)
                .padding(spacing.spacing3)
                .background(FashColors.surfaceContainerLow)
                .clipShape(RoundedRectangle(cornerRadius: spacing.radiusSoftMin, style: .continuous))
            Stepper(
                value: Binding(get: { postVM.draft.conditionScore }, set: { v in postVM.updateDraft { $0.conditionScore = v } }),
                in: 80...99
            ) {
                Text(L10n.postConditionScoreLabel(postVM.draft.conditionScore))
                    .font(FashTypography.bodyMedium)
                    .foregroundStyle(FashColors.textSecondary)
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

}
