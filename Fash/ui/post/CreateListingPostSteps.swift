import SwiftUI

struct CreateListingPostSteps: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps
    @Bindable var postVM: PostViewModel
    let step: Int

    @State private var categoryQuery = ""
    @State private var countryQuery = ""

    var body: some View {
        PostStepScrollContent(bottomNotice: bottomNotice) {
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
        .background(PostListingColors.stepCanvas)
    }

    private var bottomNotice: String? {
        switch step {
        case 1: return L10n.postHintCategoryStep
        case 2: return L10n.postHintStyleTagsStep
        case 3: return L10n.postHintBrand
        case 4: return L10n.postHintCountry
        case 5: return L10n.postHintListingDetailsStep
        default: return nil
        }
    }

    @ViewBuilder
    private var stepTitle: some View {
        let title: String = switch step {
        case 1: L10n.postStepCategory
        case 2: L10n.postStepStyleOnly
        case 3: L10n.postStepBrand
        case 4: L10n.postStepCountry
        case 5: L10n.postStepCondition
        default: ""
        }
        if !title.isEmpty {
            Text(title)
                .font(FashTypography.titleLarge.weight(.semibold))
                .foregroundStyle(FashColors.textPrimary)
        }
    }

    private var categoryStep: some View {
        Group {
            PostListingOutlinedField(
                label: L10n.createListingSelectCategory,
                text: $categoryQuery
            )
            .onChange(of: categoryQuery) { _, _ in }

            let matches = buildCategorySearchMatches(roots: postVM.categoryTree, query: categoryQuery)
            if !categoryQuery.trimmingCharacters(in: .whitespaces).isEmpty {
                ForEach(matches) { match in
                    PostSelectableListRow(
                        text: match.pathLabel,
                        subtitle: match.leaf.name,
                        selected: postVM.draft.categoryId == match.leaf.id
                    ) {
                        selectCategory(match.leaf)
                    }
                }
            } else if postVM.catalogLoading && postVM.categoryTree.isEmpty {
                ProgressView().tint(FashColors.brandPrimary)
            } else {
                ForEach(postVM.categoryTree, id: \.id) { root in
                    categoryTreeSection(root: root, depth: 0)
                }
            }
        }
        .task { await postVM.loadCatalogIfNeeded(deps: deps) }
    }

    @ViewBuilder
    private func categoryTreeSection(root: CategoryTreeNode, depth: Int) -> some View {
        if root.children.isEmpty {
            PostSelectableListRow(
                text: root.name,
                selected: postVM.draft.categoryId == root.id
            ) { selectCategory(root) }
        } else {
            Text(root.name)
                .font(FashTypography.labelLarge.weight(.semibold))
                .foregroundStyle(FashColors.textSecondary)
                .padding(.top, depth == 0 ? 0 : 8)
            ForEach(root.children, id: \.id) { child in
                categoryTreeSection(root: child, depth: depth + 1)
            }
        }
    }

    private func selectCategory(_ leaf: CategoryTreeNode) {
        postVM.updateDraft { $0 = $0.withLeafCategory(treeRoots: postVM.categoryTree, leaf: leaf) }
        categoryQuery = leaf.name
        Task { await postVM.ensureListingPhotoSlotsLoaded(deps: deps) }
    }

    private var aestheticStep: some View {
        VStack(alignment: .leading, spacing: spacing.spacing3) {
            if postVM.draft.fillMode == .fromProfileStyle {
                PostProfilePrefilledBanner()
            }
            Text(L10n.createListingStyleLabel)
                .font(FashTypography.bodySmall)
                .foregroundStyle(FashColors.textSecondary)
            FlowPillsGrid {
                ForEach(postVM.aestheticTags, id: \.id) { tag in
                    let selected = postVM.draft.selectedAestheticTagIds.contains(tag.id)
                    PostSelectablePill(
                        text: tag.displayName.isEmpty ? tag.name : tag.displayName,
                        selected: selected
                    ) {
                        postVM.updateDraft { $0 = $0.toggleAestheticTag(tag.id) }
                    }
                }
            }
        }
    }

    private var brandStep: some View {
        VStack(alignment: .leading, spacing: spacing.spacing3) {
            PostListingOutlinedField(label: L10n.createListingBrandLabel, text: brandQueryBinding)
            ForEach(postVM.brandsSearch.filter { matchesBrandQuery($0, query: postVM.draft.brandName) }.prefix(40), id: \.id) { brand in
                PostSelectableListRow(
                    text: brand.name,
                    selected: postVM.draft.brandId == brand.id
                ) {
                    postVM.updateDraft {
                        $0.brandId = brand.id
                        $0.brandName = brand.name
                    }
                }
            }
        }
    }

    private var brandQueryBinding: Binding<String> {
        Binding(
            get: { postVM.draft.brandName },
            set: { new in
                postVM.updateDraft { $0.brandName = new }
                Task { await postVM.searchBrands(deps: deps, query: new) }
            }
        )
    }

    private var countryStep: some View {
        VStack(alignment: .leading, spacing: spacing.spacing3) {
            PostListingOutlinedField(label: L10n.postStepCountry, text: $countryQuery)
            ForEach(postVM.countries.filter { matchesCountryQuery($0, query: countryQuery) }.prefix(50), id: \.id) { country in
                PostSelectableListRow(
                    text: country.name,
                    subtitle: country.iso2,
                    leadingEmoji: country.emoji,
                    selected: postVM.draft.countryId == country.id
                ) {
                    postVM.updateDraft {
                        $0.countryId = country.id
                        $0.countryIso2 = country.iso2
                        $0.countryName = country.name
                    }
                    countryQuery = country.name
                }
            }
        }
    }

    private var detailsStep: some View {
        VStack(alignment: .leading, spacing: spacing.spacing4) {
            Text(L10n.postListingDetailsIntro)
                .font(FashTypography.bodySmall)
                .foregroundStyle(FashColors.textSecondary)

            Text(L10n.postStepConditionShort)
                .font(FashTypography.labelLarge)
                .foregroundStyle(FashColors.textSecondary)
            FlowPillsGrid {
                ForEach(ListingConditionOptions.uiValues, id: \.self) { cond in
                    PostSelectablePill(text: cond, selected: postVM.draft.condition == cond) {
                        postVM.updateDraft { $0.condition = cond }
                    }
                }
            }

            Text(L10n.postConditionScoreLabel(postVM.draft.conditionScore))
                .font(FashTypography.labelLarge)
                .foregroundStyle(FashColors.textSecondary)
            Slider(
                value: Binding(
                    get: { Double(postVM.draft.conditionScore) },
                    set: { postVM.updateDraft { $0.conditionScore = min(99, max(80, Int($0.rounded()))) } }
                ),
                in: 80...99,
                step: 1
            )
            .tint(FashColors.brandPrimary)

            Text(L10n.postConditionDefectsLabel)
                .font(FashTypography.labelLarge)
                .foregroundStyle(FashColors.textSecondary)
            FlowPillsGrid {
                ForEach(listingConditionDefectOptions, id: \.self) { key in
                    PostSelectablePill(
                        text: conditionDefectLabel(key),
                        selected: postVM.draft.conditionDefects.contains(key)
                    ) {
                        postVM.updateDraft { $0 = $0.toggleConditionDefect(key) }
                    }
                }
            }
            if !postVM.draft.conditionDefects.isEmpty {
                Text(L10n.postConditionDefectPhotoHint)
                    .font(FashTypography.bodySmall)
                    .foregroundStyle(FashColors.error)
            }

            PostListingOutlinedField(label: L10n.createListingTitleLabel, text: titleBinding)
            Text("\(postVM.draft.title.count)/\(maxListingTitleLength)")
                .font(FashTypography.labelSmall)
                .foregroundStyle(FashColors.textSecondary)

            PostListingOutlinedField(
                label: L10n.postDescriptionLabel,
                text: descriptionBinding,
                axis: .vertical,
                lineLimit: 4...8
            )
            Text("\(postVM.draft.description.count)/\(maxListingDescriptionLength)")
                .font(FashTypography.labelSmall)
                .foregroundStyle(FashColors.textSecondary)

            Text(L10n.postStepColor)
                .font(FashTypography.labelLarge)
                .foregroundStyle(FashColors.textSecondary)
            Text(L10n.postListingColorHint)
                .font(FashTypography.bodySmall)
                .foregroundStyle(FashColors.textSecondary)
            FlowPillsGrid {
                ForEach(listingPrimaryColorOptions, id: \.value) { option in
                    PostSelectablePill(
                        text: option.label(),
                        selected: postVM.draft.color == option.value
                    ) {
                        postVM.updateDraft {
                            $0.color = $0.color == option.value ? "" : option.value
                        }
                    }
                }
            }
        }
    }

    private var titleBinding: Binding<String> {
        Binding(
            get: { postVM.draft.title },
            set: { v in postVM.updateDraft { $0.title = String(v.prefix(maxListingTitleLength)) } }
        )
    }

    private var descriptionBinding: Binding<String> {
        Binding(
            get: { postVM.draft.description },
            set: { v in postVM.updateDraft { $0.description = String(v.prefix(maxListingDescriptionLength)) } }
        )
    }
}
