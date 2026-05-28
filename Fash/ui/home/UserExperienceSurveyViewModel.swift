import Foundation
import Observation

@Observable
@MainActor
final class UserExperienceSurveyViewModel {
    var isLoading = true
    var isSubmitting = false
    var errorMessage: String?
    var survey: UxSurveyDetail?
    var submitted = false

    private var ratings: [String: Int] = [:]
    private var texts: [String: String] = [:]

    func load(surveyKey: String, deps: AppDependencies) async {
        isLoading = true
        errorMessage = nil
        submitted = false
        ratings = [:]
        texts = [:]
        defer { isLoading = false }
        switch await deps.uxSurveyRepository.getSurvey(surveyKey) {
        case .success(let detail):
            survey = detail
            if detail.submitted { submitted = true }
        case .failure(let err):
            survey = nil
            errorMessage = FashErrorPresentation.userMessage(for: err)
        }
    }

    func setRating(questionId: String, rating: Int) {
        ratings[questionId] = min(max(rating, 1), 5)
    }

    func setText(questionId: String, text: String) {
        texts[questionId] = text
    }

    func rating(for questionId: String) -> Int {
        ratings[questionId] ?? 0
    }

    func text(for questionId: String) -> String {
        texts[questionId] ?? ""
    }

    func submit(surveyKey: String, deps: AppDependencies) async -> Bool {
        guard let detail = survey, !isSubmitting, !submitted else { return false }
        var answers: [UxSurveyAnswerInput] = []
        for q in detail.questions {
            switch q.questionType.lowercased() {
            case "rating":
                guard let r = ratings[q.id], r > 0 else {
                    if q.required { return false }
                    continue
                }
                answers.append(UxSurveyAnswerInput(questionId: q.id, rating: r, text: nil))
            case "text":
                let t = texts[q.id]?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if t.isEmpty, q.required { return false }
                answers.append(UxSurveyAnswerInput(questionId: q.id, rating: nil, text: t))
            default:
                break
            }
        }
        isSubmitting = true
        defer { isSubmitting = false }
        switch await deps.uxSurveyRepository.submit(surveyKey, answers: answers) {
        case .success:
            submitted = true
            return true
        case .failure:
            return false
        }
    }
}
