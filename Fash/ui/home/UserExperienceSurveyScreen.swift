import SwiftUI

struct UserExperienceSurveyScreen: View {
    var surveyKey: String = "fash_ux_v1"
    var onDismiss: () -> Void = {}

    var body: some View {
        OverlayScreenHost(title: L10n.uxSurveyTitle, onDismiss: onDismiss) {
            Text(surveyKey).padding()
        }
    }
}
