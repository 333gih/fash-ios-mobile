import SwiftUI

struct UserExperienceSurveyScreen: View {
    @Environment(\.fashSpacing) private var spacing
    @Environment(AppDependencies.self) private var deps
    let surveyKey: String
    var onDismiss: () -> Void = {}

    @State private var viewModel = UserExperienceSurveyViewModel()

    var body: some View {
        OverlayScreenHost(
            title: viewModel.survey?.title.nilIfEmpty ?? L10n.uxSurveyTitle,
            onDismiss: onDismiss
        ) {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                        .tint(FashColors.brandPrimary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let err = viewModel.errorMessage, viewModel.survey == nil {
                    FashEmptyStateView(title: L10n.feedLoadError, subtitle: err)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if viewModel.submitted {
                    thanksState
                } else if let survey = viewModel.survey {
                    surveyForm(survey)
                }
            }
            .background(FashColors.screen)
        }
        .task(id: surveyKey) {
            await viewModel.load(surveyKey: surveyKey, deps: deps)
        }
    }

    private var thanksState: some View {
        VStack(spacing: spacing.spacing3) {
            Text(L10n.uxSurveyThanksTitle)
                .font(FashTypography.titleLarge.weight(.bold))
                .multilineTextAlignment(.center)
            Text(L10n.uxSurveyThanksBody)
                .font(FashTypography.bodyMedium)
                .foregroundStyle(FashColors.textSecondary)
                .multilineTextAlignment(.center)
            FashPrimaryButton(title: L10n.cdBack) { onDismiss() }
        }
        .padding(spacing.editorialStart)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func surveyForm(_ survey: UxSurveyDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: spacing.spacing4) {
                if !survey.description.isEmpty {
                    Text(survey.description)
                        .font(FashTypography.bodyLarge)
                        .foregroundStyle(FashColors.textSecondary)
                }
                ForEach(survey.questions) { question in
                    questionBlock(question)
                }
                FashPrimaryButton(
                    title: L10n.uxSurveySubmit,
                    isLoading: viewModel.isSubmitting
                ) {
                    Task { _ = await viewModel.submit(surveyKey: surveyKey, deps: deps) }
                }
            }
            .padding(spacing.editorialStart)
            .padding(.bottom, spacing.spacing6)
        }
    }

    @ViewBuilder
    private func questionBlock(_ question: UxSurveyQuestion) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question.prompt)
                .font(FashTypography.titleSmall.weight(.semibold))
            if question.questionType.lowercased() == "rating" {
                HStack(spacing: 4) {
                    ForEach(1...5, id: \.self) { star in
                        Button {
                            viewModel.setRating(questionId: question.id, rating: star)
                        } label: {
                            Image(systemName: viewModel.rating(for: question.id) >= star ? "star.fill" : "star")
                                .font(.system(size: 28))
                                .foregroundStyle(
                                    viewModel.rating(for: question.id) >= star
                                        ? FashColors.brandPrimary
                                        : FashColors.textSecondary
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
            } else {
                TextField(L10n.uxSurveyTextHint, text: Binding(
                    get: { viewModel.text(for: question.id) },
                    set: { viewModel.setText(questionId: question.id, text: $0) }
                ), axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(.roundedBorder)
            }
        }
    }
}

private extension String {
    var nilIfEmpty: String? {
        let t = trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? nil : t
    }
}
