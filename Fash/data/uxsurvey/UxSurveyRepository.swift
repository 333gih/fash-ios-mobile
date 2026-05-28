import Foundation

/// UX surveys from core-service — Android `UxSurveyRepository`.
final class UxSurveyRepository {
    private let securedClient: SecuredApiClient
    private let guestBrowse: () -> Bool
    private let guestKey: () -> String

    init(
        securedClient: SecuredApiClient,
        guestBrowse: @escaping () -> Bool,
        guestKey: @escaping () -> String
    ) {
        self.securedClient = securedClient
        self.guestBrowse = guestBrowse
        self.guestKey = guestKey
    }

    func getSurvey(_ surveyKey: String) async -> Result<UxSurveyDetail, Error> {
        let key = surveyKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else {
            return .failure(URLError(.badURL))
        }
        let enc = key.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? key
        if guestBrowse() {
            let gk = guestKey().trimmingCharacters(in: .whitespacesAndNewlines)
            var path = PublicBrowseHttp.publicApiPath("app/ux-surveys/\(enc)")
            if !gk.isEmpty, var components = URLComponents(string: path) {
                var items = components.queryItems ?? []
                items.append(URLQueryItem(name: "guest_key", value: gk))
                components.queryItems = items
                path = components.string ?? path
            }
            do {
                let data = try await RepositoryHttp.executeGet(
                    urlString: path,
                    client: securedClient,
                    publicBrowse: true
                )
                return .success(try parseSurvey(data))
            } catch {
                return .failure(error)
            }
        }
        do {
            let data = try await RepositoryHttp.executeCoreGet(
                relativePath: "api/v1/app/ux-surveys/\(enc)",
                client: securedClient
            )
            return .success(try parseSurvey(data))
        } catch {
            return .failure(error)
        }
    }

    func submit(surveyKey: String, answers: [UxSurveyAnswerInput]) async -> Result<Void, Error> {
        let key = surveyKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else { return .failure(URLError(.badURL)) }
        let enc = key.addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? key
        var body: [String: Any] = [
            "answers": answers.map { a -> [String: Any] in
                var o: [String: Any] = ["question_id": a.questionId]
                if let r = a.rating { o["answer_rating"] = r }
                if let t = a.text?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty {
                    o["answer_text"] = t
                }
                return o
            },
        ]
        guard let payload = try? JSONSerialization.data(withJSONObject: body) else {
            return .failure(URLError(.cannotParseResponse))
        }
        if guestBrowse() {
            let gk = guestKey().trimmingCharacters(in: .whitespacesAndNewlines)
            guard !gk.isEmpty else { return .failure(URLError(.userAuthenticationRequired)) }
            body["guest_key"] = gk
            guard let guestPayload = try? JSONSerialization.data(withJSONObject: body) else {
                return .failure(URLError(.cannotParseResponse))
            }
            let path = PublicBrowseHttp.publicApiPath("app/ux-surveys/\(enc)/responses")
            do {
                try await RepositoryHttp.executePost(
                    urlString: path,
                    client: securedClient,
                    body: guestPayload,
                    publicBrowse: true
                )
                return .success(())
            } catch {
                return .failure(error)
            }
        }
        do {
            try await RepositoryHttp.executeCorePost(
                relativePath: "api/v1/app/ux-surveys/\(enc)/responses",
                body: payload,
                client: securedClient
            )
            return .success(())
        } catch {
            return .failure(error)
        }
    }

    private func parseSurvey(_ data: Data) throws -> UxSurveyDetail {
        let root = try RepositoryHttp.jsonObject(data)
        let container = (root["data"] as? [String: Any]) ?? root
        let survey = (container["survey"] as? [String: Any]) ?? container
        let questionsArr = (survey["questions"] as? [[String: Any]]) ?? []
        let questions = questionsArr.map { q in
            UxSurveyQuestion(
                id: RepositoryHttp.optString(q, "id", "ID"),
                questionKey: RepositoryHttp.optString(q, "question_key", "questionKey"),
                prompt: RepositoryHttp.optString(q, "prompt", "Prompt"),
                questionType: RepositoryHttp.optString(q, "question_type", "questionType").ifEmpty("rating"),
                required: (q["required"] as? Bool) ?? true
            )
        }
        return UxSurveyDetail(
            id: RepositoryHttp.optString(survey, "id", "ID"),
            surveyKey: RepositoryHttp.optString(survey, "survey_key", "surveyKey"),
            title: RepositoryHttp.optString(survey, "title", "Title"),
            description: RepositoryHttp.optString(survey, "description", "Description"),
            submitted: (survey["submitted"] as? Bool) ?? false,
            questions: questions
        )
    }
}

private extension String {
    func ifEmpty(_ fallback: String) -> String {
        trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? fallback : self
    }
}
