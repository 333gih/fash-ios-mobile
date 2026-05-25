import Foundation

/// Port of Android `UxSurveyRepository` (data.uxsurvey).
final class UxSurveyRepository {
    private let deps: AppDependencies

    init(deps: AppDependencies) {
        self.deps = deps
    }
}
