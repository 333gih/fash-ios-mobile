import Foundation

struct UxSurveyDetail: Equatable {
    let id: String
    let surveyKey: String
    let title: String
    let description: String
    let submitted: Bool
    let questions: [UxSurveyQuestion]
}

struct UxSurveyQuestion: Identifiable, Equatable {
    let id: String
    let questionKey: String
    let prompt: String
    let questionType: String
    let required: Bool
}

struct UxSurveyAnswerInput: Equatable {
    let questionId: String
    var rating: Int?
    var text: String?
}
